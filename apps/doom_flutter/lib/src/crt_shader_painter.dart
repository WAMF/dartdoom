import 'dart:ui' as ui;

import 'package:doom_flutter/src/crt_effect.dart';
import 'package:flutter/material.dart';

class CrtShaderPainter extends CustomPainter {
  CrtShaderPainter({
    required this.image,
    required this.shader,
    required this.effect,
  });

  final ui.Image image;
  final ui.FragmentShader shader;
  final CrtEffect effect;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, effect.mode.toDouble())
      ..setImageSampler(0, image);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(CrtShaderPainter oldDelegate) =>
      image != oldDelegate.image || effect != oldDelegate.effect;
}
