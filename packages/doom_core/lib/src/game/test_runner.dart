import 'dart:async';
import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/doom_event.dart';
import 'package:doom_core/src/platform/doom_platform.dart';
import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/palette_converter.dart';
import 'package:doom_core/src/video/test_pattern.dart';
import 'package:doom_core/src/video/text_renderer.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _TestRunnerConstants {
  static const int headerY = 2;
  static const int footerY = FrameBuffer.height - 14;
  static const int keyDisplayY = FrameBuffer.height - 24;
  static const int maxDisplayedKeys = 8;
  static const int faceAnimationSpeed = 8;
}

abstract final class _FaceNames {
  static const List<String> ouchFaces = ['STFOUCH4', 'STFOUCH3', 'STFOUCH2', 'STFOUCH1', 'STFOUCH0'];
  static const List<String> straightFaces = ['STFST40', 'STFST30', 'STFST20', 'STFST10', 'STFST00'];
}

abstract final class _Colors {
  static const int white = 4;
  static const int yellow = 160;
  static const int red = 176;
  static const int green = 112;
  static const int gray = 96;
}

class TestRunner {
  TestRunner(this._platform);

  final DoomPlatform _platform;
  final FrameBuffer _frameBuffer = FrameBuffer();
  final Set<int> _pressedKeys = {};
  final PaletteConverter _paletteConverter = PaletteConverter();
  final List<Patch> _faces = [];

  StreamSubscription<DoomEvent>? _eventSubscription;
  int _ticCount = 0;
  int _frameCount = 0;
  int _lastFpsTic = 0;
  int _fps = 0;
  bool _running = false;
  bool _showDebugOverlay = true;
  String _faceName = '';

  bool get isRunning => _running;
  int get ticCount => _ticCount;
  int get fps => _fps;
  Set<int> get pressedKeys => Set.unmodifiable(_pressedKeys);
  bool get hasFaces => _faces.isNotEmpty;

  void init({DoomPalette? palette, Uint8List? wadBytes}) {
    _platform.init();

    if (palette != null) {
      _paletteConverter.setPalette(palette);
      _platform.video.setPalette(palette);
    }

    if (wadBytes != null) {
      _loadFaces(wadBytes);
    }

    _eventSubscription = _platform.input.events.listen(_handleEvent);
  }

  void _loadFaces(Uint8List wadBytes) {
    _faces.clear();
    final wad = WadManager()..addWad(wadBytes);

    for (final faceList in [_FaceNames.ouchFaces, _FaceNames.straightFaces]) {
      var loaded = false;
      for (final name in faceList) {
        final index = wad.checkNumForName(name);
        if (index != -1) {
          _faces.add(Patch.parse(wad.readLump(index)));
          loaded = true;
        }
      }
      if (loaded && _faceName.isEmpty) {
        _faceName = faceList == _FaceNames.ouchFaces ? 'OUCH' : 'FACE';
      }
      if (_faces.isNotEmpty) break;
    }
  }

  void shutdown() {
    _running = false;
    _eventSubscription?.cancel();
    _platform.shutdown();
  }

  void start() {
    _running = true;
    _ticCount = 0;
    _frameCount = 0;
    _lastFpsTic = 0;
    _fps = 0;
  }

  void runTic() {
    if (!_running) return;

    _platform.input.startTic();

    final currentTime = _platform.video.getTime();
    while (_ticCount < currentTime) {
      _ticCount++;
    }

    _updateFps();
    _render();

    _paletteConverter.convertFrame(
      _frameBuffer.indexedPixels,
      _frameBuffer.rgbaPixels,
    );
    _platform.video.finishUpdate(_frameBuffer);
    _frameCount++;
  }

  void _updateFps() {
    if (_ticCount - _lastFpsTic >= GameConstants.ticRate) {
      _fps = _frameCount;
      _frameCount = 0;
      _lastFpsTic = _ticCount;
    }
  }

  void _render() {
    TestPattern.render(_frameBuffer);

    if (hasFaces) {
      _renderFace();
    }

    TestPattern.renderCrosshair(_frameBuffer);

    if (_showDebugOverlay) {
      _renderHeader();
      _renderKeyDisplay();
      _renderFooter();
    }
  }

  void _renderFace() {
    if (_faces.isEmpty) return;

    final faceIndex = (_ticCount ~/ _TestRunnerConstants.faceAnimationSpeed) % _faces.length;
    final face = _faces[faceIndex];

    const safeAreaCenterX = (TestPattern.safeAreaLeft + TestPattern.safeAreaRight) ~/ 2;
    const safeAreaCenterY = (TestPattern.safeAreaTop + TestPattern.safeAreaBottom) ~/ 2;

    final x = safeAreaCenterX - face.width ~/ 2;
    final y = safeAreaCenterY - face.height ~/ 2;

    _drawPatch(_frameBuffer, face, x, y);
  }

