import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

Uint8List _createPnamesLump(List<String> names) {
  final bytes = ByteData(4 + names.length * 8);
  bytes.setInt32(0, names.length, Endian.little);

  for (var i = 0; i < names.length; i++) {
    final nameBytes = names[i].codeUnits;
    for (var j = 0; j < 8; j++) {
      bytes.setUint8(4 + i * 8 + j, j < nameBytes.length ? nameBytes[j] : 0);
    }
  }

  return Uint8List.view(bytes.buffer);
}

Uint8List _createTextureLump(List<_TextureEntry> textures) {
  final offsets = <int>[];
  final textureData = <int>[];

  final headerSize = 4 + textures.length * 4;
  var currentOffset = headerSize;

  for (final tex in textures) {
    offsets.add(currentOffset);

    final nameBytes = tex.name.codeUnits;
    for (var j = 0; j < 8; j++) {
      textureData.add(j < nameBytes.length ? nameBytes[j] : 0);
    }

    textureData.addAll([0, 0, 0, 0]);

    textureData
      ..add(tex.width & 0xFF)
      ..add((tex.width >> 8) & 0xFF)
      ..add(tex.height & 0xFF)
      ..add((tex.height >> 8) & 0xFF);

    textureData.addAll([0, 0, 0, 0]);

    textureData
      ..add(tex.patches.length & 0xFF)
      ..add((tex.patches.length >> 8) & 0xFF);

    for (final patch in tex.patches) {
      textureData
        ..add(patch.originX & 0xFF)
        ..add((patch.originX >> 8) & 0xFF)
        ..add(patch.originY & 0xFF)
        ..add((patch.originY >> 8) & 0xFF)
        ..add(patch.patchIndex & 0xFF)
        ..add((patch.patchIndex >> 8) & 0xFF)
        ..addAll([0, 0, 0, 0]);
    }

    currentOffset = headerSize + textureData.length;
  }

  final result = ByteData(headerSize + textureData.length);
  result.setInt32(0, textures.length, Endian.little);

  for (var i = 0; i < offsets.length; i++) {
    result.setInt32(4 + i * 4, offsets[i], Endian.little);
  }

  for (var i = 0; i < textureData.length; i++) {
    result.setUint8(headerSize + i, textureData[i]);
  }

  return Uint8List.view(result.buffer);
}

class _TextureEntry {
  _TextureEntry(this.name, this.width, this.height, this.patches);
  final String name;
  final int width;
  final int height;
  final List<_PatchEntry> patches;
}

class _PatchEntry {
  _PatchEntry(this.originX, this.originY, this.patchIndex);
  final int originX;
  final int originY;
  final int patchIndex;
}

void main() {
  group('TexturePatch', () {
    test('stores origin and patch index', () {
      const patch = TexturePatch(
        originX: 10,
        originY: 20,
        patchIndex: 5,
      );

      expect(patch.originX, 10);
      expect(patch.originY, 20);
      expect(patch.patchIndex, 5);
    });
  });

  group('TextureDef', () {
    test('stores texture definition', () {
      const def = TextureDef(
        name: 'STARTAN1',
        width: 128,
        height: 128,
        patches: [
          TexturePatch(originX: 0, originY: 0, patchIndex: 0),
        ],
      );

      expect(def.name, 'STARTAN1');
      expect(def.width, 128);
      expect(def.height, 128);
      expect(def.patches.length, 1);
    });
  });

  group('PatchNames', () {
    test('parses patch names', () {
      final data = _createPnamesLump(['WALL00', 'WALL01', 'DOOR02']);

      final pnames = PatchNames.parse(data);

      expect(pnames.length, 3);
      expect(pnames[0], 'WALL00');
      expect(pnames[1], 'WALL01');
      expect(pnames[2], 'DOOR02');
    });

    test('names list is accessible', () {
      final data = _createPnamesLump(['TEST']);

      final pnames = PatchNames.parse(data);

      expect(pnames.names, ['TEST']);
    });

    test('handles empty pnames', () {
      final data = _createPnamesLump([]);

      final pnames = PatchNames.parse(data);

      expect(pnames.length, 0);
    });

    test('converts names to uppercase', () {
      final data = _createPnamesLump(['wall00']);

      final pnames = PatchNames.parse(data);

      expect(pnames[0], 'WALL00');
    });
  });

  group('TextureLump', () {
    test('parses single texture', () {
      final data = _createTextureLump([
        _TextureEntry('AASTINKY', 64, 128, []),
      ]);

      final lump = TextureLump.parse(data);

      expect(lump.length, 1);
      expect(lump[0].name, 'AASTINKY');
      expect(lump[0].width, 64);
      expect(lump[0].height, 128);
    });

    test('parses texture with patches', () {
      final data = _createTextureLump([
        _TextureEntry('BIGDOOR1', 128, 128, [
          _PatchEntry(0, 0, 0),
          _PatchEntry(64, 0, 1),
        ]),
      ]);

      final lump = TextureLump.parse(data);

      expect(lump[0].patches.length, 2);
      expect(lump[0].patches[0].originX, 0);
      expect(lump[0].patches[0].patchIndex, 0);
      expect(lump[0].patches[1].originX, 64);
      expect(lump[0].patches[1].patchIndex, 1);
    });

    test('parses multiple textures', () {
      final data = _createTextureLump([
        _TextureEntry('TEX1', 64, 64, []),
        _TextureEntry('TEX2', 128, 128, []),
        _TextureEntry('TEX3', 256, 128, []),
      ]);

      final lump = TextureLump.parse(data);

      expect(lump.length, 3);
      expect(lump[0].name, 'TEX1');
      expect(lump[1].name, 'TEX2');
      expect(lump[2].name, 'TEX3');
    });

    test('textures list is accessible', () {
      final data = _createTextureLump([
        _TextureEntry('TEST', 64, 64, []),
      ]);

      final lump = TextureLump.parse(data);

      expect(lump.textures.length, 1);
    });

    test('handles empty texture lump', () {
      final data = _createTextureLump([]);

      final lump = TextureLump.parse(data);

      expect(lump.length, 0);
    });
  });
}
