import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({
    required this.lumpData,
    required this.palette,
    required this.isFlat,
    super.key,
  });

  final Uint8List lumpData;
  final DoomPalette palette;
  final bool isFlat;

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  ui.Image? _image;
  String? _error;
  int _scale = 4;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lumpData != widget.lumpData ||
        oldWidget.palette != widget.palette) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    _image?.dispose();
    _image = null;
    _error = null;

    try {
      final (rgba, width, height) = widget.isFlat
          ? _decodeFlat(widget.lumpData, widget.palette)
          : _decodePatch(widget.lumpData, widget.palette);

      final image = await _createImage(rgba, width, height);
      if (mounted) {
        setState(() {
          _image = image;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  (Uint8List, int, int) _decodeFlat(Uint8List data, DoomPalette palette) {
    const width = 64;
    const height = 64;

    if (data.length != width * height) {
      throw FormatException(
        'Invalid flat size: ${data.length} (expected ${width * height})',
      );
    }

    final rgba = Uint8List(width * height * 4);
    for (var i = 0; i < data.length; i++) {
      final colorIndex = data[i];
      rgba[i * 4] = palette.getRed(colorIndex);
      rgba[i * 4 + 1] = palette.getGreen(colorIndex);
      rgba[i * 4 + 2] = palette.getBlue(colorIndex);
      rgba[i * 4 + 3] = 255;
    }

    return (rgba, width, height);
  }

  (Uint8List, int, int) _decodePatch(Uint8List data, DoomPalette palette) {
    final patch = Patch.parse(data);
    final width = patch.width;
    final height = patch.height;

    final rgba = Uint8List(width * height * 4);

    for (var x = 0; x < width; x++) {
      for (final post in patch.columns[x]) {
        var y = post.topDelta;
        for (final colorIndex in post.pixels) {
          if (y >= 0 && y < height) {
            final i = (y * width + x) * 4;
            rgba[i] = palette.getRed(colorIndex);
            rgba[i + 1] = palette.getGreen(colorIndex);
            rgba[i + 2] = palette.getBlue(colorIndex);
            rgba[i + 3] = 255;
          }
          y++;
        }
      }
    }

    return (rgba, width, height);
  }

  Future<ui.Image> _createImage(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${_image!.width} x ${_image!.height}'),
              const SizedBox(width: 16),
              const Text('Scale:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _scale,
                items: [1, 2, 4, 8]
                    .map((s) => DropdownMenuItem(value: s, child: Text('${s}x')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _scale = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 10,
            child: Center(
              child: CustomPaint(
                painter: _ImagePainter(_image!, _scale),
                size: Size(
                  _image!.width.toDouble() * _scale,
                  _image!.height.toDouble() * _scale,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.scale);

  final ui.Image image;
  final int scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) =>
      image != oldDelegate.image || scale != oldDelegate.scale;
}
