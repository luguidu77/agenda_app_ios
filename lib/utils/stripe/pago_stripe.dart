import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeTranscationResponse {
  String message;
  bool success;
  StripeTranscationResponse({required this.message, required this.success});
}

class StripeService {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${StripeService.apiBase}/payment_intents';
  static Uri paymentApiUri = Uri.parse(paymentApiUrl);
  static String secret = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  static Map<String, String> headers = {
    'Authorization': 'Bearer ${StripeService.secret}',
    'Content-type': 'application/x-www-form-urlencoded'
  };
  static init() {
    /*  Stripe.publishableKey =
       */
    /* StripePayment.setOptions(StripeOptions(
        publishableKey:
            'pk_test_51JpFagEaW0pHhZCIp8tzFqDjH0brYcfQ9nOYHeD0DLj2yKZBnlm6lKC1RJ8hVCFQIwkzWdV3649C0s48cykqL1o200pPg6bhxh',
        // live publish 'pk_live_51JpFagEaW0pHhZCIR7pWGHaR6b3tl58FiZh1PD06OYQmx3yOQ8PHwSJeHNUoBjDDgcFvsg3i3iCCDanKR9nLbRy100oohpdDpV'
        // debug 'pk_test_51JpFagEaW0pHhZCIp8tzFqDjH0brYcfQ9nOYHeD0DLj2yKZBnlm6lKC1RJ8hVCFQIwkzWdV3649C0s48cykqL1o200pPg6bhxh'
        merchantId: 'merchant.thegreatestmarkeplace',
        androidPayMode: 'production')); */
  }

  static Future<Map<String, dynamic>?> createPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        "amount": amount,
        "currency": currency,
      }; //payment_method_types: [] : 'card'
      var response =
          await http.post(paymentApiUri, headers: headers, body: body);

      return jsonDecode(response.body);
    } catch (error) {
      print('error ocurido en el pago intent $error');
    }
    return null;
  }

  static Future<StripeTranscationResponse?> payWithNewCard(
      {String? amount, String? currency}) async {
    // var paymentMethodCard = await Stripe.instance.createPaymentMethod(PaymentMethodParams.card());
    var paymentIntent =
        await StripeService.createPaymentIntent(amount!, currency!);

    print(paymentIntent!['client_secret']);
    final clientSecret = paymentIntent[
        'client_secret']; // tiene que traer de response.body el 'client_secret'

    await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            /*  applePay: PaymentSheetApplePay(
              merchantCountryCode: 'ES',
            ), */
            googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: 'ES',
              testEnv: true,
            ),
            style: ThemeMode.light,
            //   merchantCountryCode: 'ES',
            merchantDisplayName: 'Agenda de citas Pro'));

    await Stripe.instance.confirmPaymentSheetPayment();
    return null;
    // retorna StripeTranscationResponse
  }
}
