# DeviceTrust Example App

Production-level diagnostic UI demonstrating the `device_trust` plugin capabilities.

## Overview

This example app showcases how to use the `device_trust` plugin to detect:

- **Rooted/Jailbroken** devices
- **Emulator/Simulator** environments
- **Frida/Hook** frameworks
- **Debugger** attachment
- **Developer Mode** (Android)
- **ADB** enablement (Android)

The UI displays results in four main sections:

1. **Summary**: Color-coded flags for all security checks
2. **Policy (Example)**: Sample policy evaluation (COMPROMISED/OK)
3. **Details (JSON)**: Full report details with copy-to-clipboard
4. **Detected Signals**: Lists of specific findings (paths, schemes, libraries)

## Running the Example

### iOS Simulator

```bash
cd example
flutter run -d "iPhone 14"
```

**Expected behavior:**
- `emulator: true` (simulator is detected)
- Most other flags: `false` (simulator is generally clean)
- UI will show green/red badges accordingly
- "Policy (Example)" will show **COMPROMISED** due to emulator flag

### iOS Physical Device

```bash
flutter run -d <device-id>
```

**Expected behavior:**
- `emulator: false`
- `rootedOrJailbroken: false` (on non-jailbroken device)
- `debuggerAttached: true` (if running in debug mode from Xcode)
- Other flags typically `false`

### Android Emulator

```bash
flutter run -d emulator-5554
```

**Expected behavior:**
- `emulator: true` (emulator is detected)
- `devModeEnabled: true` (often enabled on emulators)
- `adbEnabled: true` (on emulators)
- Other flags typically `false`

### Android Physical Device

```bash
flutter run -d <device-id>
```

**Expected behavior:**
- `emulator: false`
- `rootedOrJailbroken: false` (on non-rooted device)
- `devModeEnabled: true/false` (depends on device settings)
- `adbEnabled: true/false` (depends on device settings)
- `debuggerAttached: true` (when debugging)

## Using the App

1. Launch the app
2. Tap **"Get DeviceTrust Report"**
3. Wait for analysis (progress indicator shown)
4. Review the results in cards:
   - **Summary**: Quick overview of all flags
   - **Policy**: Example security policy decision
   - **Details**: Full JSON with copy button
   - **Signals**: Detected paths, schemes, libraries (if any)

## Understanding the Results

### iOS Simulator

Since simulators are development environments:
- ✅ Detection as emulator is **expected**
- Policy shows COMPROMISED (due to emulator flag)
- This is normal for development

### Production iOS Device

On a non-jailbroken device:
- All flags should be `false` in **Release** mode
- Only `debuggerAttached` might be `true` in **Debug** mode

### Jailbroken iOS Device

May show:
- `rootedOrJailbroken: true`
- `fridaSuspected: true` (if Frida/Cydia Substrate present)
- Detected signals: Cydia paths, URL schemes, DYLD libraries

### Android Emulator

Development environments typically show:
- `emulator: true`
- `devModeEnabled: true`
- `adbEnabled: true`
- This is expected for emulators

### Rooted Android Device

May show:
- `rootedOrJailbroken: true`
- Detected signals: su binaries, root management apps

## Integration Tests

Run smoke tests:

```bash
cd example
flutter test integration_test/plugin_integration_test.dart
```

This ensures the app launches and basic UI is functional.

## Notes

- The **Policy (Example)** card is a simple demonstration. Real-world policies should be tailored to your app's security requirements.
- All detection is heuristic-based; no third-party SDKs are used.
- Results may vary based on device configuration and OS version.
- For production use, consider your own policy logic based on `DeviceTrustReport` fields.

## Troubleshooting

### iOS: LSApplicationQueriesSchemes

The app declares URL schemes in `Info.plist`:
- `cydia://`, `sileo://`, `zbra://`, `filza://`, `undecimus://`, `activator://`

This is for `canOpenURL` checks only (no URLs are actually opened).

### Android: Manifest Queries

The plugin's manifest declares package queries for:
- Root management apps (Magisk, SuperSU, etc.)
- Frida server

These merge automatically via Gradle.

## Learn More

- [device_trust plugin](https://github.com/MuhammedErdemKazanci/device_trust)
- [Flutter documentation](https://docs.flutter.dev/)
