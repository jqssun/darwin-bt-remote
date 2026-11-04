# Bluetooth HID Remote for iOS & macOS

[![Stars](https://img.shields.io/github/stars/jqssun/darwin-bt-remote?label=stars&logo=GitHub)](https://github.com/jqssun/darwin-bt-remote)
[![GitHub](https://img.shields.io/github/downloads/jqssun/darwin-bt-remote/total?label=GitHub&logo=GitHub)](https://github.com/jqssun/darwin-bt-remote/releases)
[![license](https://img.shields.io/badge/License-AGPLv3-blue.svg)](LICENSE)
[![build](https://img.shields.io/github/actions/workflow/status/jqssun/darwin-bt-remote/build.yml?label=build)](https://github.com/jqssun/darwin-bt-remote/actions/workflows/build.yml)
[![release](https://img.shields.io/github/v/release/jqssun/darwin-bt-remote)](https://github.com/jqssun/darwin-bt-remote/releases)

**Remote** is the first device-agnostic open-source app that turns an iPhone, iPad, or Mac into a generic Bluetooth keyboard, mouse, and trackpad, and that works reliably across every major platform. Use any Apple device as a serverless wireless remote for anything that accepts Bluetooth input, with no companion app needed on the target.

As the Apple counterpart of [BT Remote for Android](https://github.com/jqssun/android-bt-remote), it acts as a Bluetooth HID controller for Windows, Linux, macOS, iOS (and iPadOS), tvOS, Android (and Android TV, Google TV, Fire OS), ChromeOS, and SteamOS, plus any other host that supports a standard Bluetooth keyboard or mouse.

Unlike network remote-control tools, it needs nothing installed on the target and relies solely on the host's built-in Bluetooth HID support. Your Apple device presents itself as a standard [Bluetooth Human Interface Device (HID)](https://www.bluetooth.com/specifications/specs/hid-service-specification/) and sends keyboard, media, and mouse input directly over Bluetooth. It also features a direct input mode where you can forward the currently connected hardware input straight to the target device.

[<img height="48" alt="Get it on App Store" src="https://jqssun.github.io/images/badges/apple-app-store.svg">](https://apps.apple.com/app/id6778921831)
[<img height="48" alt="Get it on GitHub" src="https://jqssun.github.io/images/badges/github.svg">](https://github.com/jqssun/darwin-bt-remote/releases/latest)

| Devices | Android | Apple (iOS or macOS) | Windows |
| :---: | :---: | :---: | :---: |
| **iOS Controller** | <video loop src='https://github.com/user-attachments/assets/7a1853ba-d4b0-4def-97dc-4de5f4a5a114' alt="iOS controlling Android" width="260"></video> | <video loop src='https://github.com/user-attachments/assets/bab84d16-b154-40d4-b9ed-f27c462b67b0' alt="iOS controlling macOS" width="260"></video> | <video loop src='https://github.com/user-attachments/assets/ad35c59a-f1bb-4e09-a53c-2433c37ade7a' alt="iOS controlling Windows" width="260"></video> |
| **macOS Controller** | <video loop src='https://github.com/user-attachments/assets/da88c42e-680c-43d2-8263-0180486860e0' alt="macOS controlling Android" width="260"></video> | <video loop src='https://github.com/user-attachments/assets/913a7cb7-b9d4-4d33-be6f-0262dc1ea8d2' alt="macOS controlling iOS" width="260"></video> | <video loop src='https://github.com/user-attachments/assets/d29c964a-3d34-400d-bc5d-fe1670c91c29' alt="macOS controlling Windows" width="260"></video> |

## Compatibility

- HID device (controller):
    - iOS 15 (iPadOS 15) and later
    - macOS 13 and later

- HID host (target):
    - Android 4 and later
    - Android TV, Google TV, and Fire OS
    - ChromeOS
    - iOS 13 (iPadOS 13) and later
    - iOS 4 and later (keyboard only)
    - tvOS 9.2 and later
    - Mac OS X 10.3 and later
    - Linux kernel 2.6 and later
    - SteamOS
    - Windows XP Service Pack 2 and later

## Implementation

The app includes two HID backends and picks the right one depending on platform:

| backend | profile | platform | path | description |
|---|---|---|---|---|
| Bluetooth Classic | HID Profile | macOS | [`BTHIDKit/Classic`](BTHIDKit/Sources/BTHIDKit/Classic) | IOBluetooth SDP record with L2CAP control and interrupt channels |
| Bluetooth Low Energy | HID over GATT Profile | macOS, iOS | [`BTHIDKit/LowEnergy`](BTHIDKit/Sources/BTHIDKit/LowEnergy) | CoreBluetooth peripheral exposing the HID service |

Both backends emit the same HID report descriptors, supporting HID usages for `mouse` (relative mouse input with scroll wheel), `keyboard` (with LED output reports for state indicators), `consumerControl` (for multimedia keys), and `systemControl` (including power and sleep management).

Check out [`build.sh`](build.sh) for development builds, or the [CI](.github/workflows/build.yml) for building with [`fastlane`](https://github.com/fastlane/fastlane).

## Development

This Bluetooth HID stack is manually developed over weeks of working around a list of undocumented platform behaviors to ensure it pairs and streams input fast and reliably on all OS versions above iOS 15 and macOS 13. Making changes to this stack is highly discouraged as it is likely to break SDP negotiation, GATT layout, or bonding handshake, with no clear error logs. Some key constraints to be aware of:

### iOS (HOGP)

- iOS exposes no HID device role, so the full HOGP GATT tree must be manually constructed in `CBPeripheralManager` and the existing implementation of service, characteristic, and descriptor layout must be adhered to for pairing and input streaming to consistently work
- SIG UUIDs must be declared with the full 128-bit canonical string since the 16-bit short form is rejected as system reserved
- `.extendedProperties` must not be set on Protocol Mode, Boot Keyboard Output, or Output Report characteristics since it implicitly appends a descriptor that alters the GATT layout and breaks host's HID binding
- Hosts may stall after subscribing until a baseline input report is pushed, and therefore an initial report on subscribe is required
- Encryption and bonding are mandatory, and a stale bond on either side triggers teardowns that only a full re-pair clears

### macOS (HIDP)

- `bluetoothd` binds the HID L2CAP ports at startup and always operates as the HID host; this means the stack is restricted to outbound connections and can never listen for inbound
- `bluetoothd` performs an SDP lookup for HID device record on the peer on every inbound attempt; Windows hosts expose no such record, so the daemon resets the connection
- `bluetoothd` withdraws competing outbound L2CAP channels, which surfaces on Windows as the outbound open failing with "No Resources Available"
- `bluetoothd` cannot be switched into device role by any SDP attribute or IOBluetooth flag, so in HIDP mode it can only reach stacks that accept device-initiated connections, namely Android; Windows is unreachable via HIDP by design

## License

[AGPL-3.0-only](LICENSE). Commercial license is available upon request.

Bundling this software into closed-source commercial applications, proprietary products, or App Store distributions without an explicit commercial license is copyright infringement.
