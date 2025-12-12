import 'dart:async';
import 'dart:ui' as ui;

import 'package:doom_core/doom_core.dart';
import 'package:doom_flutter/src/flutter_platform.dart';
import 'package:doom_flutter/src/key_mapping.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoomWidget extends StatefulWidget {
  const DoomWidget({
    super.key,
    this.scale = 3,
    this.wadBytes,
  });

  final int scale;
  final Uint8List? wadBytes;

  @override
  State<DoomWidget> createState() => _DoomWidgetState();
}

class _DoomWidgetState extends State<DoomWidget> {
  FlutterPlatform? _platform;
  TestRunner? _testRunner;
  final _frameNotifier = ValueNotifier<ui.Image?>(null);
  final _focusNode = FocusNode();
  Timer? _gameLoopTimer;

  @override
  void initState() {
    super.initState();
    _initializeWithWad();
  }

  void _initializeWithWad() {
    DoomPalette? palette;
    final wadBytes = widget.wadBytes;

    if (wadBytes != null) {
      final wadManager = WadManager()..addWad(wadBytes);
      final playpalIndex = wadManager.checkNumForName('PLAYPAL');
      if (playpalIndex != -1) {
        final playpalData = wadManager.readLump(playpalIndex);
        final playpal = PlayPal.parse(playpalData);
        palette = playpal[0];
      }
    }

    _platform = FlutterPlatform(onFrameReady: _handleFrame);
    _testRunner = TestRunner(_platform!)
      ..init(palette: palette, wadBytes: wadBytes)
      ..start();
    _startGameLoop();
  }

  @override
  void didUpdateWidget(DoomWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wadBytes != widget.wadBytes) {
      _cleanup();
      _initializeWithWad();
    }
  }

  void _cleanup() {
    _stopGameLoop();
    _testRunner?.shutdown();
    _testRunner = null;
    _platform = null;
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _testRunner?.runTic(),
    );
  }

  void _stopGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
  }

  @override
  void dispose() {
    _cleanup();
    _focusNode.dispose();
    _frameNotifier.value?.dispose();
    super.dispose();
  }

  void _handleFrame(FrameBuffer frame) {
    _convertToImage(frame.rgbaPixels).then((image) {
      final oldImage = _frameNotifier.value;
      _frameNotifier.value = image;
      oldImage?.dispose();
    });
  }

  Future<ui.Image> _convertToImage(Uint8List rgba) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      FrameBuffer.width,
      FrameBuffer.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final platform = _platform;
    if (platform == null) return KeyEventResult.ignored;

    final doomKey = KeyMapping.toDoomKey(event.logicalKey);
    if (doomKey != null) {
      if (event is KeyDownEvent) {
        platform.input.postKeyDown(doomKey);
      } else if (event is KeyUpEvent) {
        platform.input.postKeyUp(doomKey);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        child: ValueListenableBuilder<ui.Image?>(
          valueListenable: _frameNotifier,
          builder: (context, image, child) {
            if (image == null) {
              return Container(
                width: FrameBuffer.width * widget.scale.toDouble(),
                height: FrameBuffer.height * widget.scale.toDouble(),
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }
            return CustomPaint(
              painter: DoomPainter(image),
              size: Size(
                FrameBuffer.width * widget.scale.toDouble(),
                FrameBuffer.height * widget.scale.toDouble(),
              ),
            );
          },
        ),
      ),
    );
  }

  FlutterPlatform? get platform => _platform;
  TestRunner? get testRunner => _testRunner;
}

class DoomPainter extends CustomPainter {
  DoomPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        FrameBuffer.width.toDouble(),
        FrameBuffer.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(DoomPainter oldDelegate) => image != oldDelegate.image;
}
