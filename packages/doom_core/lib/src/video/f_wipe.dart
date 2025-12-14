import 'dart:math';
import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';

enum WipeType {
  colorXForm,
  melt,
}

class ScreenWipe {
  static const int _width = ScreenConstants.width;
  static const int _height = ScreenConstants.height;

  final Uint8List _startScreen = Uint8List(_width * _height);
  final Uint8List _endScreen = Uint8List(_width * _height);
  final Uint8List _workScreen = Uint8List(_width * _height);
  final Int16List _columnY = Int16List(_width);

  final Random _random = Random();

  bool _active = false;
  bool _initialized = false;

  bool get isActive => _active;

  void captureStartScreen(Uint8List screen) {
    _startScreen.setAll(0, screen);
  }

  void captureEndScreen(Uint8List screen) {
    _endScreen.setAll(0, screen);
  }

  void startWipe() {
    _active = true;
    _initialized = false;
  }

  bool doWipe(Uint8List screen, int ticks) {
    if (!_active) return true;

    if (!_initialized) {
      _initMelt();
      _initialized = true;
    }

    final done = _doMelt(ticks);

    screen.setAll(0, _workScreen);

    if (done) {
      _active = false;
      _initialized = false;
    }

    return done;
  }

  void _initMelt() {
    _workScreen.setAll(0, _startScreen);

    _columnY[0] = -_random.nextInt(16);
    for (var i = 1; i < _width; i++) {
      final r = _random.nextInt(3) - 1;
      _columnY[i] = _columnY[i - 1] + r;
      if (_columnY[i] > 0) {
        _columnY[i] = 0;
      } else if (_columnY[i] == -16) {
        _columnY[i] = -15;
      }
    }
  }

  bool _doMelt(int ticks) {
    var done = true;

    for (var t = 0; t < ticks; t++) {
      for (var x = 0; x < _width; x++) {
        if (_columnY[x] < 0) {
          _columnY[x]++;
          done = false;
        } else if (_columnY[x] < _height) {
          var dy = (_columnY[x] < 16) ? _columnY[x] + 1 : 8;
          if (_columnY[x] + dy >= _height) {
            dy = _height - _columnY[x];
          }

          final columnTop = _columnY[x];
          for (var j = 0; j < dy; j++) {
            final srcY = columnTop + j;
            _workScreen[srcY * _width + x] = _endScreen[srcY * _width + x];
          }

          _columnY[x] += dy;

          for (var j = _columnY[x]; j < _height; j++) {
            final srcY = j - _columnY[x];
            _workScreen[j * _width + x] = _startScreen[srcY * _width + x];
          }

          done = false;
        }
      }
    }

    return done;
  }
}
