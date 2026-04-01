import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import '../novalnet_util.dart';
import '../novalnet_payment_params.dart';

class ApplePayHandler {
  static Future<Map<String, dynamic>?> startPayment(
    BuildContext context,
    Map<String, dynamic> bodyParams,
    Function(bool) onLoading,
  ) async {
    try {
      //  Config
      final config = PaymentConfiguration.fromJsonString(_applePayConfig());

      // Pay client
      final payClient = Pay({PayProvider.apple_pay: config});

      // Availability
      final canPay = await payClient.userCanPay(PayProvider.apple_pay);

      if (!canPay) {
        return {"status": "FAILURE", "message": "Apple Pay not available"};
      }

      dynamic amount = NovalnetUtil.convertToAmount(bodyParams["amount"]);
      if (amount == null || amount == "INVALID") {
        return {
          "status": "FAILURE",
          "message":
              "Invalid Amount type (Amount type should be int or string only)",
        };
      }

      // Items
      final items = [
        PaymentItem(
          label: "Total",
          amount: amount,
          status: PaymentItemStatus.final_price,
        ),
      ];

      Map<String, dynamic>? resultData;

      // UI
      await showModalBottomSheet(
        context: context,
        builder: (_) {
          return SizedBox(
            height: 120,
            child: Center(
              child: ApplePayButton(
                paymentConfiguration: config,
                paymentItems: items,
                type: ApplePayButtonType.buy,

                onPaymentResult: (result) {
                  resultData = result;
                  Navigator.pop(context);
                },

                onError: (e) {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      );
      onLoading(true);

      // Validate
      if (resultData == null || resultData?.isEmpty == true) {
        return {"status": "FAILURE", "message": "Apple Pay cancelled"};
      }
      final fixedResultData = NovalnetUtil.deepDecode(resultData);
      Map<String, dynamic> genarateWalletTokenReq = {
        "client_key": "${bodyParams["client_key"]}",
        "domain": "https://www.novalnet.com/",
        "is_pending_transaction": false,
        "payment_method": "APPLEPAY",
        "validate_data": fixedResultData,
      };
      final tokenResponse = await NovalnetUtil.sendRequest(
        genarateWalletTokenReq,
        "tokenize",
        bodyParams["access_key"],
      );
      if (tokenResponse.isNotEmpty && tokenResponse["error"] != null) {
        return {"status": "FAILURE", "message": tokenResponse["error"]};
      }

      final token = tokenResponse["token"];

      // Build request
      final paymentRequest = NovalnetPaymentParams().nnGetParams(
        bodyParams: {...bodyParams, "wallet_token": token},
        paymentType: "APPLEPAY",
      );

      // Call API
      final response = await NovalnetUtil.sendRequest(
        paymentRequest,
        bodyParams["payment_action"],
        bodyParams["access_key"],
      );
      onLoading(false);
      return response;
    } catch (e) {
      onLoading(false);
      return {"status": "FAILURE", "message": "Apple Pay failed"};
    }
  }

  static String _applePayConfig() {
    return '''
{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.novalnet.payport",
    "displayName": "Novalnet Demo",
    "merchantCapabilities": ["3DS"],
    "supportedNetworks": ["visa", "masterCard"],
    "countryCode": "DE",
    "currencyCode": "EUR"
  }
}
''';
  }
}
