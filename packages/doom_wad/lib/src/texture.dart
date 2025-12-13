import 'dart:typed_data';

import 'package:doom_wad/src/patch.dart';
import 'package:doom_wad/src/wad_file.dart';

abstract final class _TextureConstants {
  static const int patchNameLength = 8;
  static const int textureNameLength = 8;
}

class TexturePatch {
  const TexturePatch({
    required this.originX,
    required this.originY,
    required this.patchIndex,
  });

  final int originX;
  final int originY;
  final int patchIndex;
}

class TextureDef {
  const TextureDef({
    required this.name,
    required this.width,
    required this.height,
    required this.patches,
  });

  final String name;
  final int width;
  final int height;
  final List<TexturePatch> patches;
}

class PatchNames {
  PatchNames(this.names);

  factory PatchNames.parse(Uint8List data) {
    final reader = WadReader(ByteData.sublistView(data));
    final count = reader.readInt32();

    final names = <String>[];
    for (var i = 0; i < count; i++) {
      names.add(reader.readString(_TextureConstants.patchNameLength));
    }

    return PatchNames(names);
  }

  final List<String> names;

  int get length => names.length;
  String operator [](int index) => names[index];
}

class TextureLump {
  TextureLump(this.textures);

  factory TextureLump.parse(Uint8List data) {
    final byteData = ByteData.sublistView(data);
    final numTextures = byteData.getInt32(0, Endian.little);

    final offsets = <int>[];
    for (var i = 0; i < numTextures; i++) {
      offsets.add(byteData.getInt32(4 + i * 4, Endian.little));
    }

    final textures = <TextureDef>[];
    for (final offset in offsets) {
      final reader = WadReader(byteData)..position = offset;

      final name = reader.readString(_TextureConstants.textureNameLength);
      reader.skip(4);
      final width = reader.readInt16();
      final height = reader.readInt16();
      reader.skip(4);
      final patchCount = reader.readInt16();

      final patches = <TexturePatch>[];
      for (var j = 0; j < patchCount; j++) {
        final originX = reader.readInt16();
        final originY = reader.readInt16();
        final patchIndex = reader.readInt16();
        reader.skip(4);

        patches.add(
          TexturePatch(
            originX: originX,
            originY: originY,
            patchIndex: patchIndex,
          ),
        );
      }

      textures.add(
        TextureDef(
          name: name,
          width: width,
          height: height,
          patches: patches,
        ),
      );
    }

    return TextureLump(textures);
  }

  final List<TextureDef> textures;

  int get length => textures.length;
  TextureDef operator [](int index) => textures[index];
}

class TextureManager {
  TextureManager(this._wadManager);

  final WadManager _wadManager;
  PatchNames? _patchNames;
  final List<TextureDef> _textures = [];
  final Map<String, int> _textureIndex = {};
  final Map<int, Uint8List> _compositeCache = {};

  int _firstFlat = -1;
  int _lastFlat = -1;
  int _firstSprite = -1;
  int _lastSprite = -1;

  int get numTextures => _textures.length;
  int get numFlats => _lastFlat >= _firstFlat ? _lastFlat - _firstFlat + 1 : 0;
  int get firstFlat => _firstFlat;
  int get lastFlat => _lastFlat;
  int get firstSprite => _firstSprite;
  int get lastSprite => _lastSprite;

  void init() {
    _loadPatchNames();
    _loadTextures();
    _findFlatRange();
    _findSpriteRange();
  }

  void _loadPatchNames() {
    final data = _wadManager.cacheLumpName('PNAMES');
    _patchNames = PatchNames.parse(data);
  }

  void _loadTextures() {
    _textures.clear();
    _textureIndex.clear();

    final texture1Data = _wadManager.cacheLumpName('TEXTURE1');
    final texture1 = TextureLump.parse(texture1Data);
    for (final tex in texture1.textures) {
      _textureIndex[tex.name] = _textures.length;
      _textures.add(tex);
    }

    final texture2Index = _wadManager.checkNumForName('TEXTURE2');
    if (texture2Index != -1) {
      final texture2Data = _wadManager.readLump(texture2Index);
      final texture2 = TextureLump.parse(texture2Data);
      for (final tex in texture2.textures) {
        _textureIndex[tex.name] = _textures.length;
        _textures.add(tex);
      }
    }
  }

  void _findFlatRange() {
    _firstFlat = _wadManager.getNumForName('F_START') + 1;
    _lastFlat = _wadManager.getNumForName('F_END') - 1;
  }

  void _findSpriteRange() {
    _firstSprite = _wadManager.getNumForName('S_START') + 1;
    _lastSprite = _wadManager.getNumForName('S_END') - 1;
  }

  int checkTextureNumForName(String name) {
    if (name.isEmpty || name.startsWith('-')) {
      return 0;
    }

    final upperName = name.toUpperCase();
    return _textureIndex[upperName] ?? -1;
  }

