# Agent notes

## biking-keyboard-remap.swift

Remaps MINI_KEYBOARD A/B to Space/Enter via a CGEvent tap, classifying each keystroke's sender (CGEvent field 87, an IORegistry entry ID) by the vendor/product IDs of the HID service that sent it. Built and installed by `../setup.sh` as `~/Applications/BikingKeyboardRemap.app`, launched by `../../plist/local.biking-keyboard-remap.plist`.

### Device identities

The device reports a different identity per transport, and the script matches both (`targetDevices`):

| Transport | VID:PID | Product name |
| --- | --- | --- |
| Bluetooth LE | `0x05ac:0x022c` | `MINI_KEYBOARD` |
| USB (cable or 2.4GHz receiver) | `0x1189:0x8840` | `USB Composite Device` |

While the 2.4GHz receiver is plugged in, keys arrive over USB even though Bluetooth shows the keyboard as "Connected". On 2026-09-25, matching only the Bluetooth identity left A/B unmapped in exactly that state.

### Accessibility permission

- The app is ad-hoc signed (`codesign -s -`), so its Accessibility grant is tied to the exact build. **Every rebuild invalidates the grant.** The tap then fails and the app `exit(1)`s, and launchd (`KeepAlive`) respawns it every ~10s. tccd logs: `Failed to match existing code requirement for subject local.biking-keyboard-remap and service kTCCServicePostEvent`.
- On macOS 27, the Accessibility list is **System Settings > Privacy & Security > Device Control and Data Access**. Re-grant: remove the entry, then use "+" to add the app again (or run `tccutil reset Accessibility local.biking-keyboard-remap` first).
- Improvement (tried and reverted): if `CGEvent.tapCreate` returns nil, call `AXIsProcessTrustedWithOptions` with `kAXTrustedCheckOptionPrompt` to show the system approval popup, which also adds the app to the list. Then retry `tapCreate` every 2s instead of exiting. Retry the tap itself, not `AXIsProcessTrusted()`: on macOS 27 that function caches its first answer for the life of the process. This part was verified: the tap came up in-process right after approval.
- No stable signing identity exists on this machine (`security find-identity -v -p codesigning` shows 0). A self-signed cert would keep grants across rebuilds.

### Debugging tips

- `print` output never reaches `/tmp/biking-keyboard-remap.std{out,err}`, because the LaunchAgent runs the app via `open -W`. Use `log show --predicate 'process == "biking-keyboard-remap"'` or add `os_log`.
- `launchctl kickstart -k` only restarts the `open` wrapper. To load a new binary, kill the app process itself: `pkill -f BikingKeyboardRemap.app/Contents/MacOS`.
- To confirm the tap is installed, call `CGGetEventTapList` and look for a non-listen-only tap owned by the app's PID.
- To see which device sent a key: use a listen-only tap at `.cghidEventTap` (before the remap) or `.cgSessionEventTap` (after the remap), and print field 87 resolved with `IORegistryEntryIDMatching` plus a parent search for `VendorID`/`ProductID`.
- If neither tap sees keys, check raw input with an `IOHIDManager` input-value callback matched on both VID:PIDs. That bypasses the event system entirely. On 2026-09-24 the Bluetooth link was listed as "Connected" but sent no reports at all.
- `ioreg -r -c IOHIDInterface -l` and `system_profiler SPBluetoothDataType` show which identity is currently attached.
