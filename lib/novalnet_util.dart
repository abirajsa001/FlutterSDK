import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class NovalnetUtil {
  static String getDueDate(int days) {
    if (isValidDueDate(days)) {
      if (days > 0) {
        DateTime futureDate = DateTime.now().add(Duration(days: days));
        return futureDate.toIso8601String().split("T")[0];
      }
    }
    return "";
  }

  static Future<Map<String, dynamic>> sendRequest(
    Map<String, dynamic> body,
    action,
    accessKey,
  ) async {
    try {
      String endpoint = getEndpoint(action);
      if (["payment", "authorize"].contains(action)) {
        endpoint = getEndpoint(action, body["transaction"]["payment_type"]);
      }
      String hashValue = base64Encode(utf8.encode(accessKey));
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Charset": "utf-8",
          "Accept": "application/json",
          "X-NN-Access-Key": hashValue,
        },
        body: jsonEncode(body),
      );

      if ([200, 201].contains(response.statusCode)) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "FAILURE",
          "status_text": "HTTP Error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "status": "FAILURE",
        "status_text": "Network error: ${e.toString()}",
      };
    }
  }

  static String getEndpoint(String action, [String paymentType = ""]) {
    List formPayments = [
      'CREDITCARD',
      'DIRECT_DEBIT_ACH',
      'DIRECT_DEBIT_SEPA',
      'GUARANTEED_INVOICE',
      'GUARANTEED_DIRECT_DEBIT_SEPA',
      'INSTALMENT_INVOICE',
      'INSTALMENT_DIRECT_DEBIT_SEPA',
    ];
    if (action == "authorize") {
      if (paymentType.isNotEmpty && (formPayments.contains(paymentType))) {
        return "https://payport.novalnet.de/v2/seamless/authorize";
      }
      return "https://payport.novalnet.de/v2/authorize";
    }
    if (action == "payment") {
      if (paymentType.isNotEmpty && (formPayments.contains(paymentType))) {
        return "https://payport.novalnet.de/v2/seamless/payment";
      }
      return "https://payport.novalnet.de/v2/payment";
    }
    if (action == "transaction_details") {
      return "https://payport.novalnet.de/v2/transaction/details";
    }
    if (action == "merchant_details") {
      return "https://payport.novalnet.de/v2/merchant/details";
    }
    if (action == "tokenize") {
      return "https://payport.novalnet.de/v2/tokenize";
    }
    return "INVALLID";
  }

  static bool genarateHashValue(Map<String, dynamic> result, accessKey) {
    String status = result["status"];
    dynamic tid = result["tid"];
    String txnSecret = result["txn_secret"];
    String checksum = result["checksum"];
    dynamic revAccessKey = accessKey.split('').reversed.join();
    String token = "$tid$txnSecret$status$revAccessKey";
    String hashValue = sha256.convert(utf8.encode(token)).toString();
    if (hashValue == checksum) {
      return true;
    }
    return false;
  }

  static Map<String, dynamic> getErrorMessage(
    Map<String, dynamic> response,
    lang,
  ) {
    String status;
    String message;
    if (response == null || response.isEmpty) {
      status = "FAILURE";
      message = localize("RESPONSE_EMPTY", lang);
    } else {
      status = response["result"]?["status"] ?? response["status"] ?? "FAILURE";
      message =
          response["result"]?["status_text"] ??
          response["status_text"] ??
          "Payment failed";
    }

    Map<String, dynamic> errorMSG = {"status": status, "message": message};

    dynamic tid = response["tid"] ?? response["transaction"]?["tid"];

    if (tid != null && tid.toString().isNotEmpty) {
      errorMSG["tid"] = tid;
    }
    return errorMSG;
  }

  // static Map<String, Map<String, String>> getPaymentNames() {
  static Map<String, Map<String, String>> localizedStrings = {
    "INVOICE": {"en": "Invoice", "de": "Kauf auf Rechnung"},
    "PREPAYMENT": {"en": "Prepayment", "de": "Vorkasse"},
    "DIRECT_DEBIT_SEPA": {"en": "Direct Debit SEPA", "de": "SEPA-Lastschrift"},
    "DIRECT_DEBIT_ACH": {"en": "Direct Debit ACH", "de": "Lastschrift ACH"},
    "CREDITCARD": {"en": "Credit/Debit Cards", "de": "Kredit- / Debitkarte"},
    "IDEAL": {"en": "iDEAL | Wero", "de": "iDEAL"},
    "PAYPAL": {"en": "PayPal", "de": "PayPal"},
    "BANCONTACT": {"en": "Bancontact", "de": "Bancontact"},
    "GOOGLEPAY": {"en": "Google Pay", "de": "Google Pay"},
    "APPLEPAY": {"en": "Apple Pay", "de": "Apple Pay"},
    "PRZELEWY24": {"en": "Przelewy24", "de": "Przelewy24"},
    "WECHATPAY": {"en": "WeChat Pay", "de": "WeChat Pay"},
    "ALIPAY": {"en": "Alipay", "de": "Alipay"},
    "MBWAY": {"en": "MB WAY", "de": "MB WAY"},
    "KAKAOPAY": {"en": "KakaoPay", "de": "KakaoPay"},
    "NAVERPAY": {"en": "Naver Pay", "de": "Naver Pay"},
    "TWINT": {"en": "TWINT", "de": "TWINT"},
    "EPS": {"en": "eps", "de": "eps"},
    "ONLINE_BANK_TRANSFER": {
      "en": "Online bank transfer",
      "de": "Onlineüberweisung",
    },
    "POSTFINANCE": {"en": "PostFinance", "de": "PostFinance"},
    "POSTFINANCE_CARD": {"en": "PostFinance Card", "de": "PostFinance Card"},
    "TRUSTLY": {"en": "Trustly", "de": "Trustly"},
    "BLIK": {"en": "Blik", "de": "Blik"},
    "GUARANTEED_INVOICE": {
      "en": "Invoice with payment guarantee",
      "de": "Rechnung mit Zahlungsgarantie",
    },
    "GUARANTEED_DIRECT_DEBIT_SEPA": {
      "en": "Direct debit SEPA with payment guarantee",
      "de": "Lastschrift SEPA mit Zahlungsgarantie",
    },
    "INSTALMENT_INVOICE": {
      "en": "Instalment by invoice",
      "de": "Ratenzahlung per Rechnung",
    },
    "INSTALMENT_DIRECT_DEBIT_SEPA": {
      "en": "Instalment by SEPA direct debit",
      "de": "Ratenzahlung per SEPA-Lastschrift",
    },
    "MULTIBANCO": {"en": "Multibanco", "de": "Multibanco"},
    "HASH_FAIL": {
      "en":
          "While redirecting some data has been changed. The hash check failed",
      "de":
          "Während der Umleitung wurden einige Daten geändert. Die Hash-Prüfung ist fehlgeschlagen",
    },
    "RETURN_URL_EMPTY": {
      "en": "Return URL empty or invalid",
      "de": "Die Rückgabe-URL ist leer oder ungültig",
    },
    "TID_DETAILS_FETCH_ERROR": {
      "en": "Failed to fetch transaction details in NN",
      "de": "Das Abrufen der Transaktionsdetails in NN ist fehlgeschlagen",
    },
    "RESPONSE_EMPTY": {
      "en": "NN request returns empty result",
      "de": "Die NN-Abfrage liefert kein Ergebnis",
    },
    "REDIRECT_URL_EMPTY": {
      "en": "Empty Payment Redirection url is received from NN",
      "de":
          "Von NN wurde eine leere URL für die Zahlungsweiterleitung empfangen",
    },
  };
  //   return paymentLabels;
  // }

  static bool isAllowed(String name, List<String> allowedPayments) {
    final cleaned = allowedPayments
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toList();

    return cleaned.isEmpty || cleaned.contains(name.toUpperCase());
  }

  static Map<String, String> getPaymentIcons() {
    return {
      "CREDITCARD": "lib/assets/images/creditcard.png",
      "PAYPAL": "lib/assets/images/paypal.png",
      "DIRECT_DEBIT_SEPA": "lib/assets/images/direct_debit_sepa.png",
      "INVOICE": "lib/assets/images/invoice.png",
      "PREPAYMENT": "lib/assets/images/prepayment.png",
      "IDEAL": "lib/assets/images/ideal.png",
      "BANCONTACT": "lib/assets/images/bancontact.png",
      "GOOGLEPAY": "lib/assets/images/googlepay.png",
      "APPLEPAY": "lib/assets/images/applepay.png",
      "PRZELEWY24": "lib/assets/images/przelewy24.png",
      "WECHATPAY": "lib/assets/images/wechatpay.png",
      "ALIPAY": "lib/assets/images/alipay.png",
      "MBWAY": "lib/assets/images/mbway.png",
      "KAKAOPAY": "lib/assets/images/kakaopay.png",
      "NAVERPAY": "lib/assets/images/naverpay.png",
      "TWINT": "lib/assets/images/twint.png",
      "EPS": "lib/assets/images/eps.png",
      "ONLINE_BANK_TRANSFER": "lib/assets/images/online_bank_transfer.png",
      "POSTFINANCE": "lib/assets/images/postfinance.png",
      "POSTFINANCE_CARD": "lib/assets/images/postfinance.png",
      "TRUSTLY": "lib/assets/images/trustly.png",
      "BLIK": "lib/assets/images/blik.png",
      "DIRECT_DEBIT_ACH": "lib/assets/images/direct_debit_ach.png",
      "MULTIBANCO": "lib/assets/images/multibanco.png",
      "GUARANTEED_INVOICE": "lib/assets/images/invoice.png",
      "GUARANTEED_DIRECT_DEBIT_SEPA": "lib/assets/images/direct_debit_sepa.png",
      "INSTALMENT_INVOICE": "lib/assets/images/invoice.png",
      "INSTALMENT_DIRECT_DEBIT_SEPA": "lib/assets/images/direct_debit_sepa.png",
    };
  }

  static String localize(String key, String? lang) {
    final language = (lang?.toLowerCase().startsWith("de") ?? false)
        ? "de"
        : "en";

    final normalizedKey = key.toUpperCase();

    return localizedStrings[normalizedKey]?[language] ??
        localizedStrings[normalizedKey]?["en"] ??
        key;
  }

  static String convertToAmount(dynamic amount) {
    int value;
    if (amount is int) {
      value = amount;
    } else if (amount is String) {
      value = int.tryParse(amount) ?? 0;
    } else {
      return "INVALID";
    }
    return (value / 100).toStringAsFixed(2);
  }

  static dynamic deepDecode(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key, deepDecode(value)));
    } else if (data is List) {
      return data.map((e) => deepDecode(e)).toList();
    } else if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return deepDecode(decoded);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  static bool isValidDueDate(dynamic dueDateInput) {
    if (dueDateInput is int) return true;
    if (dueDateInput is String) {
      return int.tryParse(dueDateInput) != null;
    }
    return false;
  }
}
