import 'dart:typed_data';

import 'package:doom_core/src/game/game_info.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _SlopeConstants {
  static const int horizontal = 0;
  static const int vertical = 1;
  static const int positive = 2;
  static const int negative = 3;
}

abstract final class _BboxIndices {
  static const int top = 0;
  static const int bottom = 1;
  static const int left = 2;
  static const int right = 3;
}

class LevelLoader {
  LevelLoader(this._textureManager);

  final TextureManager _textureManager;

  List<Vertex> _vertices = [];
  List<Sector> _sectors = [];
  List<Side> _sides = [];
  List<Line> _lines = [];
  List<Seg> _segs = [];
  List<Subsector> _subsectors = [];
  List<Node> _nodes = [];

  RenderState loadLevel(MapData mapData) {
    _setupVertices(mapData.vertices);
    _setupSectors(mapData.sectors);
    _setupSides(mapData.sidedefs);
    _setupLines(mapData.linedefs);
    _setupSegs(mapData.segs);
    _setupSubsectors(mapData.subsectors);
    _setupNodes(mapData.nodes);
    _linkSectorLines();

    final state = RenderState()
      ..vertices = _vertices
      ..sectors = _sectors
      ..sides = _sides
      ..lines = _lines
      ..segs = _segs
      ..subsectors = _subsectors
      ..nodes = _nodes
      ..firstFlat = _textureManager.firstFlat
      ..textureManager = _textureManager;

    _setupFlatTranslation(state);
    _setupTextureTranslation(state);
    _setupSky(state);

    return state;
  }

  void _setupSky(RenderState state) {
    try {
      state.skyFlatNum = _textureManager.flatNumForName('F_SKY1');
    } catch (_) {
      state.skyFlatNum = 0;
    }

    final skyTextureNum = _textureManager.checkTextureNumForName('SKY1');
    state.skyTexture = skyTextureNum >= 0 ? skyTextureNum : 0;
  }

  void _setupVertices(List<MapVertex> mapVertices) {
    _vertices = List.generate(
      mapVertices.length,
      (i) => Vertex(mapVertices[i].x, mapVertices[i].y),
    );
  }

  void _setupSectors(List<MapSector> mapSectors) {
    _sectors = List.generate(
      mapSectors.length,
      (i) {
        final ms = mapSectors[i];
        return Sector(
          index: i,
          floorHeight: ms.floorHeight.toFixed().s32,
          ceilingHeight: ms.ceilingHeight.toFixed().s32,
          floorPic: _getFlatNum(ms.floorPic),
          ceilingPic: _getFlatNum(ms.ceilingPic),
          lightLevel: ms.lightLevel,
          special: ms.special,
          tag: ms.tag,
        );
      },
    );
  }

  void _setupSides(List<MapSidedef> mapSidedefs) {
    _sides = List.generate(
      mapSidedefs.length,
      (i) {
        final ms = mapSidedefs[i];
        return Side(
          textureOffset: ms.textureOffsetX.toFixed().s32,
          rowOffset: ms.textureOffsetY.toFixed().s32,
          topTexture: _getTextureNum(ms.topTexture),
          bottomTexture: _getTextureNum(ms.bottomTexture),
          midTexture: _getTextureNum(ms.midTexture),
          sector: _sectors[ms.sector],
        );
      },
    );
  }

  void _setupLines(List<MapLinedef> mapLinedefs) {
    _lines = List.generate(
      mapLinedefs.length,
      (i) {
        final ml = mapLinedefs[i];
        final v1 = _vertices[ml.v1];
        final v2 = _vertices[ml.v2];

        final dx = v2.x - v1.x;
        final dy = v2.y - v1.y;

        final slopeType = _calculateSlopeType(dx, dy);
        final bbox = _calculateBbox(v1, v2);

        final frontSide = ml.sidenum0 >= 0 ? _sides[ml.sidenum0] : null;
        final backSide = ml.sidenum1 >= 0 ? _sides[ml.sidenum1] : null;

        return Line(
          v1: v1,
          v2: v2,
          dx: dx,
          dy: dy,
          flags: ml.flags,
          special: ml.special,
          tag: ml.tag,
          sideNum: [ml.sidenum0, ml.sidenum1],
          frontSide: frontSide,
          backSide: backSide,
          frontSector: frontSide?.sector,
          backSector: backSide?.sector,
          slopeType: slopeType,
          bbox: bbox,
        );
      },
    );
  }

