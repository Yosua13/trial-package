import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package_baru_platform_interface.dart';

/// An implementation of [PackageBaruPlatform] that uses method channels.
class MethodChannelPackageBaru extends PackageBaruPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('package_baru');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
