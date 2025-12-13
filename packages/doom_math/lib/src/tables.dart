import 'dart:math' as math;

import 'package:doom_math/src/fixed.dart';

abstract final class _AngleConstants {
  static const int fineAngles = 8192;
  static const int fineMask = fineAngles - 1;
  static const int angleToFineShift = 19;

  static const int ang45 = 0x20000000;
  static const int ang90 = 0x40000000;
  static const int ang180 = 0x80000000;
  static const int ang270 = 0xc0000000;

  static const int slopeRange = 2048;
  static const int slopeBits = 11;
  static const int dBits = Fixed32.fracBits - slopeBits;
}

abstract final class Angle {
  static const int fineAngles = _AngleConstants.fineAngles;
  static const int fineMask = _AngleConstants.fineMask;
  static const int angleToFineShift = _AngleConstants.angleToFineShift;

  static const int ang45 = _AngleConstants.ang45;
  static const int ang90 = _AngleConstants.ang90;
  static const int ang180 = _AngleConstants.ang180;
  static const int ang270 = _AngleConstants.ang270;

  static const int slopeRange = _AngleConstants.slopeRange;
  static const int slopeBits = _AngleConstants.slopeBits;
  static const int dBits = _AngleConstants.dBits;
}

class DoomTables {
  DoomTables._() {
    _initTables();
  }

  static final DoomTables instance = DoomTables._();

  late final List<int> fineTangent;
  late final List<int> fineSine;
  late final List<int> tanToAngle;

  List<int> get fineCosine =>
      fineSine.sublist(_AngleConstants.fineAngles ~/ 4);

  void _initTables() {
    fineTangent = _generateFineTangent();
    fineSine = _generateFineSine();
    tanToAngle = _generateTanToAngle();
  }

  List<int> _generateFineTangent() {
    final table = List<int>.filled(_AngleConstants.fineAngles ~/ 2, 0);

    for (var i = 0; i < _AngleConstants.fineAngles ~/ 2; i++) {
      final angle =
          (i + 0.5) * math.pi / (_AngleConstants.fineAngles ~/ 2) - math.pi / 2;
      final tan = math.tan(angle);
      table[i] = (tan * Fixed32.fracUnit).round();
    }

    return table;
  }

  List<int> _generateFineSine() {
    const size = 5 * _AngleConstants.fineAngles ~/ 4;
    final table = List<int>.filled(size, 0);

    for (var i = 0; i < size; i++) {
      final angle = (i * 2 * math.pi) / _AngleConstants.fineAngles;
      final sin = math.sin(angle);
      table[i] = (sin * Fixed32.fracUnit).round();
    }

    return table;
  }

  List<int> _generateTanToAngle() {
    final table = List<int>.filled(_AngleConstants.slopeRange + 1, 0);

    for (var i = 0; i <= _AngleConstants.slopeRange; i++) {
      final tan = i / _AngleConstants.slopeRange;
      final angle = math.atan(tan);
      table[i] = (angle * 0x80000000 / math.pi).round().u32;
    }

    return table;
  }

  int slopeDiv(int num, int den) {
    final numD = num.toDouble();
    final denD = den.toDouble();
    if (numD.isNaN || numD.isInfinite || denD.isNaN || denD.isInfinite) {
      return _AngleConstants.slopeRange;
    }

    if (den < 512) {
      return _AngleConstants.slopeRange;
    }

    final denShifted = den >> 8;
    if (denShifted == 0) {
      return _AngleConstants.slopeRange;
    }

    final numShifted = numD * 8;
    if (numShifted.isNaN || numShifted.isInfinite) {
      return _AngleConstants.slopeRange;
    }

    final ans = numShifted ~/ denShifted;
    if (ans < 0) {
      return _AngleConstants.slopeRange;
    }
    return ans <= _AngleConstants.slopeRange ? ans : _AngleConstants.slopeRange;
  }
}

int fineSine(int index) => DoomTables.instance.fineSine[index];
int fineCosine(int index) =>
    DoomTables.instance.fineSine[index + Angle.fineAngles ~/ 4];
int fineTangent(int index) => DoomTables.instance.fineTangent[index];
int tanToAngle(int index) => DoomTables.instance.tanToAngle[index];

int slopeDiv(int num, int den) => DoomTables.instance.slopeDiv(num, den);

int tanToAngleClamped(int slope) {
  return tanToAngle(slope.clamp(0, Angle.slopeRange));
}

int pointToAngle(int dx, int dy) {
  if (dx == 0 && dy == 0) {
    return 0;
  }

  if (dx >= 0) {
    if (dy >= 0) {
      if (dx > dy) {
        return tanToAngleClamped(slopeDiv(dy, dx));
      } else {
        return (Angle.ang90 - 1 - tanToAngleClamped(slopeDiv(dx, dy))).u32;
      }
    } else {
      final absDy = -dy;
      if (dx > absDy) {
        return (-tanToAngleClamped(slopeDiv(absDy, dx))).u32;
      } else {
        return (Angle.ang270 + tanToAngleClamped(slopeDiv(dx, absDy))).u32;
      }
    }
  } else {
    final absDx = -dx;
    if (dy >= 0) {
      if (absDx > dy) {
        return (Angle.ang180 - 1 - tanToAngleClamped(slopeDiv(dy, absDx))).u32;
      } else {
        return (Angle.ang90 + tanToAngleClamped(slopeDiv(absDx, dy))).u32;
      }
    } else {
      final absDy = -dy;
      if (absDx > absDy) {
        return (Angle.ang180 + tanToAngleClamped(slopeDiv(absDy, absDx))).u32;
      } else {
        return (Angle.ang270 - 1 - tanToAngleClamped(slopeDiv(absDx, absDy))).u32;
      }
    }
  }
}

int approxDistance(int dx, int dy) {
  final adx = dx.abs();
  final ady = dy.abs();
  if (adx < ady) {
    return adx + ady - (adx >> 1);
  }
  return adx + ady - (ady >> 1);
}