  int getTextureNumForName(String name) {
    final num = checkTextureNumForName(name);
    if (num == -1) {
      throw ArgumentError('R_TextureNumForName: $name not found');
    }
    return num;
  }

  TextureDef getTextureDef(int textureNum) {
    if (textureNum < 0 || textureNum >= _textures.length) {
      throw RangeError.index(textureNum, _textures, 'textureNum');
    }
    return _textures[textureNum];
  }

  int flatNumForName(String name) {
    final lumpNum = _wadManager.checkNumForName(name);
    if (lumpNum == -1) {
      throw ArgumentError('R_FlatNumForName: $name not found');
    }
    return lumpNum - _firstFlat;
  }

  Uint8List getFlat(int flatNum) {
    return _wadManager.cacheLumpNum(_firstFlat + flatNum);
  }

  Uint8List getFlatByName(String name) {
    return getFlat(flatNumForName(name));
  }

  Uint8List getSpritePatch(int patchNum) {
    return _wadManager.cacheLumpNum(_firstSprite + patchNum);
  }

  int get firstSpriteLump => _firstSprite;
  int get lastSpriteLump => _lastSprite;

  Uint8List generateComposite(int textureNum) {
    if (_compositeCache.containsKey(textureNum)) {
      return _compositeCache[textureNum]!;
    }

    final texDef = getTextureDef(textureNum);
    final composite = Uint8List(texDef.width * texDef.height);

    for (final patchDef in texDef.patches) {
      final patchName = _patchNames![patchDef.patchIndex];
      final patchLump = _wadManager.checkNumForName(patchName);
      if (patchLump == -1) continue;

      final patchData = _wadManager.cacheLumpNum(patchLump);
      final patch = Patch.parse(patchData);

      _drawPatchToComposite(
        composite,
        texDef.width,
        texDef.height,
        patch,
        patchDef.originX,
        patchDef.originY,
      );
    }

    _compositeCache[textureNum] = composite;
    return composite;
  }

  void _drawPatchToComposite(
    Uint8List composite,
    int texWidth,
    int texHeight,
    Patch patch,
    int originX,
    int originY,
  ) {
    for (var col = 0; col < patch.width; col++) {
      final destX = originX + col;
      if (destX < 0 || destX >= texWidth) continue;

      for (final post in patch.columns[col]) {
        var destY = originY + post.topDelta;
        for (final pixel in post.pixels) {
          if (destY >= 0 && destY < texHeight) {
            composite[destY * texWidth + destX] = pixel;
          }
          destY++;
        }
      }
    }
  }

  List<String> get patchNames => _patchNames?.names ?? [];
  List<TextureDef> get textures => List.unmodifiable(_textures);

  Uint8List getTextureColumn(int textureNum, int col) {
    if (textureNum < 0 || textureNum >= _textures.length) {
      return _emptyColumn;
    }

    final texDef = _textures[textureNum];
    final wrappedCol = col & (texDef.width - 1);

    final composite = generateComposite(textureNum);
    final column = Uint8List(texDef.height);

    for (var y = 0; y < texDef.height; y++) {
      column[y] = composite[y * texDef.width + wrappedCol];
    }

    return column;
  }

  int getTextureHeight(int textureNum) {
    if (textureNum < 0 || textureNum >= _textures.length) {
      return 128;
    }
    return _textures[textureNum].height;
  }

  int getTextureWidth(int textureNum) {
    if (textureNum < 0 || textureNum >= _textures.length) {
      return 64;
    }
    return _textures[textureNum].width;
  }

  void clearCache() {
    _compositeCache.clear();
  }

  List<PatchColumn> getTextureColumnPosts(int textureNum, int col) {
    if (textureNum < 0 || textureNum >= _textures.length) {
      return const [];
    }

    final texDef = _textures[textureNum];
    final wrappedCol = col % texDef.width;
    if (wrappedCol < 0) return const [];

    if (texDef.patches.length == 1) {
      final patchDef = texDef.patches[0];
      final patchName = _patchNames![patchDef.patchIndex];
      final patchLump = _wadManager.checkNumForName(patchName);
      if (patchLump == -1) return const [];

      final patchData = _wadManager.cacheLumpNum(patchLump);
      final patch = Patch.parse(patchData);

      final patchCol = wrappedCol - patchDef.originX;
      if (patchCol < 0 || patchCol >= patch.width) return const [];

      final posts = patch.columns[patchCol];
      if (patchDef.originY == 0) {
        return posts;
      }

      return posts.map((post) {
        return PatchColumn(
          topDelta: post.topDelta + patchDef.originY,
          pixels: post.pixels,
        );
      }).toList();
    }

    final column = getTextureColumn(textureNum, col);
    return [
      PatchColumn(
        topDelta: 0,
        pixels: column,
      ),
    ];
  }

  static final Uint8List _emptyColumn = Uint8List(128);
}
