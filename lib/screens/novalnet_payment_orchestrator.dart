import 'package:flutter/material.dart';
import 'package:novalnetsdk/novalnet_util.dart';
import '../novalnet_payment_params.dart';
import 'hosted_payment_page.dart';
import 'google_pay_handler.dart';
import 'apple_pay_handler.dart';

class PaymentOrchestrator {
  static Future<Map<String, dynamic>?> handlePayment(
    BuildContext context, {
    required String paymentType,
    required Map<String, dynamic> bodyParams,
    required Function(bool) onLoading,
  }) async {
    if (paymentType == "GOOGLEPAY") {
      final response = await GooglePayHandler.startPayment(
        context,
        bodyParams,
        onLoading,
      );
      if (response!["result"]["status"] == "FAILURE") {
        return NovalnetUtil.getErrorMessage(response, bodyParams["lang"]);
      }
      return {"status": response["result"]["status"], "result": response};
    }
    if (paymentType == "APPLEPAY") {
      final response = await ApplePayHandler.startPayment(
        context,
        bodyParams,
        onLoading,
      );
      if (response!["result"]["status"] == "FAILURE") {
        return NovalnetUtil.getErrorMessage(response, bodyParams["lang"]);
      }
      return {"status": response["result"]["status"], "result": response};
    }
    if (_isNative(paymentType)) {
      return await _handleNative(context, paymentType, bodyParams);
    }
    return await _handleRedirect(context, paymentType, bodyParams);
  }

  static bool _isNative(String code) {
    return ["INVOICE", "PREPAYMENT", "MULTIBANCO"].contains(code);
  }

  // NATIVE FLOW
  static Future<Map<String, dynamic>?> _handleNative(
    BuildContext context,
    String type,
    Map<String, dynamic> bodyParams,
  ) async {
    try {
      final paymentRequest = NovalnetPaymentParams().nnGetParams(
        bodyParams: bodyParams,
        paymentType: type,
      );

      final response = await NovalnetUtil.sendRequest(
        paymentRequest,
        bodyParams["payment_action"],
        bodyParams["access_key"],
      );

      if (response.isEmpty || response["status"] == "FAILURE") {
        return NovalnetUtil.getErrorMessage(response, bodyParams["lang"]);
      }

      return {"status": response["result"]["status"], "result": response};
    } catch (e) {
      return {"status": "FAILURE", "message": "Something went wrong $e"};
    }
  }

  // REDIRECT FLOW
  static Future<Map<String, dynamic>?> _handleRedirect(
    BuildContext context,
    String type,
    Map<String, dynamic> bodyParams,
  ) async {
    try {
      final paymentRequest = NovalnetPaymentParams().nnGetParams(
        bodyParams: bodyParams,
        paymentType: type,
      );

      final response = await NovalnetUtil.sendRequest(
        paymentRequest,
        bodyParams["payment_action"],
        bodyParams["access_key"],
      );

      if (response.isEmpty || response["status"] == "FAILURE") {
        return NovalnetUtil.getErrorMessage(response, bodyParams["lang"]);
      }

      String redirectUrl = response["result"]?["redirect_url"] ?? "";

      if (redirectUrl.isEmpty) {
        return {
          "status": "FAILURE",
          "message": NovalnetUtil.localize(
            "REDIRECT_URL_EMPTY",
            bodyParams["lang"],
          ),
        };
      }

      return await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HostedPaymentPage(
            url: redirectUrl,
            accessKey: bodyParams["access_key"] ?? "",
            returnUrl: bodyParams["return_url"] ?? "",
            errorReturnUrl: bodyParams["error_return_url"] ?? "",
            lang: bodyParams["lang"] ?? "en",
          ),
        ),
      );
    } catch (e) {
      return {"status": "FAILURE", "message": "Something went wrong $e"};
    }
  }
}