  void _drawPatch(FrameBuffer frame, Patch patch, int destX, int destY) {
    for (var col = 0; col < patch.width; col++) {
      final screenX = destX + col;
      if (screenX < 0 || screenX >= FrameBuffer.width) continue;

      for (final post in patch.columns[col]) {
        var y = destY + post.topDelta;
        for (final pixel in post.pixels) {
          if (y >= 0 && y < FrameBuffer.height) {
            frame.setPixel(screenX, y, pixel);
          }
          y++;
        }
      }
    }
  }

  void _renderHeader() {
    TextRenderer.drawString(
      _frameBuffer,
      4,
      _TestRunnerConstants.headerY,
      'DOOM TEST PATTERN',
      _Colors.red,
    );

    final ticText = 'TIC:$_ticCount';
    TextRenderer.drawString(
      _frameBuffer,
      FrameBuffer.width - TextRenderer.stringWidth(ticText) - 4,
      _TestRunnerConstants.headerY,
      ticText,
      _Colors.yellow,
    );
  }

  void _renderKeyDisplay() {
    TextRenderer.drawString(
      _frameBuffer,
      4,
      _TestRunnerConstants.keyDisplayY,
      'KEYS:',
      _Colors.gray,
    );

    if (_pressedKeys.isEmpty) {
      TextRenderer.drawString(
        _frameBuffer,
        52,
        _TestRunnerConstants.keyDisplayY,
        '(NONE)',
        _Colors.gray,
      );
    } else {
      var x = 52;
      var count = 0;
      for (final key in _pressedKeys) {
        if (count >= _TestRunnerConstants.maxDisplayedKeys) {
          TextRenderer.drawString(_frameBuffer, x, _TestRunnerConstants.keyDisplayY, '...', _Colors.white);
          break;
        }

        final keyName = _getKeyName(key);
        final display = '[$keyName]';
        TextRenderer.drawString(
          _frameBuffer,
          x,
          _TestRunnerConstants.keyDisplayY,
          display,
          _Colors.green,
        );
        x += TextRenderer.stringWidth(display) + 4;
        count++;
      }
    }
  }

  void _renderFooter() {
    final statusText = '320x200 @35Hz  FPS:$_fps';
    TextRenderer.drawString(
      _frameBuffer,
      4,
      _TestRunnerConstants.footerY,
      statusText,
      _Colors.gray,
    );

    TextRenderer.drawString(
      _frameBuffer,
      FrameBuffer.width - TextRenderer.stringWidth('F1:DEBUG') - 4,
      _TestRunnerConstants.footerY,
      'F1:DEBUG',
      _Colors.gray,
    );
  }

  void _handleEvent(DoomEvent event) {
    switch (event.type) {
      case DoomEventType.keyDown:
        _pressedKeys.add(event.data1);
        if (event.data1 == DoomKey.f1) {
          _showDebugOverlay = !_showDebugOverlay;
        }
      case DoomEventType.keyUp:
        _pressedKeys.remove(event.data1);
      case DoomEventType.mouse:
        break;
    }
  }

  String _getKeyName(int keyCode) {
    return switch (keyCode) {
      DoomKey.upArrow => 'UP',
      DoomKey.downArrow => 'DOWN',
      DoomKey.leftArrow => 'LEFT',
      DoomKey.rightArrow => 'RIGHT',
      DoomKey.escape => 'ESC',
      DoomKey.enter => 'ENTER',
      DoomKey.tab => 'TAB',
      DoomKey.backspace => 'BKSP',
      DoomKey.rshift => 'SHIFT',
      DoomKey.rctrl => 'CTRL',
      DoomKey.ralt || DoomKey.lalt => 'ALT',
      DoomKey.f1 => 'F1',
      DoomKey.f2 => 'F2',
      DoomKey.f3 => 'F3',
      DoomKey.f4 => 'F4',
      DoomKey.f5 => 'F5',
      DoomKey.f6 => 'F6',
      DoomKey.f7 => 'F7',
      DoomKey.f8 => 'F8',
      DoomKey.f9 => 'F9',
      DoomKey.f10 => 'F10',
      DoomKey.f11 => 'F11',
      DoomKey.f12 => 'F12',
      32 => 'SPACE',
      >= 65 && <= 90 => String.fromCharCode(keyCode),
      >= 97 && <= 122 => String.fromCharCode(keyCode - 32),
      >= 48 && <= 57 => String.fromCharCode(keyCode),
      _ => keyCode.toRadixString(16).toUpperCase(),
    };
  }

  void toggleDebugOverlay() {
    _showDebugOverlay = !_showDebugOverlay;
  }
}
