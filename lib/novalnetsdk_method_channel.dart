import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'novalnetsdk_platform_interface.dart';

/// An implementation of [NovalnetsdkPlatform] that uses method channels.
class MethodChannelNovalnetSDK extends NovalnetsdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('novalnetsdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
