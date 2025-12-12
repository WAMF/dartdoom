import 'dart:typed_data';

import 'package:doom_math/doom_math.dart';

import 'package:doom_wad/src/wad_file.dart';

class MapVertex {

  const MapVertex(this.x, this.y);

  factory MapVertex.parse(WadReader reader) {
    return MapVertex(
      reader.readInt16().toFixed(),
      reader.readInt16().toFixed(),
    );
  }
  final int x;
  final int y;
}

class MapLinedef {

  const MapLinedef({
    required this.v1,
    required this.v2,
    required this.flags,
    required this.special,
    required this.tag,
    required this.sidenum0,
    required this.sidenum1,
  });

  factory MapLinedef.parse(WadReader reader) {
    return MapLinedef(
      v1: reader.readUint16(),
      v2: reader.readUint16(),
      flags: reader.readInt16(),
      special: reader.readInt16(),
      tag: reader.readInt16(),
      sidenum0: reader.readInt16(),
      sidenum1: reader.readInt16(),
    );
  }
  final int v1;
  final int v2;
  final int flags;
  final int special;
  final int tag;
  final int sidenum0;
  final int sidenum1;

  bool get twoSided => sidenum1 != -1;
}

abstract final class LineFlags {
  static const int blocking = 1;
  static const int blockMonsters = 2;
  static const int twoSided = 4;
  static const int dontPegTop = 8;
  static const int dontPegBottom = 16;
  static const int secret = 32;
  static const int soundBlock = 64;
  static const int dontDraw = 128;
  static const int mapped = 256;
}

class MapSidedef {

  const MapSidedef({
    required this.textureOffsetX,
    required this.textureOffsetY,
    required this.topTexture,
    required this.bottomTexture,
    required this.midTexture,
    required this.sector,
  });

  factory MapSidedef.parse(WadReader reader) {
    return MapSidedef(
      textureOffsetX: reader.readInt16(),
      textureOffsetY: reader.readInt16(),
      topTexture: reader.readString(8),
      bottomTexture: reader.readString(8),
      midTexture: reader.readString(8),
      sector: reader.readInt16(),
    );
  }
  final int textureOffsetX;
  final int textureOffsetY;
  final String topTexture;
  final String bottomTexture;
  final String midTexture;
  final int sector;
}

class MapSector {

  const MapSector({
    required this.floorHeight,
    required this.ceilingHeight,
    required this.floorPic,
    required this.ceilingPic,
    required this.lightLevel,
    required this.special,
    required this.tag,
  });

  factory MapSector.parse(WadReader reader) {
    return MapSector(
      floorHeight: reader.readInt16(),
      ceilingHeight: reader.readInt16(),
      floorPic: reader.readString(8),
      ceilingPic: reader.readString(8),
      lightLevel: reader.readInt16(),
      special: reader.readInt16(),
      tag: reader.readInt16(),
    );
  }
  final int floorHeight;
  final int ceilingHeight;
  final String floorPic;
  final String ceilingPic;
  final int lightLevel;
  final int special;
  final int tag;
}

class MapThing {

  const MapThing({
    required this.x,
    required this.y,
    required this.angle,
    required this.type,
    required this.options,
  });

  factory MapThing.parse(WadReader reader) {
    return MapThing(
      x: reader.readInt16(),
      y: reader.readInt16(),
      angle: reader.readInt16(),
      type: reader.readInt16(),
      options: reader.readInt16(),
    );
  }
  final int x;
  final int y;
  final int angle;
  final int type;
  final int options;
}

abstract final class ThingOptions {
  static const int easy = 1;
  static const int medium = 2;
  static const int hard = 4;
  static const int ambush = 8;
  static const int multiplayer = 16;
}

class MapSeg {

  const MapSeg({
    required this.v1,
    required this.v2,
    required this.angle,
    required this.linedef,
    required this.side,
    required this.offset,
  });

  factory MapSeg.parse(WadReader reader) {
    return MapSeg(
      v1: reader.readInt16(),
      v2: reader.readInt16(),
      angle: reader.readInt16(),
      linedef: reader.readInt16(),
      side: reader.readInt16(),
      offset: reader.readInt16(),
    );
  }
  final int v1;
  final int v2;
  final int angle;
  final int linedef;
  final int side;
  final int offset;
}

class MapSubsector {

