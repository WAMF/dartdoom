import 'dart:typed_data';

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
      ..firstFlat = _textureManager.firstFlat;

    _setupFlatTranslation(state);
    _setupTextureTranslation(state);

    return state;
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
        final level = startMap - j * ScreenDimensions.width ~/ (_ColormapConstants.viewDistance * RenderConstants.maxLightScale);
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
        final scale = Fixed32.div(ScreenDimensions.width.toFixed() ~/ 2, (j + 1) << RenderConstants.lightZShift);
        var level = startMap - Fixed32.toInt(scale) ~/ _ColormapConstants.distMap;
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
  static const int viewDistance = 160;
}
