import 'dart:typed_data';

import 'package:doom_core/src/demo/demo_format.dart';
import 'package:doom_core/src/demo/demo_player.dart';
import 'package:doom_core/src/demo/demo_recorder.dart';
import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:test/test.dart';

void main() {
  group('DemoPlayer', () {
    late Uint8List demoData;

    setUp(() {
      // Create a simple demo with 5 tics
      final recorder = DemoRecorder();
      recorder.startRecording(
        skill: Skill.hurtMePlenty,
        episode: 1,
        map: 1,
      );

      for (var i = 0; i < 5; i++) {
        recorder.recordTic(
          TicCmd()
            ..forwardMove = i * 10
            ..sideMove = i * 5
            ..angleTurn = i * 256
            ..buttons = i,
        );
      }

      demoData = recorder.stopRecording();
    });

    test('throws on data too short', () {
      expect(
        () => DemoPlayer(Uint8List.fromList([1, 2, 3])),
        throwsArgumentError,
      );
    });

    test('parses header correctly', () {
      final player = DemoPlayer(demoData);
      final header = player.header;

      expect(header.version, equals(DemoConstants.version));
      expect(header.skill, equals(Skill.hurtMePlenty));
      expect(header.episode, equals(1));
      expect(header.map, equals(1));
    });

    test('initial state is not finished', () {
      final player = DemoPlayer(demoData);
      expect(player.isFinished, isFalse);
    });

    test('isCompatible returns true for valid demo', () {
      final player = DemoPlayer(demoData);
      expect(player.isCompatible, isTrue);
    });

    test('totalSize returns data length', () {
      final player = DemoPlayer(demoData);
      expect(player.totalSize, equals(demoData.length));
    });

    test('position starts at header size', () {
      final player = DemoPlayer(demoData);
      expect(player.position, equals(DemoHeader.headerSize));
    });

    test('currentTic starts at 0', () {
      final player = DemoPlayer(demoData);
      expect(player.currentTic, equals(0));
    });

    test('totalTics returns correct count', () {
      final player = DemoPlayer(demoData);
      expect(player.totalTics, equals(5));
    });

    test('remainingTics returns correct count', () {
      final player = DemoPlayer(demoData);
      expect(player.remainingTics, equals(5));
    });

    group('readTic', () {
      test('reads tic values correctly', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        player.readTic(cmd);
        expect(cmd.forwardMove, equals(0));
        expect(cmd.sideMove, equals(0));
        expect(cmd.angleTurn, equals(0));
        expect(cmd.buttons, equals(0));

        player.readTic(cmd);
        expect(cmd.forwardMove, equals(10));
        expect(cmd.sideMove, equals(5));
        expect(cmd.angleTurn, equals(256));
        expect(cmd.buttons, equals(1));
      });

      test('advances position', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        final posBefore = player.position;
        player.readTic(cmd);
        expect(player.position, equals(posBefore + DemoTic.ticSize));
      });

      test('advances currentTic', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        expect(player.currentTic, equals(0));
        player.readTic(cmd);
        expect(player.currentTic, equals(1));
        player.readTic(cmd);
        expect(player.currentTic, equals(2));
      });

      test('decreases remainingTics', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        expect(player.remainingTics, equals(5));
        player.readTic(cmd);
        expect(player.remainingTics, equals(4));
      });

      test('sets isFinished when reaching marker', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        for (var i = 0; i < 5; i++) {
          expect(player.isFinished, isFalse);
          player.readTic(cmd);
        }

        // After reading all tics, next read hits marker
        player.readTic(cmd);
        expect(player.isFinished, isTrue);
      });

      test('clears cmd when finished', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        // Read all tics
        for (var i = 0; i < 6; i++) {
          player.readTic(cmd);
        }

        // Read when finished should clear cmd
        cmd
          ..forwardMove = 100
          ..sideMove = 100;
        player.readTic(cmd);
        expect(cmd.forwardMove, equals(0));
        expect(cmd.sideMove, equals(0));
      });
    });

    group('reset', () {
      test('resets position to header size', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        player.readTic(cmd);
        player.readTic(cmd);
        player.reset();

        expect(player.position, equals(DemoHeader.headerSize));
      });

      test('resets isFinished to false', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        // Read until finished
        for (var i = 0; i < 6; i++) {
          player.readTic(cmd);
        }
        expect(player.isFinished, isTrue);

        player.reset();
        expect(player.isFinished, isFalse);
      });

      test('allows re-reading from beginning', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        player.readTic(cmd);
        expect(cmd.forwardMove, equals(0));

        player.readTic(cmd);
        expect(cmd.forwardMove, equals(10));

        player.reset();

        player.readTic(cmd);
        expect(cmd.forwardMove, equals(0));
      });
    });

    group('skip', () {
      test('advances position by tic count', () {
        final player = DemoPlayer(demoData);
        final cmd = TicCmd();

        player.skip(2);
        player.readTic(cmd);

        // Should now be at tic 2 (index 2)
        expect(cmd.forwardMove, equals(20));
      });

      test('sets isFinished if skipping past end', () {
        final player = DemoPlayer(demoData);

        player.skip(10);
        expect(player.isFinished, isTrue);
      });
    });

    group('integration with recorder', () {
      test('player reads exactly what recorder wrote', () {
        // Record a demo
        final recorder = DemoRecorder();
        recorder.startRecording(
          skill: Skill.nightmare,
          episode: 3,
          map: 7,
        );

        final originalCmds = <TicCmd>[];
        for (var i = 0; i < 20; i++) {
          final cmd = TicCmd()
            ..forwardMove = (i * 3) % 128 - 64
            ..sideMove = (i * 7) % 64 - 32
            ..angleTurn = (i * 512) & 0xFF00
            ..buttons = i % 8;
          originalCmds.add(cmd);
          recorder.recordTic(cmd);
        }

        final data = recorder.stopRecording();

        // Play it back
        final player = DemoPlayer(data);
        final readCmd = TicCmd();

        for (var i = 0; i < 20; i++) {
          player.readTic(readCmd);
          expect(readCmd.forwardMove, equals(originalCmds[i].forwardMove));
          expect(readCmd.sideMove, equals(originalCmds[i].sideMove));
          // angleTurn only preserves high byte
          expect(
            readCmd.angleTurn,
            equals(originalCmds[i].angleTurn & 0xFF00),
          );
          expect(readCmd.buttons, equals(originalCmds[i].buttons));
        }
      });
    });
  });
}
