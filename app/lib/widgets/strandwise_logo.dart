import 'package:flutter/material.dart';

class StrandWiseLogo extends StatelessWidget {
  const StrandWiseLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        semanticLabel: 'StrandWise logo',
      );
}