  void _setupSegs(List<MapSeg> mapSegs) {
    _segs = List.generate(
      mapSegs.length,
      (i) {
        final ms = mapSegs[i];
        final line = _lines[ms.linedef];
        final side = ms.side == 0 ? line.frontSide! : line.backSide!;

        final frontSector =
            ms.side == 0 ? line.frontSector! : line.backSector!;
        final backSector = ms.side == 0 ? line.backSector : line.frontSector;

        return Seg(
          v1: _vertices[ms.v1],
          v2: _vertices[ms.v2],
          offset: ms.offset.toFixed().s32,
          angle: _bamFromDoomAngle(ms.angle),
          sidedef: side,
          linedef: line,
          frontSector: frontSector,
          backSector: backSector,
        );
      },
    );
  }

  void _setupSubsectors(List<MapSubsector> mapSubsectors) {
    _subsectors = List.generate(
      mapSubsectors.length,
      (i) {
        final ms = mapSubsectors[i];
        final firstSeg = _segs[ms.firstSeg];

        return Subsector(
          sector: firstSeg.frontSector,
          numLines: ms.numSegs,
          firstLine: ms.firstSeg,
        );
      },
    );
  }

  void _setupNodes(List<MapNode> mapNodes) {
    _nodes = List.generate(
      mapNodes.length,
      (i) {
        final mn = mapNodes[i];
        return Node(
          x: mn.x.toFixed().s32,
          y: mn.y.toFixed().s32,
          dx: mn.dx.toFixed().s32,
          dy: mn.dy.toFixed().s32,
          bbox: [
            Int32List.fromList([
              mn.bbox0[_BboxIndices.top].toFixed().s32,
              mn.bbox0[_BboxIndices.bottom].toFixed().s32,
              mn.bbox0[_BboxIndices.left].toFixed().s32,
              mn.bbox0[_BboxIndices.right].toFixed().s32,
            ]),
            Int32List.fromList([
              mn.bbox1[_BboxIndices.top].toFixed().s32,
              mn.bbox1[_BboxIndices.bottom].toFixed().s32,
              mn.bbox1[_BboxIndices.left].toFixed().s32,
              mn.bbox1[_BboxIndices.right].toFixed().s32,
            ]),
          ],
          children: Int32List.fromList([mn.children0, mn.children1]),
        );
      },
    );
  }

  void _linkSectorLines() {
    for (final line in _lines) {
      if (line.frontSector != null) {
        line.frontSector!.lines.add(line);
        line.frontSector!.lineCount++;
      }
      if (line.backSector != null && line.backSector != line.frontSector) {
        line.backSector!.lines.add(line);
        line.backSector!.lineCount++;
      }
    }
  }

  void _setupFlatTranslation(RenderState state) {
    final numFlats = _textureManager.numFlats;
    state.flatTranslation = List.generate(numFlats, (i) => i);
  }

  void _setupTextureTranslation(RenderState state) {
    final numTextures = _textureManager.numTextures;
    state.textureTranslation = List.generate(numTextures, (i) => i);
  }

  int _calculateSlopeType(int dx, int dy) {
    if (dx == 0) {
      return _SlopeConstants.vertical;
    } else if (dy == 0) {
      return _SlopeConstants.horizontal;
    } else if (Fixed32.toInt(dy) ^ Fixed32.toInt(dx) >= 0) {
      return _SlopeConstants.positive;
    } else {
      return _SlopeConstants.negative;
    }
  }

  Int32List _calculateBbox(Vertex v1, Vertex v2) {
    final bbox = Int32List(4);

    if (v1.x < v2.x) {
      bbox[_BboxIndices.left] = v1.x;
      bbox[_BboxIndices.right] = v2.x;
    } else {
      bbox[_BboxIndices.left] = v2.x;
      bbox[_BboxIndices.right] = v1.x;
    }

    if (v1.y < v2.y) {
      bbox[_BboxIndices.bottom] = v1.y;
      bbox[_BboxIndices.top] = v2.y;
    } else {
      bbox[_BboxIndices.bottom] = v2.y;
      bbox[_BboxIndices.top] = v1.y;
    }

    return bbox;
  }

