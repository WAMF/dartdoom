import 'package:doom_math/doom_math.dart';
import 'package:test/test.dart';

void main() {
  group('Fixed32', () {
    group('constants', () {
      test('fracBits is 16', () {
        expect(Fixed32.fracBits, 16);
      });

      test('fracUnit is 65536', () {
        expect(Fixed32.fracUnit, 65536);
      });

      test('maxInt is 0x7FFFFFFF', () {
        expect(Fixed32.maxInt, 0x7FFFFFFF);
      });

      test('minInt is -0x80000000', () {
        expect(Fixed32.minInt, -0x80000000);
      });
    });

    group('fromInt', () {
      test('converts 1 to fixed', () {
        expect(Fixed32.fromInt(1), 65536);
      });

      test('converts 0 to fixed', () {
        expect(Fixed32.fromInt(0), 0);
      });

      test('converts -1 to fixed', () {
        expect(Fixed32.fromInt(-1), -65536);
      });

      test('converts 100 to fixed', () {
        expect(Fixed32.fromInt(100), 6553600);
      });
    });

    group('toInt', () {
      test('converts fixed 65536 to 1', () {
        expect(Fixed32.toInt(65536), 1);
      });

      test('converts fixed 0 to 0', () {
        expect(Fixed32.toInt(0), 0);
      });

      test('converts fixed -65536 to -1', () {
        expect(Fixed32.toInt(-65536), -1);
      });

      test('truncates fractional part', () {
        expect(Fixed32.toInt(65536 + 32768), 1);
      });
    });

    group('toDouble', () {
      test('converts fixed 65536 to 1.0', () {
        expect(Fixed32.toDouble(65536), 1.0);
      });

      test('converts fixed 32768 to 0.5', () {
        expect(Fixed32.toDouble(32768), 0.5);
      });

      test('converts fixed -65536 to -1.0', () {
        expect(Fixed32.toDouble(-65536), -1.0);
      });
    });

    group('fromDouble', () {
      test('converts 1.0 to fixed', () {
        expect(Fixed32.fromDouble(1), 65536);
      });

      test('converts 0.5 to fixed', () {
        expect(Fixed32.fromDouble(0.5), 32768);
      });

      test('converts -1.0 to fixed', () {
        expect(Fixed32.fromDouble(-1), -65536);
      });

      test('converts 2.5 to fixed', () {
        expect(Fixed32.fromDouble(2.5), 163840);
      });
    });

    group('mul', () {
      test('multiplies 1 * 1', () {
        final a = Fixed32.fromInt(1);
        final b = Fixed32.fromInt(1);
        expect(Fixed32.toInt(Fixed32.mul(a, b)), 1);
      });

      test('multiplies 2 * 3', () {
        final a = Fixed32.fromInt(2);
        final b = Fixed32.fromInt(3);
        expect(Fixed32.toInt(Fixed32.mul(a, b)), 6);
      });

      test('multiplies 0.5 * 2', () {
        final a = Fixed32.fromDouble(0.5);
        final b = Fixed32.fromInt(2);
        expect(Fixed32.toDouble(Fixed32.mul(a, b)), 1.0);
      });

      test('multiplies negative numbers', () {
        final a = Fixed32.fromInt(-2);
        final b = Fixed32.fromInt(3);
        expect(Fixed32.toInt(Fixed32.mul(a, b)), -6);
      });

      test('multiplies two negatives', () {
        final a = Fixed32.fromInt(-2);
        final b = Fixed32.fromInt(-3);
        expect(Fixed32.toInt(Fixed32.mul(a, b)), 6);
      });
    });

    group('div', () {
      test('divides 6 / 2', () {
        final a = Fixed32.fromInt(6);
        final b = Fixed32.fromInt(2);
        expect(Fixed32.toInt(Fixed32.div(a, b)), 3);
      });

      test('divides 1 / 2', () {
        final a = Fixed32.fromInt(1);
        final b = Fixed32.fromInt(2);
        expect(Fixed32.toDouble(Fixed32.div(a, b)), 0.5);
      });

      test('divides negative by positive', () {
        final a = Fixed32.fromInt(-6);
        final b = Fixed32.fromInt(2);
        expect(Fixed32.toInt(Fixed32.div(a, b)), -3);
      });

      test('returns maxInt on overflow', () {
        final a = Fixed32.fromInt(10000);
        final b = Fixed32.fromDouble(0.0001);
        expect(Fixed32.div(a, b), Fixed32.maxInt);
      });

      test('returns minInt on negative overflow', () {
        final a = Fixed32.fromInt(-10000);
        final b = Fixed32.fromDouble(0.0001);
        expect(Fixed32.div(a, b), Fixed32.minInt);
      });
    });
  });

  group('FixedOps extension', () {
    test('toFixed converts int to fixed', () {
      expect(1.toFixed(), 65536);
      expect((-1).toFixed(), -65536);
    });

    test('fixedToInt converts fixed to int', () {
      expect(65536.fixedToInt(), 1);
      expect((-65536).fixedToInt(), -1);
    });

    test('fixedToDouble converts fixed to double', () {
      expect(65536.fixedToDouble(), 1.0);
      expect(32768.fixedToDouble(), 0.5);
    });

    test('fixedMul multiplies fixed values', () {
      final a = 2.toFixed();
      final b = 3.toFixed();
      expect(a.fixedMul(b).fixedToInt(), 6);
    });

    test('fixedDiv divides fixed values', () {
      final a = 6.toFixed();
      final b = 2.toFixed();
      expect(a.fixedDiv(b).fixedToInt(), 3);
    });
  });

  group('IntSigned extension', () {
    group('unsigned masks', () {
      test('u8 masks to 8 bits', () {
        expect(256.u8, 0);
        expect(255.u8, 255);
        expect((-1).u8, 255);
      });

      test('u16 masks to 16 bits', () {
        expect(65536.u16, 0);
        expect(65535.u16, 65535);
        expect((-1).u16, 65535);
      });

      test('u32 masks to 32 bits', () {
        expect(0x100000000.u32, 0);
        expect(0xFFFFFFFF.u32, 0xFFFFFFFF);
        expect((-1).u32, 0xFFFFFFFF);
      });
    });

    group('signed conversions', () {
      test('s8 sign-extends 8-bit', () {
        expect(127.s8, 127);
        expect(128.s8, -128);
        expect(255.s8, -1);
      });

      test('s16 sign-extends 16-bit', () {
        expect(32767.s16, 32767);
        expect(32768.s16, -32768);
        expect(65535.s16, -1);
      });

      test('s32 sign-extends 32-bit', () {
        expect(0x7FFFFFFF.s32, 0x7FFFFFFF);
        expect(0x80000000.s32, -2147483648);
        expect(0xFFFFFFFF.s32, -1);
      });
    });
  });
}
