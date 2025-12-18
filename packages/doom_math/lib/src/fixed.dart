abstract final class _FixedConstants {
  static const int fracBits = 16;
  static const int fracUnit = 1 << fracBits;
  static const int maxInt = 0x7FFFFFFF;
  static const int minInt = -0x80000000;
}

typedef Fixed = int;

extension FixedOps on int {
  static const int fracBits = _FixedConstants.fracBits;
  static const int fracUnit = _FixedConstants.fracUnit;

  int fixedMul(int other) {
    assert(
      s32.abs() < 0x7FFF0000 || other.s32.abs() < 0x10000,
      'fixedMul overflow risk: $s32 * ${other.s32}',
    );
    return (s32 * other.s32) >> _FixedConstants.fracBits;
  }

  int fixedDiv(int other) {
    if ((abs() >> 14) >= other.abs()) {
      return (this ^ other) < 0
          ? _FixedConstants.minInt
          : _FixedConstants.maxInt;
    }
    return _fixedDiv2(other);
  }

  int _fixedDiv2(int other) {
    final c = (this / other) * _FixedConstants.fracUnit;
    if (c >= 2147483648.0 || c < -2147483648.0) {
      throw StateError('FixedDiv: divide by zero');
    }
    return c.toInt();
  }

  int toFixed() => this << _FixedConstants.fracBits;

  int fixedToInt() => this >> _FixedConstants.fracBits;

  double fixedToDouble() => this / _FixedConstants.fracUnit;
}

abstract final class Fixed32 {
  static const int fracBits = _FixedConstants.fracBits;
  static const int fracUnit = _FixedConstants.fracUnit;
  static const int maxInt = _FixedConstants.maxInt;
  static const int minInt = _FixedConstants.minInt;

  static int mul(int a, int b) {
    final sa = a.s32;
    final sb = b.s32;
    assert(
      sa.abs() < 0x7FFF0000 || sb.abs() < 0x10000,
      'Fixed32.mul overflow risk: $sa * $sb',
    );
    return (sa * sb) >> fracBits;
  }

  static int div(int a, int b) {
    if ((a.abs() >> 14) >= b.abs()) {
      return (a ^ b) < 0 ? minInt : maxInt;
    }
    return div2(a, b);
  }

  static int div2(int a, int b) {
    final c = (a / b) * fracUnit;
    if (c >= 2147483648.0 || c < -2147483648.0) {
      throw StateError('FixedDiv: divide by zero');
    }
    return c.toInt();
  }

  static int fromInt(int value) => value << fracBits;

  static int toInt(int fixed) => fixed >> fracBits;

  static double toDouble(int fixed) => fixed / fracUnit;

  static int fromDouble(double value) => (value * fracUnit).toInt();
}

extension IntSigned on int {
  int get u8 => this & 0xFF;
  int get u16 => this & 0xFFFF;
  int get u32 => this & 0xFFFFFFFF;

  int get s8 => toSigned(8);
  int get s16 => toSigned(16);
  int get s32 => toSigned(32);
}
