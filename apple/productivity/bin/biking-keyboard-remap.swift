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

// A CGEvent's sender ID (field 87) is the IORegistry entry ID of the HID
// event service that produced it. Registry entry IDs are unique per boot and
// never reused, so classifications stay valid across device reconnects (each
// reconnect gets a fresh ID that is classified on first use).
var targetSenderIDs: Set<Int64> = []
var passthroughSenderIDs: Set<Int64> = []
let senderIDField = CGEventField(rawValue: 87)!

let debugMode = CommandLine.arguments.contains("--debug")
var tapRef: CFMachPort?

// Look up the sending HID service in the IORegistry and check whether it (or
// an ancestor) carries the MINI_KEYBOARD vendor/product IDs.
func senderIsTarget(_ senderID: Int64) -> Bool {
    let service = IOServiceGetMatchingService(
        kIOMainPortDefault,
        IORegistryEntryIDMatching(UInt64(bitPattern: senderID))
    )
    guard service != IO_OBJECT_NULL else { return false }
    defer { IOObjectRelease(service) }

    let searchOptions = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
    func property(_ key: String) -> Int? {
        IORegistryEntrySearchCFProperty(
            service, kIOServicePlane, key as CFString, kCFAllocatorDefault, searchOptions
        ) as? Int
    }
    return property(kIOHIDVendorIDKey) == targetVendorID
        && property(kIOHIDProductIDKey) == targetProductID
}

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

    // Classify unknown senders by device identity, never by which key they sent
    if !targetSenderIDs.contains(senderID) && !passthroughSenderIDs.contains(senderID) {
        if senderIsTarget(senderID) {
            targetSenderIDs.insert(senderID)
            print("[MINI_KEYBOARD] Identified sender ID: \(senderID) (\(String(format: "0x%llx", senderID)))")
        } else {
            passthroughSenderIDs.insert(senderID)
            if debugMode {
                print("  Registered passthrough sender: \(String(format: "0x%llx", senderID))")
            }
        }
    }

    if targetSenderIDs.contains(senderID) {
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

    return Unmanaged.passRetained(event)
}

// MARK: - Main

print("biking-keyboard-remap starting")
if debugMode { print("Debug mode enabled") }

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

print("Listening... remapping only devices matching VID \(String(format: "0x%x", targetVendorID)) PID \(String(format: "0x%x", targetProductID))")
CFRunLoopRun()
