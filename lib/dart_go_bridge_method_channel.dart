import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dart_go_bridge_platform_interface.dart';

/// An implementation of [DartGoBridgePlatform] that uses method channels.
class MethodChannelDartGoBridge extends DartGoBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dart_go_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
