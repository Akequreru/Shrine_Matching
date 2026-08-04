import 'package:flutter/material.dart';

class LoadingRibbonScreen extends StatelessWidget {
  const LoadingRibbonScreen({super.key});

  static const _backgroundColor = Color(0xFFFEFEFE);
  static const _ribbonAssetPath = 'lib/assets/loading_ribbon.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: SizedBox(
          width: double.infinity,
          child: Image.asset(_ribbonAssetPath, fit: BoxFit.fitWidth),
        ),
      ),
    );
  }
}
