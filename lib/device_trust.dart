
import 'device_trust_platform_interface.dart';

class DeviceTrust {
  Future<String?> getPlatformVersion() {
    return DeviceTrustPlatform.instance.getPlatformVersion();
  }
}
