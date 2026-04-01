import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import '../novalnet_util.dart';
import '../novalnet_payment_params.dart';

class GooglePayHandler {
  static Future<Map<String, dynamic>?> startPayment(
    BuildContext context,
    Map<String, dynamic> bodyParams,
    Function(bool) onLoading,
  ) async {
    try {
      // Create config
      String testMode = bodyParams["test_mode"].toString() == "1"
          ? "SANDBOX"
          : "PRODUCTION";
      dynamic amount = NovalnetUtil.convertToAmount(bodyParams["amount"]);
      final config = PaymentConfiguration.fromJsonString(
        _googlePayConfig(testMode, amount, bodyParams["currency"]),
      );
      // Create Pay client
      final payClient = Pay({PayProvider.google_pay: config});

      // Check availability
      final canPay = await payClient.userCanPay(PayProvider.google_pay);

      if (!canPay) {
        return {
          "status": "FAILURE",
          "message": "Google Pay not available on this device",
        };
      }
      if (amount == null || amount == "INVALID") {
        return {"status": "FAILURE", "message": "Invalid Amount type"};
      }
      // Payment items
      final items = [
        PaymentItem(
          label: "Total",
          amount: amount,
          status: PaymentItemStatus.final_price,
        ),
      ];

      Map<String, dynamic>? resultData;

      // Open UI
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return SizedBox(
            height: 120,
            child: Center(
              child: GooglePayButton(
                paymentConfiguration: config,
                paymentItems: items,
                type: GooglePayButtonType.pay,

                // SUCCESS CALLBACK
                onPaymentResult: (result) async {
                  resultData = result;
                  Navigator.pop(context);
                },

                // ERROR CALLBACK
                onError: (e) {
                  Navigator.pop(context);
                },

                loadingIndicator: const CircularProgressIndicator(),
              ),
            ),
          );
        },
      );
      onLoading(true);

      // Validate result
      if (resultData == null || resultData?.isEmpty == true) {
        return {
          "status": "FAILURE",
          "message": "Google Pay cancelled or no result",
        };
      }

      Map<String, dynamic> genarateWalletTokenReq = {
        "client_key": "51760e803526ae483f06f9ea7c61ba26", //clientKey
        "domain": "https://www.novalnet.com/",
        "is_pending_transaction": false,
        "payment_method": "GOOGLEPAY",
        "validate_data": resultData,
      };

      final validateData =
          genarateWalletTokenReq["validate_data"] as Map<String, dynamic>;

      validateData["environment"] = testMode;
      validateData["amount"] = bodyParams["amount"];
      final Map<String, dynamic> tokenResponse = await NovalnetUtil.sendRequest(
        genarateWalletTokenReq,
        "tokenize",
        bodyParams["access_key"],
      );

      if (tokenResponse.isNotEmpty && tokenResponse["error"] != null) {
        return {"status": "FAILURE", "message": tokenResponse["error"]};
      }
      if (tokenResponse.isEmpty) {
        return {"status": "FAILURE", "message": "Token "};
      }
      final token = tokenResponse["token"];

      // Build request
      final paymentRequest = NovalnetPaymentParams().nnGetParams(
        bodyParams: {...bodyParams, "wallet_token": token},
        paymentType: "GOOGLEPAY",
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
      return {"status": "FAILURE", "message": "Google Pay failed $e"};
    }
  }

  // CONFIG
  static String _googlePayConfig(String environment, amount, currency) {
    environment = environment == "SANDBOX" ? "TEST" : environment;
    return '''
{
  "provider": "google_pay",
  "data": {
    "environment": "$environment",
    "apiVersion": 2,
    "apiVersionMinor": 0,

    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "parameters": {
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "allowedCardNetworks": ["VISA", "MASTERCARD"]
        },
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "novalnet",
            "gatewayMerchantId": "BCR2DN4T4DTN7FSI"
          }
        }
      }
    ],

    "transactionInfo": {
      "totalPriceStatus": "FINAL",
      "totalPrice": "${amount.toString()}",
      "currencyCode": "$currency"
    },

    "merchantInfo": {
      "merchantName": "Novalnet"
    }
  }
}
''';
  }
}
