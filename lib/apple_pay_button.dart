import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ApplePayButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ApplePayButton({Key key, this.onPressed}) : super(key: key);

  @override
  _ApplePayButtonState createState() => _ApplePayButtonState();
}

class _ApplePayButtonState extends State<ApplePayButton> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onPressed,
        child: UiKitView(
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          viewType: 'apple_pay_button',
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    }
    throw Exception(
        '$defaultTargetPlatform is not yet supported by this plugin');
  }
}
