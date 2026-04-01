import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:novalnetsdk/novalnet_util.dart';

class HostedPaymentPage extends StatefulWidget {
  final String url;
  final String accessKey;
  final String returnUrl;
  final String errorReturnUrl;
  final String lang;

  const HostedPaymentPage({
    super.key,
    required this.url,
    required this.accessKey,
    required this.returnUrl,
    required this.errorReturnUrl,
    required this.lang,
  });

  @override
  State<HostedPaymentPage> createState() => _HostedPaymentPageState();
}

class _HostedPaymentPageState extends State<HostedPaymentPage> {
  late final WebViewController controller;
  late Uri successUri;
  late Uri failureUri;
  @override
  void initState() {
    super.initState();

    successUri = Uri.parse(widget.returnUrl);
    failureUri = Uri.parse(widget.errorReturnUrl);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // NAVIGATION INTERCEPT
          onNavigationRequest: (request) async {
            if (request.url.isEmpty) {
              Navigator.pop(context, {
                "status": "FAILURE",
                "message": NovalnetUtil.localize(
                  "RETURN_URL_EMPTY",
                  widget.lang,
                ),
              });
              return NavigationDecision.prevent;
            }
            Uri uri = Uri.parse(request.url);

            // SUCCESS REDIRECT
            if (uri.scheme == successUri.scheme &&
                uri.host == successUri.host) {
              Map<String, dynamic> queryParameters = uri.queryParameters;
              // HASH VALIDATION
              bool checkHashValue = NovalnetUtil.genarateHashValue(
                queryParameters,
                widget.accessKey,
              );
              if (checkHashValue) {
                if (uri.queryParameters["status"] == "SUCCESS") {
                  // GET TRANSACTION DETAILS
                  var data = {
                    "transaction": {"tid": uri.queryParameters["tid"]},
                  };
                  Map<String, dynamic> tidDetails =
                      await NovalnetUtil.sendRequest(
                        data,
                        "transaction_details",
                        widget.accessKey,
                      );

                  if (tidDetails.isEmpty || tidDetails["result"] == null) {
                    Navigator.pop(context, {
                      "status": "FAILURE",
                      "message": NovalnetUtil.localize(
                        "TID_DETAILS_FETCH_ERROR",
                        widget.lang,
                      ),
                    });
                    return NavigationDecision.prevent;
                  }

                  if (tidDetails["result"]["status"] == "FAILURE") {
                    Map<String, dynamic> errorData =
                        NovalnetUtil.getErrorMessage(tidDetails, widget.lang);
                    Navigator.pop(context, errorData);
                    return NavigationDecision.prevent;
                  }
                  Navigator.pop(context, {
                    "status": tidDetails["result"]["status"],
                    "result": tidDetails,
                  });
                  return NavigationDecision.prevent;
                } else {
                  Map<String, dynamic> errorData = NovalnetUtil.getErrorMessage(
                    uri.queryParameters, widget.lang
                  );
                  Navigator.pop(context, errorData);
                  return NavigationDecision.prevent;
                }
              } else {
                Map<String, dynamic> errorData = NovalnetUtil.getErrorMessage(
                  uri.queryParameters, widget.lang
                );
                errorData["status"] = "FAILURE";
                errorData["message"] = NovalnetUtil.localize(
                  "HASH_FAIL",
                  widget.lang,
                );
                Navigator.pop(context, errorData);
                return NavigationDecision.prevent;
              }
            }

            // FAILURE REDIRECT
            if (uri.scheme == failureUri.scheme &&
                uri.host == failureUri.host) {
              Map<String, dynamic> errorData = NovalnetUtil.getErrorMessage(
                uri.queryParameters, widget.lang
              );
              Navigator.pop(context, errorData);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      // LOAD PAYMENT PAGE
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Secure Payment")),

      body: Stack(
        children: [
          // WEBVIEW
          WebViewWidget(controller: controller),
        ],
      ),
    );
  }
}
