/// A security signal encoded in a device trust report's `flags` value.
///
/// The numeric masks are part of the platform-channel protocol and must remain
/// stable across releases.
enum DeviceTrustFlag {
  /// Device is rooted (Android) or jailbroken (iOS).
  rootedOrJailbroken(1),

  /// App is running on an emulator or simulator.
  emulator(2),

  /// Android developer mode is enabled.
  devModeEnabled(4),

  /// Android Debug Bridge (ADB) is enabled.
  adbEnabled(8),

  /// Frida or another hooking framework is suspected.
  fridaSuspected(16),

  /// A debugger is attached to the app process.
  debuggerAttached(32);

  const DeviceTrustFlag(this.mask);

  /// Stable bit mask used by the compact native report protocol.
  final int mask;
}
