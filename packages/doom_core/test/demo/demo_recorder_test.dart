import 'package:doom_core/src/demo/demo_format.dart';
import 'package:doom_core/src/demo/demo_recorder.dart';
import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:test/test.dart';

void main() {
  group('DemoRecorder', () {
    late DemoRecorder recorder;

    setUp(() {
      recorder = DemoRecorder();
    });

    test('initial state is not recording', () {
      expect(recorder.isRecording, isFalse);
    });

    test('initial position is 0', () {
      expect(recorder.position, equals(0));
    });

    test('initial ticCount is 0', () {
      expect(recorder.ticCount, equals(0));
    });

    test('initial header is null', () {
      expect(recorder.header, isNull);
    });

    group('startRecording', () {
      test('sets isRecording to true', () {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
        expect(recorder.isRecording, isTrue);
      });

      test('creates header with correct values', () {
        recorder.startRecording(
          skill: Skill.ultraViolence,
          episode: 2,
          map: 5,
          deathmatch: true,
          respawn: true,
          consolePlayer: 1,
          playersInGame: [true, true, false, false],
        );

        final header = recorder.header!;
        expect(header.version, equals(DemoConstants.version));
        expect(header.skill, equals(Skill.ultraViolence));
        expect(header.episode, equals(2));
        expect(header.map, equals(5));
        expect(header.deathmatch, isTrue);
        expect(header.respawn, isTrue);
        expect(header.consolePlayer, equals(1));
        expect(header.playersInGame, equals([true, true, false, false]));
      });

      test('sets position to header size', () {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
        expect(recorder.position, equals(DemoHeader.headerSize));
      });

      test('throws if already recording', () {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
        expect(
          () => recorder.startRecording(
            skill: Skill.hurtMePlenty,
            episode: 1,
            map: 1,
          ),
          throwsStateError,
        );
      });
    });

    group('recordTic', () {
      setUp(() {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
      });

      test('increases position by ticSize', () {
        final posBefore = recorder.position;
        recorder.recordTic(TicCmd());
        expect(recorder.position, equals(posBefore + DemoTic.ticSize));
      });

      test('increases ticCount', () {
        expect(recorder.ticCount, equals(0));
        recorder.recordTic(TicCmd());
        expect(recorder.ticCount, equals(1));
        recorder.recordTic(TicCmd());
        expect(recorder.ticCount, equals(2));
      });

      test('throws if not recording', () {
        final notRecording = DemoRecorder();
        expect(() => notRecording.recordTic(TicCmd()), throwsStateError);
      });
    });

    group('stopRecording', () {
      setUp(() {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
      });

      test('sets isRecording to false', () {
        recorder.stopRecording();
        expect(recorder.isRecording, isFalse);
      });

      test('resets position to 0', () {
        recorder.recordTic(TicCmd());
        recorder.stopRecording();
        expect(recorder.position, equals(0));
      });

      test('clears header', () {
        recorder.stopRecording();
        expect(recorder.header, isNull);
      });

      test('returns data with header and marker', () {
        final data = recorder.stopRecording();
        // Header (13) + marker (1)
        expect(data.length, equals(DemoHeader.headerSize + 1));
        expect(data.last, equals(DemoConstants.demoMarker));
      });

      test('returns data with recorded tics', () {
        recorder.recordTic(TicCmd()..forwardMove = 25);
        recorder.recordTic(TicCmd()..sideMove = -10);
        final data = recorder.stopRecording();
        // Header (13) + 2 tics (8) + marker (1)
        expect(data.length, equals(DemoHeader.headerSize + 8 + 1));
      });

      test('throws if not recording', () {
        recorder.stopRecording();
        expect(recorder.stopRecording, throwsStateError);
      });
    });

    group('remainingSpace', () {
      test('returns buffer size initially', () {
        expect(
          recorder.remainingSpace,
          equals(DemoConstants.defaultBufferSize),
        );
      });

      test('decreases after startRecording', () {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
        expect(
          recorder.remainingSpace,
          equals(DemoConstants.defaultBufferSize - DemoHeader.headerSize),
        );
      });

      test('decreases after recordTic', () {
        recorder.startRecording(
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );
        final spaceBefore = recorder.remainingSpace;
        recorder.recordTic(TicCmd());
        expect(recorder.remainingSpace, equals(spaceBefore - DemoTic.ticSize));
      });
    });

    group('custom buffer size', () {
      test('respects custom buffer size', () {
        final smallRecorder = DemoRecorder(bufferSize: 1024);
        expect(smallRecorder.remainingSpace, equals(1024));
      });
    });

    group('integration', () {
      test('full recording cycle produces valid demo data', () {
        recorder.startRecording(
          skill: Skill.ultraViolence,
          episode: 1,
          map: 1,
        );

        // Record some tics
        for (var i = 0; i < 10; i++) {
          recorder.recordTic(
            TicCmd()
              ..forwardMove = i
              ..angleTurn = i * 256,
          );
        }

        final data = recorder.stopRecording();

        // Verify header
        final header = DemoHeader.fromBytes(data);
        expect(header.version, equals(DemoConstants.version));
        expect(header.skill, equals(Skill.ultraViolence));
        expect(header.episode, equals(1));
        expect(header.map, equals(1));

        // Verify size: header + 10 tics + marker
        expect(
          data.length,
          equals(DemoHeader.headerSize + 10 * DemoTic.ticSize + 1),
        );

        // Verify marker
        expect(data.last, equals(DemoConstants.demoMarker));
      });
    });
  });
}
