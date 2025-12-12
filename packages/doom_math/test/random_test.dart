import 'package:doom_math/doom_math.dart';
import 'package:test/test.dart';

void main() {
  group('DoomRandom', () {
    late DoomRandom random;

    setUp(() {
      random = DoomRandom();
    });

    group('initial state', () {
      test('rndIndex starts at 0', () {
        expect(random.rndIndex, 0);
      });

      test('prndIndex starts at 0', () {
        expect(random.prndIndex, 0);
      });
    });

    group('pRandom', () {
      test('advances prndIndex', () {
        random.pRandom();
        expect(random.prndIndex, 1);
      });

      test('returns expected first values', () {
        expect(random.pRandom(), 8);
        expect(random.pRandom(), 109);
        expect(random.pRandom(), 220);
      });

      test('wraps at 256', () {
        for (var i = 0; i < 256; i++) {
          random.pRandom();
        }
        expect(random.prndIndex, 0);
        expect(random.pRandom(), 8);
      });

      test('does not affect rndIndex', () {
        random
          ..pRandom()
          ..pRandom();
        expect(random.rndIndex, 0);
      });
    });

    group('mRandom', () {
      test('advances rndIndex', () {
        random.mRandom();
        expect(random.rndIndex, 1);
      });

      test('returns expected first values', () {
        expect(random.mRandom(), 8);
        expect(random.mRandom(), 109);
        expect(random.mRandom(), 220);
      });

      test('wraps at 256', () {
        for (var i = 0; i < 256; i++) {
          random.mRandom();
        }
        expect(random.rndIndex, 0);
        expect(random.mRandom(), 8);
      });

      test('does not affect prndIndex', () {
        random
          ..mRandom()
          ..mRandom();
        expect(random.prndIndex, 0);
      });
    });

    group('clearRandom', () {
      test('resets both indices to 0', () {
        random
          ..pRandom()
          ..pRandom()
          ..mRandom()
          ..clearRandom();
        expect(random.rndIndex, 0);
        expect(random.prndIndex, 0);
      });
    });

    group('index setters', () {
      test('rndIndex setter masks to 8 bits', () {
        random.rndIndex = 256;
        expect(random.rndIndex, 0);
        random.rndIndex = 300;
        expect(random.rndIndex, 44);
      });

      test('prndIndex setter masks to 8 bits', () {
        random.prndIndex = 256;
        expect(random.prndIndex, 0);
        random.prndIndex = 300;
        expect(random.prndIndex, 44);
      });
    });

    group('determinism', () {
      test('produces same sequence for same initial state', () {
        final random1 = DoomRandom();
        final random2 = DoomRandom();

        final seq1 = List.generate(10, (_) => random1.pRandom());
        final seq2 = List.generate(10, (_) => random2.pRandom());

        expect(seq1, seq2);
      });

      test('produces different sequences from different indices', () {
        final random1 = DoomRandom();
        final random2 = DoomRandom()..prndIndex = 100;

        expect(random1.pRandom(), isNot(random2.pRandom()));
      });
    });

    group('value range', () {
      test('all pRandom values are 0-255', () {
        for (var i = 0; i < 256; i++) {
          final value = random.pRandom();
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThanOrEqualTo(255));
        }
      });

      test('all mRandom values are 0-255', () {
        for (var i = 0; i < 256; i++) {
          final value = random.mRandom();
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThanOrEqualTo(255));
        }
      });
    });
  });
}
