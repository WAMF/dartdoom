import 'dart:convert';
import 'dart:typed_data';

import 'package:doom_core/src/serialization/json_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('JsonSerializer', () {
    late JsonSerializer serializer;

    setUp(() {
      serializer = JsonSerializer();
    });

    test('formatExtension returns .json', () {
      expect(serializer.formatExtension, equals('.json'));
    });

    test('formatName returns JSON', () {
      expect(serializer.formatName, equals('JSON'));
    });

    group('JsonDataWriter', () {
      late JsonDataWriter writer;

      setUp(() {
        writer = JsonDataWriter();
      });

      group('writeByte', () {
        test('stores byte value', () {
          writer.writeByte(0x42);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(0x42));
        });

        test('masks to 8 bits', () {
          writer.writeByte(0x1FF);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(0xFF));
        });

        test('handles min value 0x00', () {
          writer.writeByte(0x00);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(0x00));
        });

        test('handles max value 0xFF', () {
          writer.writeByte(0xFF);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(0xFF));
        });
      });

      group('writeShort', () {
        test('stores signed 16-bit value', () {
          writer.writeShort(-1);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(-1));
        });

        test('handles min signed 16-bit (-32768)', () {
          writer.writeShort(-32768);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(-32768));
        });

        test('handles max signed 16-bit (32767)', () {
          writer.writeShort(32767);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(32767));
        });

        test('handles zero', () {
          writer.writeShort(0);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(0));
        });
      });

      group('writeInt', () {
        test('stores signed 32-bit value', () {
          writer.writeInt(-12345678);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(-12345678));
        });

        test('handles min signed 32-bit (-2147483648)', () {
          writer.writeInt(-2147483648);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(-2147483648));
        });

        test('handles max signed 32-bit (2147483647)', () {
          writer.writeInt(2147483647);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(2147483647));
        });

        test('handles zero', () {
          writer.writeInt(0);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(0));
        });
      });

      group('writeFixed', () {
        test('stores map with raw and decimal', () {
          writer.writeFixed(65536); // 1.0 in fixed-point
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final fixed = data[0] as Map<String, dynamic>;
          expect(fixed['raw'], equals(65536));
          expect(fixed['decimal'], equals(1.0));
        });

        test('handles 0.5 fixed-point (32768)', () {
          writer.writeFixed(32768);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final fixed = data[0] as Map<String, dynamic>;
          expect(fixed['raw'], equals(32768));
          expect(fixed['decimal'], equals(0.5));
        });

        test('handles negative fixed-point (-1.0 = -65536)', () {
          writer.writeFixed(-65536);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final fixed = data[0] as Map<String, dynamic>;
          expect(fixed['raw'], equals(-65536));
          expect(fixed['decimal'], equals(-1.0));
        });

        test('handles max fixed-point (2147483647)', () {
          writer.writeFixed(2147483647);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final fixed = data[0] as Map<String, dynamic>;
          expect(fixed['raw'], equals(2147483647));
        });

        test('handles min fixed-point (-2147483648)', () {
          writer.writeFixed(-2147483648);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final fixed = data[0] as Map<String, dynamic>;
          expect(fixed['raw'], equals(-2147483648));
        });
      });

      group('writeString', () {
        test('stores string value', () {
          writer.writeString('Hello', 10);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals('Hello'));
        });

        test('truncates long strings', () {
          writer.writeString('HelloWorld', 5);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals('Hello'));
        });

        test('handles empty string', () {
          writer.writeString('', 10);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals(''));
        });

        test('handles exact length string', () {
          writer.writeString('ABCD', 4);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals('ABCD'));
        });

        test('handles maxLength of 1', () {
          writer.writeString('Hello', 1);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], equals('H'));
        });
      });

      group('writeBool', () {
        test('stores boolean value', () {
          writer
            ..writeBool(value: true)
            ..writeBool(value: false);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data[0], isTrue);
          expect(data[1], isFalse);
        });
      });

      group('writeBytes', () {
        test('stores base64 encoded bytes', () {
          writer.writeBytes([0x01, 0x02, 0x03]);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final bytes = data[0] as Map<String, dynamic>;
          expect(bytes['bytes'], equals(base64Encode([0x01, 0x02, 0x03])));
        });

        test('handles empty byte list', () {
          writer.writeBytes([]);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final bytes = data[0] as Map<String, dynamic>;
          expect(bytes['bytes'], equals(base64Encode([])));
        });

        test('handles all byte values 0x00-0xFF', () {
          final allBytes = List.generate(256, (i) => i);
          writer.writeBytes(allBytes);
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          final bytes = data[0] as Map<String, dynamic>;
          expect(bytes['bytes'], equals(base64Encode(allBytes)));
        });
      });

      group('pad', () {
        test('adds padding marker', () {
          writer
            ..writeByte(0x01)
            ..pad();
          final text = writer.toText();
          final decoded = jsonDecode(text) as Map<String, dynamic>;
          final data = decoded['data'] as List;
          expect(data.length, equals(2));
          expect((data[1] as Map)['_pad'], isTrue);
        });
      });

      group('output', () {
        test('toBytes returns UTF-8 encoded JSON', () {
          writer.writeByte(0x42);
          final bytes = writer.toBytes();
          final text = utf8.decode(bytes);
          expect(text, contains('"data"'));
        });

        test('toText returns formatted JSON', () {
          writer.writeByte(0x42);
          final text = writer.toText();
          expect(text, contains('\n')); // Pretty printed
          expect(text, contains('"data"'));
        });

        test('position tracks values written', () {
          expect(writer.position, equals(0));
          writer.writeByte(0x01);
          expect(writer.position, equals(1));
          writer.writeShort(0x1234);
          expect(writer.position, equals(2));
          writer.writeInt(0x12345678);
          expect(writer.position, equals(3));
        });
      });
    });

    group('JsonDataReader', () {
      group('readByte', () {
        test('reads byte value', () {
          const json = '{"data": [66]}';
          final reader = JsonDataReader(json);
          expect(reader.readByte(), equals(66));
        });

        test('reads 0x00', () {
          const json = '{"data": [0]}';
          final reader = JsonDataReader(json);
          expect(reader.readByte(), equals(0));
        });

        test('reads 0xFF', () {
          const json = '{"data": [255]}';
          final reader = JsonDataReader(json);
          expect(reader.readByte(), equals(255));
        });
      });

      group('readShort', () {
        test('reads signed 16-bit value', () {
          const json = '{"data": [-1234]}';
          final reader = JsonDataReader(json);
          expect(reader.readShort(), equals(-1234));
        });

        test('reads min signed 16-bit (-32768)', () {
          const json = '{"data": [-32768]}';
          final reader = JsonDataReader(json);
          expect(reader.readShort(), equals(-32768));
        });

        test('reads max signed 16-bit (32767)', () {
          const json = '{"data": [32767]}';
          final reader = JsonDataReader(json);
          expect(reader.readShort(), equals(32767));
        });

        test('reads zero', () {
          const json = '{"data": [0]}';
          final reader = JsonDataReader(json);
          expect(reader.readShort(), equals(0));
        });
      });

      group('readInt', () {
        test('reads signed 32-bit value', () {
          const json = '{"data": [-12345678]}';
          final reader = JsonDataReader(json);
          expect(reader.readInt(), equals(-12345678));
        });

        test('reads min signed 32-bit (-2147483648)', () {
          const json = '{"data": [-2147483648]}';
          final reader = JsonDataReader(json);
          expect(reader.readInt(), equals(-2147483648));
        });

        test('reads max signed 32-bit (2147483647)', () {
          const json = '{"data": [2147483647]}';
          final reader = JsonDataReader(json);
          expect(reader.readInt(), equals(2147483647));
        });

        test('reads zero', () {
          const json = '{"data": [0]}';
          final reader = JsonDataReader(json);
          expect(reader.readInt(), equals(0));
        });
      });

      group('readFixed', () {
        test('reads fixed-point map', () {
          const json = '{"data": [{"raw": 65536, "decimal": 1.0}]}';
          final reader = JsonDataReader(json);
          expect(reader.readFixed(), equals(65536));
        });

        test('reads plain int for compatibility', () {
          const json = '{"data": [65536]}';
          final reader = JsonDataReader(json);
          expect(reader.readFixed(), equals(65536));
        });

        test('reads negative fixed-point (-1.0)', () {
          const json = '{"data": [{"raw": -65536, "decimal": -1.0}]}';
          final reader = JsonDataReader(json);
          expect(reader.readFixed(), equals(-65536));
        });

        test('reads max fixed-point', () {
          const json = '{"data": [{"raw": 2147483647, "decimal": 32767.99998}]}';
          final reader = JsonDataReader(json);
          expect(reader.readFixed(), equals(2147483647));
        });

        test('reads min fixed-point', () {
          const json = '{"data": [{"raw": -2147483648, "decimal": -32768.0}]}';
          final reader = JsonDataReader(json);
          expect(reader.readFixed(), equals(-2147483648));
        });
      });

      group('readString', () {
        test('reads string value', () {
          const json = '{"data": ["Hello"]}';
          final reader = JsonDataReader(json);
          expect(reader.readString(10), equals('Hello'));
        });

        test('truncates long string to maxLength', () {
          const json = '{"data": ["HelloWorld"]}';
          final reader = JsonDataReader(json);
          expect(reader.readString(5), equals('Hello'));
        });

        test('reads empty string', () {
          const json = '{"data": [""]}';
          final reader = JsonDataReader(json);
          expect(reader.readString(10), equals(''));
        });
      });

      group('readBool', () {
        test('reads boolean value', () {
          const json = '{"data": [true, false]}';
          final reader = JsonDataReader(json);
          expect(reader.readBool(), isTrue);
          expect(reader.readBool(), isFalse);
        });

        test('reads int as bool (1 = true, 0 = false)', () {
          const json = '{"data": [1, 0]}';
          final reader = JsonDataReader(json);
          expect(reader.readBool(), isTrue);
          expect(reader.readBool(), isFalse);
        });

        test('reads any non-zero int as true', () {
          const json = '{"data": [255, 42, -1]}';
          final reader = JsonDataReader(json);
          expect(reader.readBool(), isTrue);
          expect(reader.readBool(), isTrue);
          expect(reader.readBool(), isTrue);
        });
      });

      group('readBytes', () {
        test('reads base64 encoded bytes', () {
          final encoded = base64Encode([0x01, 0x02, 0x03]);
          final json = '{"data": [{"bytes": "$encoded"}]}';
          final reader = JsonDataReader(json);
          expect(reader.readBytes(3), equals([0x01, 0x02, 0x03]));
        });

        test('reads empty bytes', () {
          final encoded = base64Encode([]);
          final json = '{"data": [{"bytes": "$encoded"}]}';
          final reader = JsonDataReader(json);
          expect(reader.readBytes(0), equals([]));
        });

        test('reads all byte values 0x00-0xFF', () {
          final allBytes = List.generate(256, (i) => i);
          final encoded = base64Encode(allBytes);
          final json = '{"data": [{"bytes": "$encoded"}]}';
          final reader = JsonDataReader(json);
          final result = reader.readBytes(256);
          for (var i = 0; i < 256; i++) {
            expect(result[i], equals(i));
          }
        });
      });

      group('skipPadding', () {
        test('skips padding marker', () {
          const json = '{"data": [1, {"_pad": true}, 2]}';
          final reader = JsonDataReader(json);
          reader.readByte();
          reader.skipPadding();
          expect(reader.readByte(), equals(2));
        });

        test('does nothing when no padding marker', () {
          const json = '{"data": [1, 2]}';
          final reader = JsonDataReader(json);
          reader.readByte();
          reader.skipPadding();
          expect(reader.readByte(), equals(2));
        });
      });

      group('isAtEnd', () {
        test('returns false initially when data exists', () {
          const json = '{"data": [1]}';
          final reader = JsonDataReader(json);
          expect(reader.isAtEnd, isFalse);
        });

        test('returns true when exhausted', () {
          const json = '{"data": [1]}';
          final reader = JsonDataReader(json);
          reader.readByte();
          expect(reader.isAtEnd, isTrue);
        });

        test('returns true for empty data', () {
          const json = '{"data": []}';
          final reader = JsonDataReader(json);
          expect(reader.isAtEnd, isTrue);
        });
      });

      group('position', () {
        test('starts at 0', () {
          const json = '{"data": [1, 2, 3]}';
          final reader = JsonDataReader(json);
          expect(reader.position, equals(0));
        });

        test('tracks values read', () {
          const json = '{"data": [1, 2, 3]}';
          final reader = JsonDataReader(json);
          reader.readByte();
          expect(reader.position, equals(1));
          reader.readByte();
          expect(reader.position, equals(2));
        });
      });

      group('error handling', () {
        test('throws on read past end', () {
          const json = '{"data": []}';
          final reader = JsonDataReader(json);
          expect(reader.readByte, throwsStateError);
        });

        test('throws on readByte with wrong type', () {
          const json = '{"data": ["not a number"]}';
          final reader = JsonDataReader(json);
          expect(reader.readByte, throwsStateError);
        });

        test('throws on readString with wrong type', () {
          const json = '{"data": [123]}';
          final reader = JsonDataReader(json);
          expect(() => reader.readString(10), throwsStateError);
        });

        test('throws on readBytes with wrong type', () {
          const json = '{"data": [123]}';
          final reader = JsonDataReader(json);
          expect(() => reader.readBytes(1), throwsStateError);
        });
      });
    });

    group('roundtrip serialization', () {
      test('byte roundtrip preserves all values 0x00-0xFF', () {
        final writer = JsonDataWriter();
        for (var i = 0; i < 256; i++) {
          writer.writeByte(i);
        }

        final reader = JsonDataReader(writer.toText());
        for (var i = 0; i < 256; i++) {
          expect(reader.readByte(), equals(i));
        }
      });

      test('short roundtrip preserves boundary values', () {
        final writer = JsonDataWriter();
        const values = [
          0, // Zero
          1, // Positive
          -1, // Negative
          32767, // Max signed 16-bit
          -32768, // Min signed 16-bit
          0x1234, // Arbitrary positive
        ];

        for (final v in values) {
          writer.writeShort(v);
        }

        final reader = JsonDataReader(writer.toText());
        for (final v in values) {
          expect(
            reader.readShort(),
            equals(v.toSigned(16)),
            reason: 'Failed for value $v',
          );
        }
      });

      test('int roundtrip preserves boundary values', () {
        final writer = JsonDataWriter();
        const values = [
          0, // Zero
          1, // Positive
          -1, // Negative
          2147483647, // Max signed 32-bit
          -2147483648, // Min signed 32-bit
          0x12345678, // Arbitrary positive
          -12345678, // Arbitrary negative
        ];

        for (final v in values) {
          writer.writeInt(v);
        }

        final reader = JsonDataReader(writer.toText());
        for (final v in values) {
          expect(
            reader.readInt(),
            equals(v.toSigned(32)),
            reason: 'Failed for value $v',
          );
        }
      });

      test('fixed roundtrip preserves DOOM fixed-point values', () {
        final writer = JsonDataWriter();
        const fracUnit = 65536; // FRACUNIT
        final values = [
          0, // 0.0
          fracUnit, // 1.0
          fracUnit ~/ 2, // 0.5
          -fracUnit, // -1.0
          fracUnit * 100, // 100.0
          -fracUnit * 100, // -100.0
          2147483647, // Max fixed-point
          -2147483648, // Min fixed-point
          fracUnit + 32768, // 1.5
        ];

        for (final v in values) {
          writer.writeFixed(v);
        }

        final reader = JsonDataReader(writer.toText());
        for (final v in values) {
          expect(
            reader.readFixed(),
            equals(v.toSigned(32)),
            reason: 'Failed for fixed value $v',
          );
        }
      });

      test('string roundtrip preserves values', () {
        final writer = JsonDataWriter();
        const strings = [
          'Test', // Normal string
          '', // Empty string
          'ABCDEFGH', // 8 chars
        ];

        for (final s in strings) {
          writer.writeString(s, 8);
        }

        final reader = JsonDataReader(writer.toText());
        for (final s in strings) {
          expect(reader.readString(8), equals(s), reason: 'Failed for "$s"');
        }
      });

      test('bool roundtrip preserves values', () {
        final writer = JsonDataWriter();
        final values = [true, false, true, true, false];

        for (final v in values) {
          writer.writeBool(value: v);
        }

        final reader = JsonDataReader(writer.toText());
        for (final v in values) {
          expect(reader.readBool(), equals(v));
        }
      });

      test('bytes roundtrip preserves values', () {
        final writer = JsonDataWriter();
        final testBytes = [
          [0x00], // Min byte
          [0xFF], // Max byte
          [0x01, 0x02, 0x03], // Sequence
          List.generate(256, (i) => i), // All bytes
        ];

        for (final bytes in testBytes) {
          writer.writeBytes(bytes);
        }

        final reader = JsonDataReader(writer.toText());
        for (final bytes in testBytes) {
          expect(reader.readBytes(bytes.length), equals(bytes));
        }
      });

      test('mixed data roundtrip preserves all values', () {
        final writer = JsonDataWriter();
        writer
          ..writeByte(0x42)
          ..writeShort(-1234)
          ..writeInt(0x12345678)
          ..writeFixed(65536)
          ..writeString('Test', 8)
          ..writeBool(value: true)
          ..writeBool(value: false)
          ..writeBytes([0x01, 0x02, 0x03, 0x04]);

        final reader = JsonDataReader(writer.toText());
        expect(reader.readByte(), equals(0x42));
        expect(reader.readShort(), equals(-1234));
        expect(reader.readInt(), equals(0x12345678));
        expect(reader.readFixed(), equals(65536));
        expect(reader.readString(8), equals('Test'));
        expect(reader.readBool(), isTrue);
        expect(reader.readBool(), isFalse);
        expect(reader.readBytes(4), equals([0x01, 0x02, 0x03, 0x04]));
        expect(reader.isAtEnd, isTrue);
      });

      test('padding roundtrip maintains alignment', () {
        final writer = JsonDataWriter();
        writer
          ..writeByte(0x01)
          ..pad()
          ..writeInt(0x12345678)
          ..writeByte(0x02)
          ..pad()
          ..writeShort(0x5678);

        final reader = JsonDataReader(writer.toText());
        expect(reader.readByte(), equals(0x01));
        reader.skipPadding();
        expect(reader.readInt(), equals(0x12345678));
        expect(reader.readByte(), equals(0x02));
        reader.skipPadding();
        expect(reader.readShort(), equals(0x5678));
      });
    });

    group('createReader', () {
      test('accepts Uint8List', () {
        final writer = JsonDataWriter();
        writer.writeByte(0x42);

        final reader = serializer.createReader(writer.toBytes());
        expect(reader.readByte(), equals(0x42));
      });

      test('accepts String', () {
        final writer = JsonDataWriter();
        writer.writeByte(0x42);

        final reader = serializer.createReader(writer.toText());
        expect(reader.readByte(), equals(0x42));
      });

      test('throws for invalid type', () {
        expect(() => serializer.createReader(123), throwsArgumentError);
      });
    });
  });
}
