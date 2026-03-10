import 'package:flutter_test/flutter_test.dart';
import 'package:dart_go_bridge/dart_go_bridge.dart';
import 'package:dart_go_bridge/dart_go_bridge_platform_interface.dart';
import 'package:dart_go_bridge/dart_go_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDartGoBridgePlatform
    with MockPlatformInterfaceMixin
    implements DartGoBridgePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DartGoBridgePlatform initialPlatform = DartGoBridgePlatform.instance;

  test('$MethodChannelDartGoBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDartGoBridge>());
  });

  test('getPlatformVersion', () async {
    DartGoBridge dartGoBridgePlugin = DartGoBridge();
    MockDartGoBridgePlatform fakePlatform = MockDartGoBridgePlatform();
    DartGoBridgePlatform.instance = fakePlatform;

    expect(await dartGoBridgePlugin.getPlatformVersion(), '42');
  });
}
