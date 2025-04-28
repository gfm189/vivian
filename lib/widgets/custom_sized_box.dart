// lib/widgets/custom_sized_box.dart

import 'package:flutter/material.dart';

class CustomSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const CustomSizedBox({
    Key? key,
    this.width,
    this.height,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: child,
    );
  }
}