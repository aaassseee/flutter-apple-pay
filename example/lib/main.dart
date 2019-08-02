import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apple_pay/apple_pay_button.dart';
import 'package:flutter_apple_pay/flutter_apple_pay.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> makePayment() async {
    dynamic platformVersion;
    PaymentItem paymentItems = PaymentItem(label: 'Label', amount: 51.0);
    try {
      platformVersion = await FlutterApplePay.getStripeToken(
          countryCode: "US",
          currencyCode: "USD",
          paymentNetworks: [PaymentNetwork.visa, PaymentNetwork.mastercard],
          merchantIdentifier: "merchant.stripeApplePayTest",
          paymentItems: [paymentItems],
          stripePublishedKey: "pk_test_TYooMQauvdEDq54NiTphI7jx");
      print(platformVersion);
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Apple Pay Test'),
        ),
        body: Center(
            child: SizedBox(
          width: 200,
          height: 100,
          child: ApplePayButton(
            onPressed: () => makePayment(),
          ),
        )),
      ),
    );
  }
}
