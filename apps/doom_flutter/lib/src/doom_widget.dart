import 'dart:async';
import 'dart:ui' as ui;

import 'package:doom_core/doom_core.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class _GameConstants {
  static const int ticRateMs = 1000 ~/ 35;
}

class DoomWidget extends StatefulWidget {
  const DoomWidget({
    super.key,
    this.scale = 3,
    this.wadBytes,
    this.mapName = 'E1M1',
  });

  final int scale;
  final Uint8List? wadBytes;
  final String mapName;

  @override
  State<DoomWidget> createState() => _DoomWidgetState();
}

class _DoomWidgetState extends State<DoomWidget> {
  DoomGame? _game;
  DoomPalette? _palette;
  final _frameNotifier = ValueNotifier<ui.Image?>(null);
  final _focusNode = FocusNode();
  final _paletteConverter = PaletteConverter();
  Timer? _gameLoopTimer;
  Uint8List? _frameBuffer;
  Uint8List? _rgbaBuffer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final wadBytes = widget.wadBytes;
    if (wadBytes == null) return;

    final wadManager = WadManager()..addWad(wadBytes);
    final playpalIndex = wadManager.checkNumForName('PLAYPAL');
    if (playpalIndex != -1) {
      final playpalData = wadManager.readLump(playpalIndex);
      final playpal = PlayPal.parse(playpalData);
      _palette = playpal[0];
      _paletteConverter.setPalette(_palette!);
    }

    _game = DoomGame()..init(wadBytes);

    _frameBuffer = Uint8List(ScreenDimensions.width * ScreenDimensions.height);
    _rgbaBuffer = Uint8List(ScreenDimensions.width * ScreenDimensions.height * 4);

    _initialized = true;
    _startGameLoop();
  }

  @override
  void didUpdateWidget(DoomWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wadBytes != widget.wadBytes ||
        oldWidget.mapName != widget.mapName) {
      _cleanup();
      _initializeGame();
    }
  }

  void _cleanup() {
    _stopGameLoop();
    _game = null;
    _initialized = false;
  }

  void _startGameLoop() {
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: _GameConstants.ticRateMs),
      (_) => _runTic(),
    );
  }

  void _stopGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = null;
  }

  void _runTic() {
    if (!_initialized || _game == null) return;

    _game!.runTic();
    _game!.render(_frameBuffer!);

    _paletteConverter.convertFrame(_frameBuffer!, _rgbaBuffer!);
    _convertToImage(_rgbaBuffer!);
  }

  @override
  void dispose() {
    _cleanup();
    _focusNode.dispose();
    _frameNotifier.value?.dispose();
    super.dispose();
  }

  void _convertToImage(Uint8List rgba) {
    ui.decodeImageFromPixels(
      rgba,
      ScreenDimensions.width,
      ScreenDimensions.height,
      ui.PixelFormat.rgba8888,
      (image) {
        final oldImage = _frameNotifier.value;
        _frameNotifier.value = image;
        oldImage?.dispose();
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final game = _game;
    if (game == null) return KeyEventResult.ignored;

    final keyCode = _logicalKeyToCode(event.logicalKey);
    if (keyCode != null) {
      final DoomEventType eventType;
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        eventType = DoomEventType.keyDown;
      } else {
        eventType = DoomEventType.keyUp;
      }

      final doomEvent = DoomEvent(type: eventType, data1: keyCode);
      game.handleEvent(doomEvent);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int? _logicalKeyToCode(LogicalKeyboardKey key) {
    return switch (key) {
      LogicalKeyboardKey.arrowUp => DoomKey.upArrow,
      LogicalKeyboardKey.arrowDown => DoomKey.downArrow,
      LogicalKeyboardKey.arrowLeft => DoomKey.leftArrow,
      LogicalKeyboardKey.arrowRight => DoomKey.rightArrow,
      LogicalKeyboardKey.keyW => 119,
      LogicalKeyboardKey.keyS => 115,
      LogicalKeyboardKey.keyA => 97,
      LogicalKeyboardKey.keyD => 100,
      LogicalKeyboardKey.space => 32,
      LogicalKeyboardKey.shiftLeft => DoomKey.rshift,
      LogicalKeyboardKey.shiftRight => DoomKey.rshift,
      LogicalKeyboardKey.controlLeft => DoomKey.rctrl,
      LogicalKeyboardKey.controlRight => DoomKey.rctrl,
      LogicalKeyboardKey.altLeft => DoomKey.lalt,
      LogicalKeyboardKey.altRight => DoomKey.ralt,
      LogicalKeyboardKey.escape => DoomKey.escape,
      LogicalKeyboardKey.enter => DoomKey.enter,
      _ => null,
    };
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
                width: ScreenDimensions.width * widget.scale.toDouble(),
                height: ScreenDimensions.height * widget.scale.toDouble(),
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }
            return CustomPaint(
              painter: DoomPainter(image),
              size: Size(
                ScreenDimensions.width * widget.scale.toDouble(),
                ScreenDimensions.height * widget.scale.toDouble(),
              ),
            );
          },
        ),
      ),
    );
  }
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
        ScreenDimensions.width.toDouble(),
        ScreenDimensions.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(DoomPainter oldDelegate) => image != oldDelegate.image;
}
