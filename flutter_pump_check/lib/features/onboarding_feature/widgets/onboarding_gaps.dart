import 'package:flutter/material.dart';

class GapH extends StatelessWidget {
  const GapH(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class GapW extends StatelessWidget {
  const GapW(this.width, {super.key});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}
