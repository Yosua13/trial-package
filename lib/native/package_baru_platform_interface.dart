import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package_baru_method_channel.dart';

abstract class PackageBaruPlatform extends PlatformInterface {
  /// Constructs a PackageBaruPlatform.
  PackageBaruPlatform() : super(token: _token);

  static final Object _token = Object();

  static PackageBaruPlatform _instance = MethodChannelPackageBaru();

  /// The default instance of [PackageBaruPlatform] to use.
  ///
  /// Defaults to [MethodChannelPackageBaru].
  static PackageBaruPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PackageBaruPlatform] when
  /// they register themselves.
  static set instance(PackageBaruPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
