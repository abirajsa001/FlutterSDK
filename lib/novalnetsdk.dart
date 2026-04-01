import 'novalnetsdk_platform_interface.dart';
import 'package:flutter/material.dart';
import 'screens/payment_screen.dart';

class NovalnetSDK {
  Future<String?> getPlatformVersion() {
    return NovalnetsdkPlatform.instance.getPlatformVersion();
  }

  static Future<dynamic> openPaymentScreen(
    BuildContext context, {
    required Map<String, dynamic> bodyParams,
    required List<String> paymentMethods,
  }) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          bodyParams: bodyParams,
          paymentMethods: paymentMethods,
        ),
      ),
    );
  }
}
