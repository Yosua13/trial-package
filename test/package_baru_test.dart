import 'package:flutter_test/flutter_test.dart';
import 'package:package_baru/native/package_baru.dart';
import 'package:package_baru/native/package_baru_platform_interface.dart';
import 'package:package_baru/native/package_baru_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPackageBaruPlatform
    with MockPlatformInterfaceMixin
    implements PackageBaruPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PackageBaruPlatform initialPlatform = PackageBaruPlatform.instance;

  test('$MethodChannelPackageBaru is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPackageBaru>());
  });

  test('getPlatformVersion', () async {
    PackageBaru packageBaruPlugin = PackageBaru();
    MockPackageBaruPlatform fakePlatform = MockPackageBaruPlatform();
    PackageBaruPlatform.instance = fakePlatform;

    // expect(await packageBaruPlugin.getPlatformVersion(), '42');
  });
}
