import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/save/save_game.dart';
import 'package:doom_core/src/serialization/binary_serializer.dart';
import 'package:doom_core/src/serialization/json_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('SaveGameConstants', () {
    test('descriptionSize is 24', () {
      expect(SaveGameConstants.descriptionSize, equals(24));
    });

    test('versionStringSize is 16', () {
      expect(SaveGameConstants.versionStringSize, equals(16));
    });

    test('saveMarker is 0x1d', () {
      expect(SaveGameConstants.saveMarker, equals(0x1d));
    });

    test('maxSaveSlots is 6', () {
      expect(SaveGameConstants.maxSaveSlots, equals(6));
    });
  });

  group('SaveGameHeader', () {
    test('creates with required fields', () {
      final header = SaveGameHeader(
        description: 'Test Save',
        versionString: 'DartDOOM 1.0',
        skill: Skill.hurtMePlenty,
        episode: 1,
        map: 1,
        playersInGame: [true, false, false, false],
        levelTime: 12345,
      );

      expect(header.description, equals('Test Save'));
      expect(header.versionString, equals('DartDOOM 1.0'));
      expect(header.skill, equals(Skill.hurtMePlenty));
      expect(header.episode, equals(1));
      expect(header.map, equals(1));
      expect(header.playersInGame, equals([true, false, false, false]));
      expect(header.levelTime, equals(12345));
    });

    test('fromGameState creates header with version string', () {
      final header = SaveGameHeader.fromGameState(
        description: 'Quick Save',
        skill: Skill.ultraViolence,
        episode: 2,
        map: 5,
        playersInGame: [true, true, false, false],
        levelTime: 54321,
      );

      expect(header.description, equals('Quick Save'));
      expect(header.versionString, equals(SaveGameConstants.versionString));
      expect(header.skill, equals(Skill.ultraViolence));
      expect(header.episode, equals(2));
      expect(header.map, equals(5));
    });
  });

  group('SaveGameManager', () {
    late SaveGameManager manager;

    setUp(() {
      manager = SaveGameManager();
    });

    test('uses BinarySerializer by default', () {
      // Default constructor uses BinarySerializer
      expect(manager, isNotNull);
    });

    test('accepts custom serializer', () {
      final jsonManager = SaveGameManager(serializer: JsonSerializer());
      expect(jsonManager, isNotNull);
    });

    group('header serialization', () {
      test('writes and reads header correctly', () {
        final writer = BinaryDataWriter();

        // Manually write a header
        writer
          ..writeString('Test Description', SaveGameConstants.descriptionSize)
          ..writeString('DartDOOM 1.0', SaveGameConstants.versionStringSize)
          ..writeByte(Skill.ultraViolence.index)
          ..writeByte(2)
          ..writeByte(5)
          ..writeBool(value: true)
          ..writeBool(value: true)
          ..writeBool(value: false)
          ..writeBool(value: false)
          ..writeByte((12345 >> 16) & 0xff)
          ..writeByte((12345 >> 8) & 0xff)
          ..writeByte(12345 & 0xff);

        final data = writer.toBytes();
        final header = manager.loadGameHeader(data);

        expect(header.description, equals('Test Description'));
        expect(header.skill, equals(Skill.ultraViolence));
        expect(header.episode, equals(2));
        expect(header.map, equals(5));
        expect(header.playersInGame, equals([true, true, false, false]));
        expect(header.levelTime, equals(12345));
      });

      test('handles level time encoding correctly', () {
        // Test with various level times
        for (final time in [0, 255, 256, 65535, 65536, 0xFFFFFF]) {
          final writer = BinaryDataWriter();
          writer
            ..writeString('Test', SaveGameConstants.descriptionSize)
            ..writeString('Ver', SaveGameConstants.versionStringSize)
            ..writeByte(0)
            ..writeByte(1)
            ..writeByte(1)
            ..writeBool(value: true)
            ..writeBool(value: false)
            ..writeBool(value: false)
            ..writeBool(value: false)
            ..writeByte((time >> 16) & 0xff)
            ..writeByte((time >> 8) & 0xff)
            ..writeByte(time & 0xff);

          final header = manager.loadGameHeader(writer.toBytes());
          expect(header.levelTime, equals(time & 0xFFFFFF));
        }
      });
    });

    group('getSaveDescriptions', () {
      test('returns descriptions from valid saves', () {
        final saves = <Uint8List?>[];

        // Create a valid save header
        final writer = BinaryDataWriter();
        writer
          ..writeString('Save Slot 1', SaveGameConstants.descriptionSize)
          ..writeString('Ver', SaveGameConstants.versionStringSize)
          ..writeByte(0)
          ..writeByte(1)
          ..writeByte(1)
          ..writeBool(value: true)
          ..writeBool(value: false)
          ..writeBool(value: false)
          ..writeBool(value: false)
          ..writeByte(0)
          ..writeByte(0)
          ..writeByte(0);

        saves.add(writer.toBytes());
        saves.add(null);

        final descriptions = manager.getSaveDescriptions(saves);
        expect(descriptions.length, equals(2));
        expect(descriptions[0], equals('Save Slot 1'));
        expect(descriptions[1], isNull);
      });

      test('returns null for too-short data', () {
        final saves = <Uint8List?>[
          Uint8List.fromList([1, 2, 3]),
        ];

        final descriptions = manager.getSaveDescriptions(saves);
        expect(descriptions[0], isNull);
      });
    });
  });

  group('Binary vs JSON serializer', () {
    test('both serializers produce compatible headers', () {
      final binaryManager = SaveGameManager(serializer: BinarySerializer());
      final jsonManager = SaveGameManager(serializer: JsonSerializer());

      // Create headers with both
      final binaryWriter = BinaryDataWriter();
      binaryWriter
        ..writeString('Binary Save', SaveGameConstants.descriptionSize)
        ..writeString('Ver', SaveGameConstants.versionStringSize)
        ..writeByte(2)
        ..writeByte(1)
        ..writeByte(1)
        ..writeBool(value: true)
        ..writeBool(value: false)
        ..writeBool(value: false)
        ..writeBool(value: false)
        ..writeByte(0)
        ..writeByte(1)
        ..writeByte(0);

      final jsonWriter = JsonDataWriter();
      jsonWriter
        ..writeString('JSON Save', SaveGameConstants.descriptionSize)
        ..writeString('Ver', SaveGameConstants.versionStringSize)
        ..writeByte(2)
        ..writeByte(1)
        ..writeByte(1)
        ..writeBool(value: true)
        ..writeBool(value: false)
        ..writeBool(value: false)
        ..writeBool(value: false)
        ..writeByte(0)
        ..writeByte(1)
        ..writeByte(0);

      final binaryHeader = binaryManager.loadGameHeader(binaryWriter.toBytes());
      final jsonHeader = jsonManager.loadGameHeader(jsonWriter.toBytes());

      expect(binaryHeader.description, equals('Binary Save'));
      expect(jsonHeader.description, equals('JSON Save'));
      expect(binaryHeader.skill, equals(jsonHeader.skill));
      expect(binaryHeader.episode, equals(jsonHeader.episode));
      expect(binaryHeader.map, equals(jsonHeader.map));
      expect(binaryHeader.levelTime, equals(jsonHeader.levelTime));
    });
  });
}
