import 'dart:math' as math;

import 'package:doom_math/doom_math.dart';
import 'package:test/test.dart';

void main() {
  group('Angle constants', () {
    test('fineAngles is 8192', () {
      expect(Angle.fineAngles, 8192);
    });

    test('fineMask is 8191', () {
      expect(Angle.fineMask, 8191);
    });

    test('angleToFineShift is 19', () {
      expect(Angle.angleToFineShift, 19);
    });

    test('ang45 is correct', () {
      expect(Angle.ang45, 0x20000000);
    });

    test('ang90 is correct', () {
      expect(Angle.ang90, 0x40000000);
    });

    test('ang180 is correct', () {
      expect(Angle.ang180, 0x80000000);
    });

    test('ang270 is correct', () {
      expect(Angle.ang270, 0xc0000000);
    });

    test('slopeRange is 2048', () {
      expect(Angle.slopeRange, 2048);
    });
  });

  group('DoomTables', () {
    late DoomTables tables;

    setUp(() {
      tables = DoomTables.instance;
    });

    group('fineSine', () {
      test('has correct length', () {
        expect(tables.fineSine.length, 5 * Angle.fineAngles ~/ 4);
      });

      test('sine of 0 is 0', () {
        expect(tables.fineSine[0], 0);
      });

      test('sine of 90 degrees is ~fracUnit', () {
        const index = Angle.fineAngles ~/ 4;
        final value = tables.fineSine[index];
        expect(Fixed32.toDouble(value), closeTo(1.0, 0.0001));
      });

      test('sine of 180 degrees is ~0', () {
        const index = Angle.fineAngles ~/ 2;
        final value = tables.fineSine[index];
        expect(Fixed32.toDouble(value), closeTo(0.0, 0.0001));
      });

      test('sine of 270 degrees is ~-fracUnit', () {
        const index = 3 * Angle.fineAngles ~/ 4;
        final value = tables.fineSine[index];
        expect(Fixed32.toDouble(value), closeTo(-1.0, 0.0001));
      });
    });

    group('fineCosine', () {
      test('cosine of 0 is ~fracUnit', () {
        final value = tables.fineCosine[0];
        expect(Fixed32.toDouble(value), closeTo(1.0, 0.0001));
      });

      test('cosine of 90 degrees is ~0', () {
        const index = Angle.fineAngles ~/ 4;
        final value = tables.fineCosine[index];
        expect(Fixed32.toDouble(value), closeTo(0.0, 0.0001));
      });
    });

    group('fineTangent', () {
      test('has correct length', () {
        expect(tables.fineTangent.length, Angle.fineAngles ~/ 2);
      });

      test('tangent at center is near 0', () {
        const index = Angle.fineAngles ~/ 4;
        final value = tables.fineTangent[index];
        expect(Fixed32.toDouble(value), closeTo(0.0, 0.01));
      });
    });

    group('tanToAngle', () {
      test('has correct length', () {
        expect(tables.tanToAngle.length, Angle.slopeRange + 1);
      });

      test('tanToAngle[0] is 0', () {
        expect(tables.tanToAngle[0], 0);
      });

      test('tanToAngle at slopeRange is ang90', () {
        final value = tables.tanToAngle[Angle.slopeRange];
        expect(value, closeTo(Angle.ang90, Angle.ang90 * 0.01));
      });
    });

    group('slopeDiv', () {
      test('returns slopeRange when denominator is small', () {
        expect(tables.slopeDiv(1000, 100), Angle.slopeRange);
      });

      test('calculates slope for normal values', () {
        final result = tables.slopeDiv(1000, 1000);
        expect(result, lessThanOrEqualTo(Angle.slopeRange));
      });

      test('caps result at slopeRange', () {
        final result = tables.slopeDiv(100000, 1000);
        expect(result, Angle.slopeRange);
      });
    });
  });

  group('global table functions', () {
    test('fineSine returns table values', () {
      expect(fineSine(0), DoomTables.instance.fineSine[0]);
    });

    test('fineCosine returns offset sine values', () {
      expect(fineCosine(0), DoomTables.instance.fineSine[Angle.fineAngles ~/ 4]);
    });

    test('fineTangent returns table values', () {
      expect(fineTangent(0), DoomTables.instance.fineTangent[0]);
    });

    test('tanToAngle returns table values', () {
      expect(tanToAngle(0), DoomTables.instance.tanToAngle[0]);
    });

    test('slopeDiv calls instance method', () {
      expect(slopeDiv(1000, 100), DoomTables.instance.slopeDiv(1000, 100));
    });
  });

  group('trig accuracy', () {
    test('sine values match standard library', () {
      for (var i = 0; i < Angle.fineAngles; i += 100) {
        final angle = (i * 2 * math.pi) / Angle.fineAngles;
        final expected = math.sin(angle);
        final actual = Fixed32.toDouble(DoomTables.instance.fineSine[i]);
        expect(actual, closeTo(expected, 0.0001), reason: 'at index $i');
      }
    });

    test('cosine values match standard library', () {
      for (var i = 0; i < Angle.fineAngles; i += 100) {
        final angle = (i * 2 * math.pi) / Angle.fineAngles;
        final expected = math.cos(angle);
        final actual = Fixed32.toDouble(DoomTables.instance.fineCosine[i]);
        expect(actual, closeTo(expected, 0.0001), reason: 'at index $i');
      }
    });
  });
}
