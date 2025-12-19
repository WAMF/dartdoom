import 'dart:typed_data';

import 'package:doom_core/src/demo/demo_format.dart';
import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:test/test.dart';

void main() {
  group('DemoConstants', () {
    test('version is 110', () {
      expect(DemoConstants.version, equals(110));
    });

    test('demoMarker is 0x80', () {
      expect(DemoConstants.demoMarker, equals(0x80));
    });

    test('defaultBufferSize is 0x20000', () {
      expect(DemoConstants.defaultBufferSize, equals(0x20000));
    });
  });

  group('DemoHeader', () {
    test('headerSize is 13', () {
      expect(DemoHeader.headerSize, equals(13));
    });

    group('construction', () {
      test('creates with default values', () {
        final header = DemoHeader(
          version: 110,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        expect(header.version, equals(110));
        expect(header.skill, equals(Skill.hurtMePlenty));
        expect(header.episode, equals(1));
        expect(header.map, equals(1));
        expect(header.deathmatch, isFalse);
        expect(header.respawn, isFalse);
        expect(header.fast, isFalse);
        expect(header.noMonsters, isFalse);
        expect(header.consolePlayer, equals(0));
        // Default playersInGame is all false
        expect(header.playersInGame, equals([false, false, false, false]));
      });

      test('creates with custom players', () {
        final header = DemoHeader(
          version: 110,
          skill: Skill.ultraViolence,
          episode: 2,
          map: 3,
          playersInGame: [true, true, false, false],
          consolePlayer: 1,
        );

        expect(header.playersInGame, equals([true, true, false, false]));
        expect(header.consolePlayer, equals(1));
      });

      test('creates with all flags enabled', () {
        final header = DemoHeader(
          version: 110,
          skill: Skill.nightmare,
          episode: 4,
          map: 9,
          deathmatch: true,
          respawn: true,
          fast: true,
          noMonsters: true,
          consolePlayer: 3,
          playersInGame: [true, true, true, true],
        );

        expect(header.deathmatch, isTrue);
        expect(header.respawn, isTrue);
        expect(header.fast, isTrue);
        expect(header.noMonsters, isTrue);
        expect(header.consolePlayer, equals(3));
        expect(header.playersInGame, equals([true, true, true, true]));
      });
    });

    group('isCompatible', () {
      test('returns true for matching version', () {
        final header = DemoHeader(
          version: DemoConstants.version,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        expect(header.isCompatible, isTrue);
      });

      test('returns true for version 109 (DOOM 1.9)', () {
        final header = DemoHeader(
          version: 109,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        // Versions 104-110 are all compatible (same header format)
        expect(header.isCompatible, isTrue);
      });

      test('returns true for version 104 (DOOM 1.4, minimum compatible)', () {
        final header = DemoHeader(
          version: 104,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        expect(header.isCompatible, isTrue);
      });

      test('returns false for version 103 (incompatible)', () {
        final header = DemoHeader(
          version: 103,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        expect(header.isCompatible, isFalse);
      });

      test('returns false for version 0', () {
        final header = DemoHeader(
          version: 0,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        expect(header.isCompatible, isFalse);
      });

      test('returns false for max byte version 255', () {
        final header = DemoHeader(
          version: 255,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        expect(header.isCompatible, isFalse);
      });
    });

    group('toBytes', () {
      test('produces 13-byte header', () {
        final header = DemoHeader(
          version: 110,
          skill: Skill.hurtMePlenty,
          episode: 1,
          map: 1,
        );

        final bytes = header.toBytes();
        expect(bytes.length, equals(13));
      });

      test('encodes values correctly', () {
        final header = DemoHeader(
          version: 110,
          skill: Skill.ultraViolence,
          episode: 2,
          map: 5,
          deathmatch: true,
          respawn: true,
          fast: true,
          noMonsters: true,
          consolePlayer: 1,
          playersInGame: [true, true, true, false],
        );

        final bytes = header.toBytes();
        expect(bytes[0], equals(110)); // version
        expect(bytes[1], equals(Skill.ultraViolence.index)); // skill
        expect(bytes[2], equals(2)); // episode
        expect(bytes[3], equals(5)); // map
        expect(bytes[4], equals(1)); // deathmatch
        expect(bytes[5], equals(1)); // respawn
        expect(bytes[6], equals(1)); // fast
        expect(bytes[7], equals(1)); // nomonsters
        expect(bytes[8], equals(1)); // consoleplayer
        expect(bytes[9], equals(1)); // player 0 in game
        expect(bytes[10], equals(1)); // player 1 in game
        expect(bytes[11], equals(1)); // player 2 in game
        expect(bytes[12], equals(0)); // player 3 not in game
      });

      test('encodes all flags as false correctly', () {
        final header = DemoHeader(
          version: 110,
          skill: Skill.imTooYoungToDie,
          episode: 1,
          map: 1,
          deathmatch: false,
          respawn: false,
          fast: false,
          noMonsters: false,
          consolePlayer: 0,
          playersInGame: [false, false, false, false],
        );

        final bytes = header.toBytes();
        expect(bytes[4], equals(0)); // deathmatch
        expect(bytes[5], equals(0)); // respawn
        expect(bytes[6], equals(0)); // fast
        expect(bytes[7], equals(0)); // nomonsters
        expect(bytes[8], equals(0)); // consoleplayer
        expect(bytes[9], equals(0)); // player 0
        expect(bytes[10], equals(0)); // player 1
        expect(bytes[11], equals(0)); // player 2
        expect(bytes[12], equals(0)); // player 3
      });

      test('encodes all skill levels correctly', () {
        for (final skill in Skill.values) {
          final header = DemoHeader(
            version: 110,
            skill: skill,
            episode: 1,
            map: 1,
          );
          final bytes = header.toBytes();
          expect(bytes[1], equals(skill.index), reason: 'Failed for $skill');
        }
      });

      test('encodes boundary episode values', () {
        for (final episode in [1, 2, 3, 4, 255]) {
          final header = DemoHeader(
            version: 110,
            skill: Skill.hurtMePlenty,
            episode: episode,
            map: 1,
          );
          final bytes = header.toBytes();
          expect(bytes[2], equals(episode), reason: 'Failed for episode $episode');
        }
      });

      test('encodes boundary map values', () {
        for (final map in [1, 9, 32, 99, 255]) {
          final header = DemoHeader(
            version: 110,
            skill: Skill.hurtMePlenty,
            episode: 1,
            map: map,
          );
          final bytes = header.toBytes();
          expect(bytes[3], equals(map), reason: 'Failed for map $map');
        }
      });
    });

    group('fromBytes', () {
      test('parses header correctly', () {
        final bytes = Uint8List.fromList([
          110, // version
          3, // skill (ultraViolence)
          2, // episode
          5, // map
          1, // deathmatch
          0, // respawn
          1, // fast
          0, // nomonsters
          0, // consoleplayer
          1, // player 0
          1, // player 1
          0, // player 2
          0, // player 3
        ]);

        final header = DemoHeader.fromBytes(bytes);
        expect(header.version, equals(110));
        expect(header.skill, equals(Skill.ultraViolence));
        expect(header.episode, equals(2));
        expect(header.map, equals(5));
        expect(header.deathmatch, isTrue);
        expect(header.respawn, isFalse);
        expect(header.fast, isTrue);
        expect(header.noMonsters, isFalse);
        expect(header.consolePlayer, equals(0));
        expect(header.playersInGame, equals([true, true, false, false]));
      });

      test('parses all flags as true', () {
        final bytes = Uint8List.fromList([
          110, 2, 1, 1,
          1, 1, 1, 1, // all flags true
          3, // consoleplayer
          1, 1, 1, 1, // all players
        ]);

        final header = DemoHeader.fromBytes(bytes);
        expect(header.deathmatch, isTrue);
        expect(header.respawn, isTrue);
        expect(header.fast, isTrue);
        expect(header.noMonsters, isTrue);
        expect(header.consolePlayer, equals(3));
        expect(header.playersInGame, equals([true, true, true, true]));
      });

      test('parses all flags as false', () {
        final bytes = Uint8List.fromList([
          110, 2, 1, 1,
          0, 0, 0, 0, // all flags false
          0, // consoleplayer
          0, 0, 0, 0, // no players
        ]);

        final header = DemoHeader.fromBytes(bytes);
        expect(header.deathmatch, isFalse);
        expect(header.respawn, isFalse);
        expect(header.fast, isFalse);
        expect(header.noMonsters, isFalse);
        expect(header.consolePlayer, equals(0));
        expect(header.playersInGame, equals([false, false, false, false]));
      });

      test('parses all skill levels correctly', () {
        for (final skill in Skill.values) {
          final bytes = Uint8List.fromList([
            110, skill.index, 1, 1,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
          ]);
          final header = DemoHeader.fromBytes(bytes);
          expect(header.skill, equals(skill), reason: 'Failed for $skill');
        }
      });

      test('parses boundary episode values', () {
        for (final episode in [0, 1, 4, 127, 255]) {
          final bytes = Uint8List.fromList([
            110, 2, episode, 1,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
          ]);
          final header = DemoHeader.fromBytes(bytes);
          expect(header.episode, equals(episode),
              reason: 'Failed for episode $episode');
        }
      });

      test('parses boundary map values', () {
        for (final map in [0, 1, 9, 32, 127, 255]) {
          final bytes = Uint8List.fromList([
            110, 2, 1, map,
            0, 0, 0, 0, 0, 0, 0, 0, 0,
          ]);
          final header = DemoHeader.fromBytes(bytes);
          expect(header.map, equals(map), reason: 'Failed for map $map');
        }
      });

      test('parses boundary consoleplayer values', () {
        for (final player in [0, 1, 2, 3]) {
          final bytes = Uint8List.fromList([
            110, 2, 1, 1,
            0, 0, 0, 0, player, 0, 0, 0, 0,
          ]);
          final header = DemoHeader.fromBytes(bytes);
          expect(header.consolePlayer, equals(player),
              reason: 'Failed for player $player');
        }
      });
    });

    group('roundtrip', () {
      test('preserves all values', () {
        final original = DemoHeader(
          version: 110,
          skill: Skill.nightmare,
          episode: 3,
          map: 7,
          deathmatch: true,
          respawn: true,
          fast: false,
          noMonsters: true,
          consolePlayer: 2,
          playersInGame: [true, false, true, true],
        );

        final bytes = original.toBytes();
        final restored = DemoHeader.fromBytes(bytes);

        expect(restored.version, equals(original.version));
        expect(restored.skill, equals(original.skill));
        expect(restored.episode, equals(original.episode));
        expect(restored.map, equals(original.map));
        expect(restored.deathmatch, equals(original.deathmatch));
        expect(restored.respawn, equals(original.respawn));
        expect(restored.fast, equals(original.fast));
        expect(restored.noMonsters, equals(original.noMonsters));
        expect(restored.consolePlayer, equals(original.consolePlayer));
        expect(restored.playersInGame, equals(original.playersInGame));
      });

      test('preserves all skill levels', () {
        for (final skill in Skill.values) {
          final original = DemoHeader(
            version: 110,
            skill: skill,
            episode: 1,
            map: 1,
          );
          final restored = DemoHeader.fromBytes(original.toBytes());
          expect(restored.skill, equals(skill), reason: 'Failed for $skill');
        }
      });

      test('preserves all player combinations', () {
        final combinations = [
          [false, false, false, false],
          [true, false, false, false],
          [true, true, false, false],
          [true, true, true, false],
          [true, true, true, true],
          [false, true, false, true],
        ];

        for (final players in combinations) {
          final original = DemoHeader(
            version: 110,
            skill: Skill.hurtMePlenty,
            episode: 1,
            map: 1,
            playersInGame: players,
          );
          final restored = DemoHeader.fromBytes(original.toBytes());
          expect(restored.playersInGame, equals(players),
              reason: 'Failed for $players');
        }
      });

      test('preserves all flag combinations', () {
        for (var i = 0; i < 16; i++) {
          final deathmatch = (i & 1) != 0;
          final respawn = (i & 2) != 0;
          final fast = (i & 4) != 0;
          final noMonsters = (i & 8) != 0;

          final original = DemoHeader(
            version: 110,
            skill: Skill.hurtMePlenty,
            episode: 1,
            map: 1,
            deathmatch: deathmatch,
            respawn: respawn,
            fast: fast,
            noMonsters: noMonsters,
          );
          final restored = DemoHeader.fromBytes(original.toBytes());
          expect(restored.deathmatch, equals(deathmatch));
          expect(restored.respawn, equals(respawn));
          expect(restored.fast, equals(fast));
          expect(restored.noMonsters, equals(noMonsters));
        }
      });
    });
  });

  group('DemoTic', () {
    test('ticSize is 4', () {
      expect(DemoTic.ticSize, equals(4));
    });

    group('fromTicCmd', () {
      test('creates from TicCmd', () {
        final cmd = TicCmd()
          ..forwardMove = 25
          ..sideMove = -10
          ..angleTurn = 0x1234
          ..buttons = 0x03;

        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.forwardMove, equals(25));
        expect(tic.sideMove, equals(-10));
        expect(tic.angleTurn, equals(0x12)); // High byte only
        expect(tic.buttons, equals(0x03));
      });

      test('handles max forward move (127)', () {
        final cmd = TicCmd()..forwardMove = 127;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.forwardMove, equals(127));
      });

      test('handles min forward move (-127)', () {
        // Note: fromTicCmd clamps to -127..127, not -128..127
        final cmd = TicCmd()..forwardMove = -128;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.forwardMove, equals(-127)); // Clamped to -127
      });

      test('handles max side move (127)', () {
        final cmd = TicCmd()..sideMove = 127;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.sideMove, equals(127));
      });

      test('handles min side move (-127)', () {
        // Note: fromTicCmd clamps to -127..127, not -128..127
        final cmd = TicCmd()..sideMove = -128;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.sideMove, equals(-127)); // Clamped to -127
      });

      test('extracts high byte of angleTurn with +128 offset', () {
        // Original: (cmd->angleturn+128)>>8
        // 0xABCD + 128 = 0xAC4D, >> 8 = 0xAC
        final cmd = TicCmd()..angleTurn = 0xABCD;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.angleTurn, equals(0xAC));
      });

      test('handles max angleTurn (0xFFFF)', () {
        // 0xFFFF + 128 = 0x1007F, >> 8 = 0x100, & 0xFF = 0x00
        final cmd = TicCmd()..angleTurn = 0xFFFF;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.angleTurn, equals(0x00)); // Wraps due to +128 offset
      });

      test('handles max buttons (0xFF)', () {
        final cmd = TicCmd()..buttons = 0xFF;
        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.buttons, equals(0xFF));
      });

      test('handles zero values', () {
        final cmd = TicCmd()
          ..forwardMove = 0
          ..sideMove = 0
          ..angleTurn = 0
          ..buttons = 0;

        final tic = DemoTic.fromTicCmd(cmd);
        expect(tic.forwardMove, equals(0));
        expect(tic.sideMove, equals(0));
        expect(tic.angleTurn, equals(0));
        expect(tic.buttons, equals(0));
      });
    });

    group('fromBytes', () {
      test('parses 4-byte tic', () {
        // 246 = 0xF6 which as signed byte is -10
        final bytes = Uint8List.fromList([25, 246, 0x12, 0x03]);
        final tic = DemoTic.fromBytes(bytes, 0);
        expect(tic.forwardMove, equals(25));
        // sideMove is stored as unsigned byte (246), converted in applyTo
        expect(tic.sideMove, equals(246));
        expect(tic.angleTurn, equals(0x12));
        expect(tic.buttons, equals(0x03));
      });

      test('parses at offset', () {
        final bytes = Uint8List.fromList([0, 0, 0, 0, 50, 100, 0x34, 0x07]);
        final tic = DemoTic.fromBytes(bytes, 4);
        expect(tic.forwardMove, equals(50));
        expect(tic.sideMove, equals(100));
        expect(tic.angleTurn, equals(0x34));
        expect(tic.buttons, equals(0x07));
      });

      test('parses boundary values', () {
        // Max unsigned bytes
        final bytes = Uint8List.fromList([255, 255, 255, 255]);
        final tic = DemoTic.fromBytes(bytes, 0);
        expect(tic.forwardMove, equals(255));
        expect(tic.sideMove, equals(255));
        expect(tic.angleTurn, equals(255));
        expect(tic.buttons, equals(255));
      });

      test('parses zero values', () {
        final bytes = Uint8List.fromList([0, 0, 0, 0]);
        final tic = DemoTic.fromBytes(bytes, 0);
        expect(tic.forwardMove, equals(0));
        expect(tic.sideMove, equals(0));
        expect(tic.angleTurn, equals(0));
        expect(tic.buttons, equals(0));
      });
    });

    group('writeToBytes', () {
      test('writes 4-byte tic', () {
        final tic = DemoTic(
          forwardMove: 25,
          sideMove: -10,
          angleTurn: 0x12,
          buttons: 0x03,
        );

        final bytes = Uint8List(4);
        tic.writeToBytes(bytes, 0);

        expect(bytes[0], equals(25));
        expect(bytes[1], equals(246)); // -10 as unsigned byte
        expect(bytes[2], equals(0x12));
        expect(bytes[3], equals(0x03));
      });

      test('writes at offset', () {
        final tic = DemoTic(
          forwardMove: 50,
          sideMove: 100,
          angleTurn: 0x34,
          buttons: 0x07,
        );

        final bytes = Uint8List(8);
        tic.writeToBytes(bytes, 4);

        expect(bytes[4], equals(50));
        expect(bytes[5], equals(100));
        expect(bytes[6], equals(0x34));
        expect(bytes[7], equals(0x07));
      });

      test('writes max positive values', () {
        final tic = DemoTic(
          forwardMove: 127,
          sideMove: 127,
          angleTurn: 0xFF,
          buttons: 0xFF,
        );

        final bytes = Uint8List(4);
        tic.writeToBytes(bytes, 0);

        expect(bytes[0], equals(127));
        expect(bytes[1], equals(127));
        expect(bytes[2], equals(0xFF));
        expect(bytes[3], equals(0xFF));
      });

      test('writes max negative values', () {
        final tic = DemoTic(
          forwardMove: -128,
          sideMove: -128,
          angleTurn: 0,
          buttons: 0,
        );

        final bytes = Uint8List(4);
        tic.writeToBytes(bytes, 0);

        expect(bytes[0], equals(128)); // -128 as unsigned byte
        expect(bytes[1], equals(128));
        expect(bytes[2], equals(0));
        expect(bytes[3], equals(0));
      });
    });

    group('applyTo', () {
      test('sets TicCmd values', () {
        final tic = DemoTic(
          forwardMove: 25,
          sideMove: -10,
          angleTurn: 0x12,
          buttons: 0x03,
        );

        final cmd = TicCmd();
        tic.applyTo(cmd);

        expect(cmd.forwardMove, equals(25));
        expect(cmd.sideMove, equals(-10));
        expect(cmd.angleTurn, equals(0x1200)); // Shifted left by 8
        expect(cmd.buttons, equals(0x03));
      });

      test('handles max positive values', () {
        final tic = DemoTic(
          forwardMove: 127,
          sideMove: 127,
          angleTurn: 0xFF,
          buttons: 0xFF,
        );

        final cmd = TicCmd();
        tic.applyTo(cmd);

        expect(cmd.forwardMove, equals(127));
        expect(cmd.sideMove, equals(127));
        expect(cmd.angleTurn, equals(0xFF00));
        expect(cmd.buttons, equals(0xFF));
      });

      test('handles max negative values', () {
        final tic = DemoTic(
          forwardMove: -128,
          sideMove: -128,
          angleTurn: 0,
          buttons: 0,
        );

        final cmd = TicCmd();
        tic.applyTo(cmd);

        expect(cmd.forwardMove, equals(-128));
        expect(cmd.sideMove, equals(-128));
        expect(cmd.angleTurn, equals(0));
        expect(cmd.buttons, equals(0));
      });

      test('handles zero values', () {
        final tic = DemoTic(
          forwardMove: 0,
          sideMove: 0,
          angleTurn: 0,
          buttons: 0,
        );

        final cmd = TicCmd();
        tic.applyTo(cmd);

        expect(cmd.forwardMove, equals(0));
        expect(cmd.sideMove, equals(0));
        expect(cmd.angleTurn, equals(0));
        expect(cmd.buttons, equals(0));
      });
    });

    group('roundtrip through TicCmd', () {
      test('preserves values', () {
        final original = TicCmd()
          ..forwardMove = 50
          ..sideMove = -25
          ..angleTurn = 0x5600
          ..buttons = 0x05;

        final tic = DemoTic.fromTicCmd(original);
        final restored = TicCmd();
        tic.applyTo(restored);

        expect(restored.forwardMove, equals(original.forwardMove));
        expect(restored.sideMove, equals(original.sideMove));
        // Note: angleTurn loses precision (low byte discarded)
        expect(restored.angleTurn, equals(0x5600));
        expect(restored.buttons, equals(original.buttons));
      });

      test('preserves max values', () {
        final original = TicCmd()
          ..forwardMove = 127
          ..sideMove = 127
          ..angleTurn = 0xFF00
          ..buttons = 0xFF;

        final tic = DemoTic.fromTicCmd(original);
        final restored = TicCmd();
        tic.applyTo(restored);

        expect(restored.forwardMove, equals(127));
        expect(restored.sideMove, equals(127));
        expect(restored.angleTurn, equals(0xFF00));
        expect(restored.buttons, equals(0xFF));
      });

      test('preserves min values', () {
        // Note: fromTicCmd clamps to -127..127
        final original = TicCmd()
          ..forwardMove = -127
          ..sideMove = -127
          ..angleTurn = 0
          ..buttons = 0;

        final tic = DemoTic.fromTicCmd(original);
        final restored = TicCmd();
        tic.applyTo(restored);

        expect(restored.forwardMove, equals(-127));
        expect(restored.sideMove, equals(-127));
        // angleTurn 0 + 128 = 128, >> 8 = 0, << 8 = 0
        expect(restored.angleTurn, equals(0));
        expect(restored.buttons, equals(0));
      });

      test('angleTurn has +128 rounding offset', () {
        // Original stores: (angleturn+128)>>8
        // Restored: stored<<8
        // So 0x56AB + 128 = 0x572B, >> 8 = 0x57, << 8 = 0x5700
        final original = TicCmd()..angleTurn = 0x56AB;

        final tic = DemoTic.fromTicCmd(original);
        final restored = TicCmd();
        tic.applyTo(restored);

        expect(restored.angleTurn, equals(0x5700));
      });
    });

    group('roundtrip through bytes', () {
      test('preserves positive values', () {
        final original = DemoTic(
          forwardMove: 50,
          sideMove: 25,
          angleTurn: 0x12,
          buttons: 0x05,
        );

        final bytes = Uint8List(4);
        original.writeToBytes(bytes, 0);
        final restored = DemoTic.fromBytes(bytes, 0);

        expect(restored.forwardMove, equals(original.forwardMove));
        expect(restored.sideMove, equals(original.sideMove));
        expect(restored.angleTurn, equals(original.angleTurn));
        expect(restored.buttons, equals(original.buttons));
      });

      test('preserves max unsigned byte values', () {
        final original = DemoTic(
          forwardMove: 255,
          sideMove: 255,
          angleTurn: 255,
          buttons: 255,
        );

        final bytes = Uint8List(4);
        original.writeToBytes(bytes, 0);
        final restored = DemoTic.fromBytes(bytes, 0);

        expect(restored.forwardMove, equals(255));
        expect(restored.sideMove, equals(255));
        expect(restored.angleTurn, equals(255));
        expect(restored.buttons, equals(255));
      });

      test('preserves zero values', () {
        final original = DemoTic(
          forwardMove: 0,
          sideMove: 0,
          angleTurn: 0,
          buttons: 0,
        );

        final bytes = Uint8List(4);
        original.writeToBytes(bytes, 0);
        final restored = DemoTic.fromBytes(bytes, 0);

        expect(restored.forwardMove, equals(0));
        expect(restored.sideMove, equals(0));
        expect(restored.angleTurn, equals(0));
        expect(restored.buttons, equals(0));
      });

      test('handles negative values through byte conversion', () {
        final original = DemoTic(
          forwardMove: -10,
          sideMove: -50,
          angleTurn: 0x80,
          buttons: 0x01,
        );

        final bytes = Uint8List(4);
        original.writeToBytes(bytes, 0);

        // Verify bytes are stored as unsigned
        expect(bytes[0], equals(246)); // -10 as unsigned
        expect(bytes[1], equals(206)); // -50 as unsigned

        final restored = DemoTic.fromBytes(bytes, 0);
        // fromBytes stores as unsigned, applyTo converts back
        expect(restored.forwardMove, equals(246));
        expect(restored.sideMove, equals(206));
      });
    });
  });
}
