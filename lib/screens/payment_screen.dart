import 'package:novalnetsdk/novalnet_util.dart';
import 'package:flutter/material.dart';
import 'novalnet_payment_orchestrator.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bodyParams;
  final List<String> paymentMethods;

  const PaymentScreen({
    super.key,
    required this.bodyParams,
    required this.paymentMethods,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    String lang = widget.bodyParams["lang"] ?? "EN";

    List<String> allowedMethods = [
      "INVOICE",
      "PREPAYMENT",
      "DIRECT_DEBIT_SEPA",
      "DIRECT_DEBIT_ACH",
      "CREDITCARD",
      "IDEAL",
      "PAYPAL",
      "BANCONTACT",
      "GOOGLEPAY",
      "APPLEPAY",
      "PRZELEWY24",
      "WECHATPAY",
      "ALIPAY",
      "MBWAY",
      "KAKAOPAY",
      "NAVERPAY",
      "TWINT",
      "EPS",
      "ONLINE_BANK_TRANSFER",
      "POSTFINANCE",
      "POSTFINANCE_CARD",
      "TRUSTLY",
      "BLIK",
      "GUARANTEED_INVOICE",
      "GUARANTEED_DIRECT_DEBIT_SEPA",
      "INSTALMENT_INVOICE",
      "INSTALMENT_DIRECT_DEBIT_SEPA",
      "MULTIBANCO",
    ];

    List<String> methodsToShow = allowedMethods
        .where((code) => NovalnetUtil.isAllowed(code, widget.paymentMethods))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Methods"), centerTitle: true),
      backgroundColor: Colors.grey[100],

      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methodsToShow.length,
            itemBuilder: (context, index) {
              String code = methodsToShow[index];
              String label = NovalnetUtil.localize(code, lang);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),

                    onTap: () async {
                      var result = await PaymentOrchestrator.handlePayment(
                        context,
                        paymentType: code,
                        bodyParams: widget.bodyParams,

                        //  Loader control from handler
                        onLoading: (loading) {
                          if (mounted) {
                            setState(() => isLoading = loading);
                          }
                        },
                      );

                      if (result == null ||
                          result["result"]?["status"] == "FAILURE") {
                        Navigator.pop(context, {
                          "status": "FAILURE",
                          "message": result == null
                              ? "Payment Failed"
                              : result["message"],
                        });
                        return;
                      }

                      if (result.isNotEmpty && context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            NovalnetUtil.getPaymentIcons()[code] ?? "",
                            package: "novalnetsdk",
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.payment, size: 24);
                            },
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // LOADER OVERLAY
          if (isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Processing payment..."),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