  const MapSubsector({
    required this.numSegs,
    required this.firstSeg,
  });

  factory MapSubsector.parse(WadReader reader) {
    return MapSubsector(
      numSegs: reader.readInt16(),
      firstSeg: reader.readInt16(),
    );
  }
  final int numSegs;
  final int firstSeg;
}

class MapNode {

  const MapNode({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.bbox0,
    required this.bbox1,
    required this.children0,
    required this.children1,
  });

  factory MapNode.parse(WadReader reader) {
    final x = reader.readInt16();
    final y = reader.readInt16();
    final dx = reader.readInt16();
    final dy = reader.readInt16();

    final bbox0 = <int>[
      reader.readInt16(),
      reader.readInt16(),
      reader.readInt16(),
      reader.readInt16(),
    ];

    final bbox1 = <int>[
      reader.readInt16(),
      reader.readInt16(),
      reader.readInt16(),
      reader.readInt16(),
    ];

    final children0 = reader.readUint16();
    final children1 = reader.readUint16();

    return MapNode(
      x: x,
      y: y,
      dx: dx,
      dy: dy,
      bbox0: bbox0,
      bbox1: bbox1,
      children0: children0,
      children1: children1,
    );
  }
  final int x;
  final int y;
  final int dx;
  final int dy;
  final List<int> bbox0;
  final List<int> bbox1;
  final int children0;
  final int children1;
}

abstract final class NodeChild {
  static const int subsectorBit = 0x8000;

  static bool isSubsector(int child) => (child & subsectorBit) != 0;
  static int getIndex(int child) => child & ~subsectorBit;
}

class MapData {

  const MapData({
    required this.vertices,
    required this.linedefs,
    required this.sidedefs,
    required this.sectors,
    required this.things,
    required this.segs,
    required this.subsectors,
    required this.nodes,
    this.blockmap,
    this.reject,
  });
  final List<MapVertex> vertices;
  final List<MapLinedef> linedefs;
  final List<MapSidedef> sidedefs;
  final List<MapSector> sectors;
  final List<MapThing> things;
  final List<MapSeg> segs;
  final List<MapSubsector> subsectors;
  final List<MapNode> nodes;
  final Uint8List? blockmap;
  final Uint8List? reject;
}

class MapLoader {

  MapLoader(this.wadManager);
  final WadManager wadManager;

  MapData loadMap(String mapName) {
    final mapIndex = wadManager.getNumForName(mapName);

    return MapData(
      things: _loadThings(mapIndex + 1),
      linedefs: _loadLinedefs(mapIndex + 2),
      sidedefs: _loadSidedefs(mapIndex + 3),
      vertices: _loadVertices(mapIndex + 4),
      segs: _loadSegs(mapIndex + 5),
      subsectors: _loadSubsectors(mapIndex + 6),
      nodes: _loadNodes(mapIndex + 7),
      sectors: _loadSectors(mapIndex + 8),
      reject: _tryLoadLump(mapIndex + 9),
      blockmap: _tryLoadLump(mapIndex + 10),
    );
  }

  List<MapThing> _loadThings(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 10;

    return List.generate(count, (_) => MapThing.parse(reader));
  }

  List<MapLinedef> _loadLinedefs(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 14;

    return List.generate(count, (_) => MapLinedef.parse(reader));
  }

  List<MapSidedef> _loadSidedefs(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 30;

    return List.generate(count, (_) => MapSidedef.parse(reader));
  }

  List<MapVertex> _loadVertices(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 4;

    return List.generate(count, (_) => MapVertex.parse(reader));
  }

  List<MapSeg> _loadSegs(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 12;

    return List.generate(count, (_) => MapSeg.parse(reader));
  }

  List<MapSubsector> _loadSubsectors(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 4;

    return List.generate(count, (_) => MapSubsector.parse(reader));
  }

  List<MapNode> _loadNodes(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 28;

    return List.generate(count, (_) => MapNode.parse(reader));
  }

  List<MapSector> _loadSectors(int lump) {
    final data = wadManager.readLump(lump);
    final reader = WadReader(ByteData.sublistView(data));
    final count = data.length ~/ 26;

    return List.generate(count, (_) => MapSector.parse(reader));
  }

  Uint8List? _tryLoadLump(int lump) {
    try {
      return wadManager.readLump(lump);
    } catch (_) {
      return null;
    }
  }
}
