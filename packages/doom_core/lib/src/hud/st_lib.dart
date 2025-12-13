import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/v_video.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _ScreenIndices {
  static const int background = 4;
  static const int foreground = 0;
}

abstract final class StLibConstants {
  static const int stY = ScreenConstants.height - 32;
  static const int naValue = 1994;
}

class StNumber {
  StNumber({
    required this.x,
    required this.y,
    required this.width,
    required this.patches,
    required this.getValue,
  });

  final int x;
  final int y;
  final int width;
  final List<Patch> patches;
  final int Function() getValue;

  bool enabled = true;

  void update(
    List<Uint8List> screens,
    Patch? minusPatch, {
    required bool refresh,
  }) {
    if (!enabled) return;

    final numDigits = width;
    var num = getValue();

    final w = patches[0].width;
    final h = patches[0].height;

    final neg = num < 0;
    if (neg) {
      if (numDigits == 2 && num < -9) {
        num = -9;
      } else if (numDigits == 3 && num < -99) {
        num = -99;
      }
      num = -num;
    }

    final clearX = x - numDigits * w;

    VVideo.copyRect(
      src: screens[_ScreenIndices.background],
      srcX: clearX,
      srcY: y - StLibConstants.stY,
      dst: screens[_ScreenIndices.foreground],
      dstX: clearX,
      dstY: y,
      width: w * numDigits,
      height: h,
    );

    if (num == StLibConstants.naValue) return;

    var drawX = x;

    if (num == 0) {
      VVideo.drawPatch(screens[_ScreenIndices.foreground], drawX - w, y, patches[0]);
    }

    while (num > 0 && numDigits > 0) {
      drawX -= w;
      VVideo.drawPatch(screens[_ScreenIndices.foreground], drawX, y, patches[num % 10]);
      num ~/= 10;
    }

    if (neg && minusPatch != null) {
      VVideo.drawPatch(screens[_ScreenIndices.foreground], drawX - 8, y, minusPatch);
    }
  }
}

class StPercent {
  StPercent({
    required this.x,
    required this.y,
    required this.patches,
    required this.percentPatch,
    required this.getValue,
  }) : number = StNumber(
          x: x,
          y: y,
          width: 3,
          patches: patches,
          getValue: getValue,
        );

  final int x;
  final int y;
  final List<Patch> patches;
  final Patch percentPatch;
  final int Function() getValue;
  final StNumber number;

  bool get enabled => number.enabled;
  set enabled(bool value) => number.enabled = value;

  void update(
    List<Uint8List> screens,
    Patch? minusPatch, {
    required bool refresh,
  }) {
    if (refresh && number.enabled) {
      VVideo.drawPatch(screens[_ScreenIndices.foreground], x, y, percentPatch);
    }
    number.update(screens, minusPatch, refresh: refresh);
  }
}

class StMultIcon {
  StMultIcon({
    required this.x,
    required this.y,
    required this.patches,
    required this.getIndex,
  });

  final int x;
  final int y;
  final List<Patch> patches;
  final int Function() getIndex;

  int _oldIndex = -1;
  bool enabled = true;

  void update(List<Uint8List> screens, {required bool refresh}) {
    final index = getIndex();

    if (!enabled) return;
    if (_oldIndex == index && !refresh) return;
    if (index == -1) return;

    if (_oldIndex != -1) {
      final oldPatch = patches[_oldIndex];
      final px = x - oldPatch.leftOffset;
      final py = y - oldPatch.topOffset;
      final w = oldPatch.width;
      final h = oldPatch.height;

      VVideo.copyRect(
        src: screens[_ScreenIndices.background],
        srcX: px,
        srcY: py - StLibConstants.stY,
        dst: screens[_ScreenIndices.foreground],
        dstX: px,
        dstY: py,
        width: w,
        height: h,
      );
    }

    VVideo.drawPatch(screens[_ScreenIndices.foreground], x, y, patches[index]);
    _oldIndex = index;
  }
}

class StBinIcon {
  StBinIcon({
    required this.x,
    required this.y,
    required this.patch,
    required this.getValue,
  });

  final int x;
  final int y;
  final Patch patch;
  final bool Function() getValue;

  bool _oldVal = false;
  bool enabled = true;

  void update(List<Uint8List> screens, {required bool refresh}) {
    final val = getValue();

    if (!enabled) return;
    if (_oldVal == val && !refresh) return;

    final px = x - patch.leftOffset;
    final py = y - patch.topOffset;
    final w = patch.width;
    final h = patch.height;

    if (val) {
      VVideo.drawPatch(screens[_ScreenIndices.foreground], x, y, patch);
    } else {
      VVideo.copyRect(
        src: screens[_ScreenIndices.background],
        srcX: px,
        srcY: py - StLibConstants.stY,
        dst: screens[_ScreenIndices.foreground],
        dstX: px,
        dstY: py,
        width: w,
        height: h,
      );
    }

    _oldVal = val;
  }
}