  int _bamFromDoomAngle(int doomAngle) {
    return (doomAngle << 16) & 0xFFFFFFFF;
  }

  int _getTextureNum(String name) {
    if (name.isEmpty || name.startsWith('-')) {
      return 0;
    }
    final num = _textureManager.checkTextureNumForName(name);
    return num >= 0 ? num : 0;
  }

  int _getFlatNum(String name) {
    if (name.isEmpty || name.startsWith('-')) {
      return 0;
    }
    try {
      return _textureManager.flatNumForName(name);
    } catch (_) {
      return 0;
    }
  }
}

class RenderData {
  RenderData(this._wadManager);

  final WadManager _wadManager;

  Uint8List? _colormaps;

  void initData(RenderState state) {
    _loadColormaps(state);
    _initLightTables(state);
    _initSprites(state);
  }

  void _initSprites(RenderState state) {
    state.firstSpriteLump = _wadManager.getNumForName('S_START') + 1;
    state.lastSpriteLump = _wadManager.getNumForName('S_END') - 1;
    state.numSpriteLumps = state.lastSpriteLump - state.firstSpriteLump + 1;

    state.spriteWidth = List.filled(state.numSpriteLumps, 0);
    state.spriteOffset = List.filled(state.numSpriteLumps, 0);
    state.spriteTopOffset = List.filled(state.numSpriteLumps, 0);

    for (var i = 0; i < state.numSpriteLumps; i++) {
      final patchData = _wadManager.cacheLumpNum(state.firstSpriteLump + i);
      if (patchData.length < 8) continue;

      final byteData = ByteData.sublistView(patchData);
      final width = byteData.getInt16(0, Endian.little);
      final leftOffset = byteData.getInt16(4, Endian.little);
      final topOffset = byteData.getInt16(6, Endian.little);

      state.spriteWidth[i] = width << Fixed32.fracBits;
      state.spriteOffset[i] = leftOffset << Fixed32.fracBits;
      state.spriteTopOffset[i] = topOffset << Fixed32.fracBits;
    }

    _initSpriteDefs(state);
  }

  void _initSpriteDefs(RenderState state) {
    state.sprites = [];

    for (var i = 0; i < spriteNames.length; i++) {
      final name = spriteNames[i];
      final frames = <int, _TempSpriteFrame>{};
      var maxFrame = -1;

      for (var lump = state.firstSpriteLump; lump <= state.lastSpriteLump; lump++) {
        final lumpName = _wadManager.getLumpInfo(lump).name.toUpperCase();
        if (!lumpName.startsWith(name)) continue;
        if (lumpName.length < 6) continue;

        final frameChar = lumpName.codeUnitAt(4) - 0x41;
        final rotationChar = lumpName.codeUnitAt(5) - 0x30;

        if (frameChar < 0 || frameChar > 28) continue;

        _installSpriteLump(
          frames,
          lump - state.firstSpriteLump,
          frameChar,
          rotationChar,
          false,
        );

        if (frameChar > maxFrame) maxFrame = frameChar;

        if (lumpName.length >= 8) {
          final frameChar2 = lumpName.codeUnitAt(6) - 0x41;
          final rotationChar2 = lumpName.codeUnitAt(7) - 0x30;
          if (frameChar2 >= 0 && frameChar2 <= 28) {
            _installSpriteLump(
              frames,
              lump - state.firstSpriteLump,
              frameChar2,
              rotationChar2,
              true,
            );
            if (frameChar2 > maxFrame) maxFrame = frameChar2;
          }
        }
      }

      if (maxFrame == -1) {
        state.sprites.add(SpriteDef(numFrames: 0, spriteFrames: []));
        continue;
      }

      final spriteFrames = <SpriteFrame>[];
      for (var f = 0; f <= maxFrame; f++) {
        final temp = frames[f];
        if (temp == null) {
          spriteFrames.add(SpriteFrame(
            rotate: false,
            lump: Int32List.fromList(List.filled(8, 0)),
            flip: Uint8List(8),
          ),);
        } else {
          spriteFrames.add(SpriteFrame(
            rotate: temp.rotate,
            lump: Int32List.fromList(temp.lump),
            flip: Uint8List.fromList(temp.flip),
          ),);
        }
      }

      state.sprites.add(SpriteDef(
        numFrames: maxFrame + 1,
        spriteFrames: spriteFrames,
      ),);
    }
  }

