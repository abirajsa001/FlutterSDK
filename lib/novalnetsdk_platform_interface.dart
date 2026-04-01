import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'novalnetsdk_method_channel.dart';

abstract class NovalnetsdkPlatform extends PlatformInterface {
  /// Constructs a NovalnetsdkPlatform.
  NovalnetsdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static NovalnetsdkPlatform _instance = MethodChannelNovalnetSDK();

  /// The default instance of [NovalnetsdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelNovalnetsdk].
  static NovalnetsdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NovalnetsdkPlatform] when
  /// they register themselves.
  static set instance(NovalnetsdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
