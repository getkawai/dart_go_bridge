import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dart_go_bridge_method_channel.dart';

abstract class DartGoBridgePlatform extends PlatformInterface {
  /// Constructs a DartGoBridgePlatform.
  DartGoBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static DartGoBridgePlatform _instance = MethodChannelDartGoBridge();

  /// The default instance of [DartGoBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelDartGoBridge].
  static DartGoBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DartGoBridgePlatform] when
  /// they register themselves.
  static set instance(DartGoBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
