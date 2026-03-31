import Foundation
import IOKit
import IOKit.hid
import CoreGraphics

// MINI_KEYBOARD identification
let targetVendorID = 0x5ac
let targetProductID = 0x22c

// macOS virtual keycode remapping
// A (VK 0) -> Space (VK 49)
// B (VK 11) -> Return (VK 36)
let remapTable: [Int64: CGKeyCode] = [
    0: 49,
    11: 36,
]

// Sender ID tracking
var knownMainSenderIDs: Set<Int64> = []
var targetSenderIDs: Set<Int64> = []
var deviceConnected = true // assume connected; IOHIDManager updates if available
let lock = NSLock()
let senderIDField = CGEventField(rawValue: 87)!

var debugMode = CommandLine.arguments.contains("--debug")
var tapRef: CFMachPort?

// MARK: - IOHIDManager: detect connect/disconnect

func deviceMatches(_ device: IOHIDDevice) -> Bool {
    guard let vid = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int,
          let pid = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int else {
        return false
    }
    return vid == targetVendorID && pid == targetProductID
}

func onDeviceAdded(_ context: UnsafeMutableRawPointer?, _ result: IOReturn, _ sender: UnsafeMutableRawPointer?, _ device: IOHIDDevice) {
    guard deviceMatches(device) else { return }
    print("[MINI_KEYBOARD] Connected")
    lock.lock()
    deviceConnected = true
    lock.unlock()
}

func onDeviceRemoved(_ context: UnsafeMutableRawPointer?, _ result: IOReturn, _ sender: UnsafeMutableRawPointer?, _ device: IOHIDDevice) {
    guard deviceMatches(device) else { return }
    print("[MINI_KEYBOARD] Disconnected")
    lock.lock()
    deviceConnected = false
    targetSenderIDs.removeAll()
    lock.unlock()
}

// MARK: - CGEventTap: intercept, learn, and remap

func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = tapRef { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passRetained(event)
    }

    guard type == .keyDown || type == .keyUp else {
        return Unmanaged.passRetained(event)
    }

    let senderID = event.getIntegerValueField(senderIDField)
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    lock.lock()
    let isTarget = targetSenderIDs.contains(senderID)
    let isKnownMain = knownMainSenderIDs.contains(senderID)
    let connected = deviceConnected
    lock.unlock()

    // Already identified as target
    if isTarget {
        if debugMode {
            let dir = type == .keyDown ? "dn" : "up"
            print("  \(dir): kc=\(keyCode) sender=\(String(format: "0x%llx", senderID)) -> REMAP")
        }
        if let newVK = remapTable[keyCode] {
            if let newEvent = CGEvent(keyboardEventSource: nil, virtualKey: newVK, keyDown: type == .keyDown) {
                return Unmanaged.passRetained(newEvent)
            }
        }
        return nil // drop non-remapped keys from target
    }

    // Already identified as main keyboard
    if isKnownMain {
        return Unmanaged.passRetained(event)
    }

    // Unknown sender - learn its identity
    // If MINI_KEYBOARD is connected and this sender sends A or B (keycodes 0 or 11),
    // it's likely the MINI_KEYBOARD. Otherwise, it's the main keyboard.
    if connected && (keyCode == 0 || keyCode == 11) {
        lock.lock()
        targetSenderIDs.insert(senderID)
        lock.unlock()
        print("[MINI_KEYBOARD] Learned sender ID: \(senderID) (\(String(format: "0x%llx", senderID)))")

        if let newVK = remapTable[keyCode] {
            if let newEvent = CGEvent(keyboardEventSource: nil, virtualKey: newVK, keyDown: type == .keyDown) {
                return Unmanaged.passRetained(newEvent)
            }
        }
        return nil
    }

    // Unknown sender sending a non-A/B key - it's a main keyboard
    lock.lock()
    knownMainSenderIDs.insert(senderID)
    lock.unlock()
    if debugMode {
        print("  Registered main keyboard sender: \(String(format: "0x%llx", senderID))")
    }

    return Unmanaged.passRetained(event)
}

// MARK: - Main

print("biking-keyboard-remap starting")
if debugMode { print("Debug mode enabled") }

// IOHIDManager for device lifecycle
let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matchKeyboard: [String: Any] = [kIOHIDDeviceUsagePageKey as String: 1, kIOHIDDeviceUsageKey as String: 6]
let matchMouse: [String: Any] = [kIOHIDDeviceUsagePageKey as String: 1, kIOHIDDeviceUsageKey as String: 2]
IOHIDManagerSetDeviceMatchingMultiple(hidManager, [matchKeyboard, matchMouse] as CFArray)
IOHIDManagerRegisterDeviceMatchingCallback(hidManager, onDeviceAdded, nil)
IOHIDManagerRegisterDeviceRemovalCallback(hidManager, onDeviceRemoved, nil)
IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

let hidResult = IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
if hidResult != kIOReturnSuccess {
    print("IOHIDManager unavailable (\(String(format: "0x%x", hidResult))), assuming device connected")
}

// CGEventTap for key interception
let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
guard let tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: mask,
    callback: eventTapCallback,
    userInfo: nil
) else {
    print("Failed to create event tap. Grant Accessibility permission.")
    exit(1)
}
tapRef = tap

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

print("Listening... (type on main keyboard first to register it, then use MINI_KEYBOARD)")
CFRunLoopRun()
