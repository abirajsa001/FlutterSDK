import 'package:flutter_test/flutter_test.dart';
import 'package:novalnetsdk/novalnetsdk.dart';
import 'package:novalnetsdk/novalnetsdk_platform_interface.dart';
import 'package:novalnetsdk/novalnetsdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNovalnetsdkPlatform
    with MockPlatformInterfaceMixin
    implements NovalnetsdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NovalnetsdkPlatform initialPlatform = NovalnetsdkPlatform.instance;

  test('$MethodChannelNovalnetSDK is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNovalnetSDK>());
  });

  test('getPlatformVersion', () async {
    NovalnetSDK novalnetsdkPlugin = NovalnetSDK();
    MockNovalnetsdkPlatform fakePlatform = MockNovalnetsdkPlatform();
    NovalnetsdkPlatform.instance = fakePlatform;

    expect(await novalnetsdkPlugin.getPlatformVersion(), '42');
  });
}
