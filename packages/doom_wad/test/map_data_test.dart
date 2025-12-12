import 'dart:typed_data';

import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

WadReader _createReader(List<int> bytes) {
  final data = ByteData(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    data.setUint8(i, bytes[i]);
  }
  return WadReader(data);
}

List<int> _int16Bytes(int value) {
  return [value & 0xFF, (value >> 8) & 0xFF];
}

void main() {
  group('MapVertex', () {
    test('parses vertex coordinates', () {
      final reader = _createReader([
        ..._int16Bytes(100),
        ..._int16Bytes(200),
      ]);

      final vertex = MapVertex.parse(reader);

      expect(Fixed32.toInt(vertex.x), 100);
      expect(Fixed32.toInt(vertex.y), 200);
    });

    test('handles negative coordinates', () {
      final reader = _createReader([
        ..._int16Bytes(-50),
        ..._int16Bytes(-100),
      ]);

      final vertex = MapVertex.parse(reader);

      expect(Fixed32.toInt(vertex.x), -50);
      expect(Fixed32.toInt(vertex.y), -100);
    });

    test('const constructor works', () {
      final vertex = MapVertex(100.toFixed(), 200.toFixed());

      expect(Fixed32.toInt(vertex.x), 100);
      expect(Fixed32.toInt(vertex.y), 200);
    });
  });

  group('MapLinedef', () {
    test('parses linedef data', () {
      final reader = _createReader([
        ..._int16Bytes(0),
        ..._int16Bytes(1),
        ..._int16Bytes(5),
        ..._int16Bytes(10),
        ..._int16Bytes(100),
        ..._int16Bytes(0),
        ..._int16Bytes(1),
      ]);

      final linedef = MapLinedef.parse(reader);

      expect(linedef.v1, 0);
      expect(linedef.v2, 1);
      expect(linedef.flags, 5);
      expect(linedef.special, 10);
      expect(linedef.tag, 100);
      expect(linedef.sidenum0, 0);
      expect(linedef.sidenum1, 1);
    });

    test('twoSided returns correct value', () {
      const oneSided = MapLinedef(
        v1: 0,
        v2: 1,
        flags: 0,
        special: 0,
        tag: 0,
        sidenum0: 0,
        sidenum1: -1,
      );

      const twoSided = MapLinedef(
        v1: 0,
        v2: 1,
        flags: 4,
        special: 0,
        tag: 0,
        sidenum0: 0,
        sidenum1: 1,
      );

      expect(oneSided.twoSided, isFalse);
      expect(twoSided.twoSided, isTrue);
    });
  });

  group('LineFlags', () {
    test('has correct flag values', () {
      expect(LineFlags.blocking, 1);
      expect(LineFlags.blockMonsters, 2);
      expect(LineFlags.twoSided, 4);
      expect(LineFlags.dontPegTop, 8);
      expect(LineFlags.dontPegBottom, 16);
      expect(LineFlags.secret, 32);
      expect(LineFlags.soundBlock, 64);
      expect(LineFlags.dontDraw, 128);
      expect(LineFlags.mapped, 256);
    });
  });

  group('MapSidedef', () {
    test('parses sidedef data', () {
      final reader = _createReader([
        ..._int16Bytes(10),
        ..._int16Bytes(20),
        ...List.filled(8, 0x2D),
        ...List.filled(8, 0x2D),
        ...'MIDTEX'.codeUnits,
        0,
        0,
        ..._int16Bytes(5),
      ]);

      final sidedef = MapSidedef.parse(reader);

      expect(sidedef.textureOffsetX, 10);
      expect(sidedef.textureOffsetY, 20);
      expect(sidedef.midTexture, 'MIDTEX');
      expect(sidedef.sector, 5);
    });

    test('const constructor works', () {
      const sidedef = MapSidedef(
        textureOffsetX: 0,
        textureOffsetY: 0,
        topTexture: 'TOP',
        bottomTexture: 'BOTTOM',
        midTexture: 'MID',
        sector: 0,
      );

      expect(sidedef.topTexture, 'TOP');
      expect(sidedef.bottomTexture, 'BOTTOM');
      expect(sidedef.midTexture, 'MID');
    });
  });

  group('MapSector', () {
    test('parses sector data', () {
      final reader = _createReader([
        ..._int16Bytes(0),
        ..._int16Bytes(128),
        ...'FLOOR'.codeUnits,
        0,
        0,
        0,
        ...'CEIL'.codeUnits,
        0,
        0,
        0,
        0,
        ..._int16Bytes(160),
        ..._int16Bytes(9),
        ..._int16Bytes(1),
      ]);

      final sector = MapSector.parse(reader);

      expect(sector.floorHeight, 0);
      expect(sector.ceilingHeight, 128);
      expect(sector.floorPic, 'FLOOR');
      expect(sector.ceilingPic, 'CEIL');
      expect(sector.lightLevel, 160);
      expect(sector.special, 9);
      expect(sector.tag, 1);
    });

    test('const constructor works', () {
      const sector = MapSector(
        floorHeight: 0,
        ceilingHeight: 128,
        floorPic: 'FLOOR',
        ceilingPic: 'CEIL',
        lightLevel: 255,
        special: 0,
        tag: 0,
      );

      expect(sector.floorHeight, 0);
      expect(sector.ceilingHeight, 128);
    });
  });

  group('MapThing', () {
    test('parses thing data', () {
      final reader = _createReader([
        ..._int16Bytes(100),
        ..._int16Bytes(200),
        ..._int16Bytes(90),
        ..._int16Bytes(1),
        ..._int16Bytes(7),
      ]);

      final thing = MapThing.parse(reader);

      expect(thing.x, 100);
      expect(thing.y, 200);
      expect(thing.angle, 90);
      expect(thing.type, 1);
      expect(thing.options, 7);
    });

    test('const constructor works', () {
      const thing = MapThing(
        x: 0,
        y: 0,
        angle: 0,
        type: 1,
        options: 7,
      );

      expect(thing.type, 1);
      expect(thing.options, 7);
    });
  });

  group('ThingOptions', () {
    test('has correct option values', () {
      expect(ThingOptions.easy, 1);
      expect(ThingOptions.medium, 2);
      expect(ThingOptions.hard, 4);
      expect(ThingOptions.ambush, 8);
      expect(ThingOptions.multiplayer, 16);
    });
  });

  group('MapSeg', () {
    test('parses seg data', () {
      final reader = _createReader([
        ..._int16Bytes(0),
        ..._int16Bytes(1),
        ..._int16Bytes(16384),
        ..._int16Bytes(5),
        ..._int16Bytes(0),
        ..._int16Bytes(32),
      ]);

      final seg = MapSeg.parse(reader);

      expect(seg.v1, 0);
      expect(seg.v2, 1);
      expect(seg.angle, 16384);
      expect(seg.linedef, 5);
      expect(seg.side, 0);
      expect(seg.offset, 32);
    });

    test('const constructor works', () {
      const seg = MapSeg(
        v1: 0,
        v2: 1,
        angle: 0,
        linedef: 0,
        side: 0,
        offset: 0,
      );

      expect(seg.v1, 0);
      expect(seg.v2, 1);
    });
  });

  group('MapSubsector', () {
    test('parses subsector data', () {
      final reader = _createReader([
        ..._int16Bytes(5),
        ..._int16Bytes(10),
      ]);

      final subsector = MapSubsector.parse(reader);

      expect(subsector.numSegs, 5);
      expect(subsector.firstSeg, 10);
    });

    test('const constructor works', () {
      const subsector = MapSubsector(numSegs: 3, firstSeg: 0);

      expect(subsector.numSegs, 3);
      expect(subsector.firstSeg, 0);
    });
  });

  group('MapNode', () {
    test('parses node data', () {
      final reader = _createReader([
        ..._int16Bytes(100),
        ..._int16Bytes(200),
        ..._int16Bytes(50),
        ..._int16Bytes(-50),
        ..._int16Bytes(0),
        ..._int16Bytes(100),
        ..._int16Bytes(0),
        ..._int16Bytes(100),
        ..._int16Bytes(100),
        ..._int16Bytes(200),
        ..._int16Bytes(100),
        ..._int16Bytes(200),
        ..._int16Bytes(0),
        ..._int16Bytes(32769),
      ]);

      final node = MapNode.parse(reader);

      expect(node.x, 100);
      expect(node.y, 200);
      expect(node.dx, 50);
      expect(node.dy, -50);
      expect(node.bbox0.length, 4);
      expect(node.bbox1.length, 4);
      expect(node.children0, 0);
      expect(node.children1, 32769);
    });

    test('const constructor works', () {
      const node = MapNode(
        x: 0,
        y: 0,
        dx: 1,
        dy: 0,
        bbox0: [0, 0, 100, 100],
        bbox1: [100, 0, 200, 100],
        children0: 0,
        children1: 1,
      );

      expect(node.dx, 1);
      expect(node.dy, 0);
    });
  });

  group('NodeChild', () {
    test('subsectorBit is correct', () {
      expect(NodeChild.subsectorBit, 0x8000);
    });

    test('isSubsector detects subsector flag', () {
      expect(NodeChild.isSubsector(0x8000), isTrue);
      expect(NodeChild.isSubsector(0x8001), isTrue);
      expect(NodeChild.isSubsector(0x7FFF), isFalse);
      expect(NodeChild.isSubsector(0), isFalse);
    });

    test('getIndex strips subsector bit', () {
      expect(NodeChild.getIndex(0x8000), 0);
      expect(NodeChild.getIndex(0x8001), 1);
      expect(NodeChild.getIndex(0x8FFF), 0x0FFF);
      expect(NodeChild.getIndex(0x7FFF), 0x7FFF);
    });
  });

  group('MapData', () {
    test('stores all map components', () {
      const mapData = MapData(
        vertices: [MapVertex(0, 0)],
        linedefs: [
          MapLinedef(
            v1: 0,
            v2: 0,
            flags: 0,
            special: 0,
            tag: 0,
            sidenum0: 0,
            sidenum1: -1,
          ),
        ],
        sidedefs: [
          MapSidedef(
            textureOffsetX: 0,
            textureOffsetY: 0,
            topTexture: '-',
            bottomTexture: '-',
            midTexture: 'STARTAN1',
            sector: 0,
          ),
        ],
        sectors: [
          MapSector(
            floorHeight: 0,
            ceilingHeight: 128,
            floorPic: 'FLOOR',
            ceilingPic: 'CEIL',
            lightLevel: 160,
            special: 0,
            tag: 0,
          ),
        ],
        things: [
          MapThing(x: 0, y: 0, angle: 0, type: 1, options: 7),
        ],
        segs: [
          MapSeg(
            v1: 0,
            v2: 0,
            angle: 0,
            linedef: 0,
            side: 0,
            offset: 0,
          ),
        ],
        subsectors: [MapSubsector(numSegs: 1, firstSeg: 0)],
        nodes: [
          MapNode(
            x: 0,
            y: 0,
            dx: 1,
            dy: 0,
            bbox0: [0, 0, 0, 0],
            bbox1: [0, 0, 0, 0],
            children0: 0,
            children1: 0,
          ),
        ],
      );

      expect(mapData.vertices.length, 1);
      expect(mapData.linedefs.length, 1);
      expect(mapData.sidedefs.length, 1);
      expect(mapData.sectors.length, 1);
      expect(mapData.things.length, 1);
      expect(mapData.segs.length, 1);
      expect(mapData.subsectors.length, 1);
      expect(mapData.nodes.length, 1);
      expect(mapData.blockmap, isNull);
      expect(mapData.reject, isNull);
    });

    test('can include blockmap and reject', () {
      final mapData = MapData(
        vertices: [],
        linedefs: [],
        sidedefs: [],
        sectors: [],
        things: [],
        segs: [],
        subsectors: [],
        nodes: [],
        blockmap: Uint8List.fromList([1, 2, 3]),
        reject: Uint8List.fromList([4, 5, 6]),
      );

      expect(mapData.blockmap, isNotNull);
      expect(mapData.reject, isNotNull);
    });
  });
}