  void _installSpriteLump(
    Map<int, _TempSpriteFrame> frames,
    int lump,
    int frame,
    int rotation,
    bool flipped,
  ) {
    var temp = frames[frame];
    if (temp == null) {
      temp = _TempSpriteFrame()
        ..rotate = rotation != 0;
      frames[frame] = temp;
    }

    if (rotation == 0) {
      temp.rotate = false;
      for (var r = 0; r < 8; r++) {
        temp.lump[r] = lump;
        temp.flip[r] = flipped ? 1 : 0;
      }
    } else {
      temp.rotate = true;
      final r = rotation - 1;
      if (r >= 0 && r < 8) {
        temp.lump[r] = lump;
        temp.flip[r] = flipped ? 1 : 0;
      }
    }
  }

  void _loadColormaps(RenderState state) {
    _colormaps = _wadManager.cacheLumpName('COLORMAP');
    state.colormaps = _colormaps;
  }

  void _initLightTables(RenderState state) {
    if (_colormaps == null) return;

    for (var i = 0; i < RenderConstants.lightLevels; i++) {
      final startMap =
          ((RenderConstants.lightLevels - 1 - i) * 2) * _ColormapConstants.numColormaps ~/ RenderConstants.lightLevels;

      for (var j = 0; j < RenderConstants.maxLightScale; j++) {
        final scaledWidth = state.viewWidth << state.detailShift;
        final level = startMap - j * ScreenDimensions.width ~/ scaledWidth ~/ _ColormapConstants.distMap;
        final clampedLevel = level.clamp(0, _ColormapConstants.numColormaps - 1);

        state.scaleLight[i][j] = Uint8List.sublistView(
          _colormaps!,
          clampedLevel * _ColormapConstants.colormapSize,
          (clampedLevel + 1) * _ColormapConstants.colormapSize,
        );
      }
    }

    for (var i = 0; i < RenderConstants.lightLevels; i++) {
      final startMap =
          ((RenderConstants.lightLevels - 1 - i) * 2) * _ColormapConstants.numColormaps ~/ RenderConstants.lightLevels;

      for (var j = 0; j < RenderConstants.maxLightZ; j++) {
        var scale = Fixed32.div(ScreenDimensions.width.toFixed() ~/ 2, (j + 1) << RenderConstants.lightZShift);
        scale >>= RenderConstants.lightScaleShift;
        var level = startMap - scale ~/ _ColormapConstants.distMap;
        level = level.clamp(0, _ColormapConstants.numColormaps - 1);

        state.zLight[i][j] = Uint8List.sublistView(
          _colormaps!,
          level * _ColormapConstants.colormapSize,
          (level + 1) * _ColormapConstants.colormapSize,
        );
      }
    }
  }

  Uint8List getColormap(int lightLevel) {
    if (_colormaps == null) {
      return Uint8List(_ColormapConstants.colormapSize);
    }

    final index = lightLevel.clamp(0, _ColormapConstants.numColormaps - 1);
    return Uint8List.sublistView(
      _colormaps!,
      index * _ColormapConstants.colormapSize,
      (index + 1) * _ColormapConstants.colormapSize,
    );
  }

  Uint8List? get colormaps => _colormaps;
}

abstract final class _ColormapConstants {
  static const int colormapSize = 256;
  static const int numColormaps = 32;
  static const int distMap = 2;
}

class _TempSpriteFrame {
  bool rotate = false;
  List<int> lump = List.filled(8, -1);
  List<int> flip = List.filled(8, 0);
}
