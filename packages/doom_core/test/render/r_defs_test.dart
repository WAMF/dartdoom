import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:test/test.dart';

void main() {
  group('RenderConstants', () {
    test('has correct maxVisplanes', () {
      expect(RenderConstants.maxVisplanes, 128);
    });

    test('has correct maxDrawSegs', () {
      expect(RenderConstants.maxDrawSegs, 256);
    });

    test('has correct maxVissprites', () {
      expect(RenderConstants.maxVissprites, 128);
    });

    test('has correct lightLevels', () {
      expect(RenderConstants.lightLevels, 16);
    });

    test('has correct maxLightScale', () {
      expect(RenderConstants.maxLightScale, 48);
    });

    test('has correct maxLightZ', () {
      expect(RenderConstants.maxLightZ, 128);
    });

    test('heightUnit is power of 2', () {
      expect(RenderConstants.heightUnit, 1 << RenderConstants.heightBits);
    });
  });

  group('SlopeType', () {
    test('has correct values', () {
      expect(SlopeType.horizontal, 0);
      expect(SlopeType.vertical, 1);
      expect(SlopeType.positive, 2);
      expect(SlopeType.negative, 3);
    });
  });

  group('Silhouette', () {
    test('has correct values', () {
      expect(Silhouette.none, 0);
      expect(Silhouette.bottom, 1);
      expect(Silhouette.top, 2);
      expect(Silhouette.both, 3);
    });

    test('both equals top | bottom', () {
      expect(Silhouette.both, Silhouette.top | Silhouette.bottom);
    });
  });

  group('BspConstants', () {
    test('subsectorFlag is correct', () {
      expect(BspConstants.subsectorFlag, 0x8000);
    });

    test('isSubsector returns true for subsector nodes', () {
      expect(BspConstants.isSubsector(0x8000), isTrue);
      expect(BspConstants.isSubsector(0x8001), isTrue);
      expect(BspConstants.isSubsector(0xFFFF), isTrue);
    });

    test('isSubsector returns false for regular nodes', () {
      expect(BspConstants.isSubsector(0), isFalse);
      expect(BspConstants.isSubsector(0x7FFF), isFalse);
      expect(BspConstants.isSubsector(100), isFalse);
    });

    test('getIndex strips subsector flag', () {
      expect(BspConstants.getIndex(0x8000), 0);
      expect(BspConstants.getIndex(0x8001), 1);
      expect(BspConstants.getIndex(0x80FF), 0xFF);
    });

    test('getIndex preserves regular node index', () {
      expect(BspConstants.getIndex(0), 0);
      expect(BspConstants.getIndex(100), 100);
      expect(BspConstants.getIndex(0x7FFF), 0x7FFF);
    });
  });

  group('Vertex', () {
    test('stores coordinates', () {
      final vertex = Vertex(100, 200);

      expect(vertex.x, 100);
      expect(vertex.y, 200);
    });

    test('coordinates are mutable', () {
      final vertex = Vertex(0, 0);
      vertex.x = 50;
      vertex.y = 75;

      expect(vertex.x, 50);
      expect(vertex.y, 75);
    });
  });

  group('Sector', () {
    test('stores all properties', () {
      final sector = Sector(
        index: 0,
        floorHeight: 0,
        ceilingHeight: 128,
        floorPic: 1,
        ceilingPic: 2,
        lightLevel: 160,
        special: 9,
        tag: 5,
      );

      expect(sector.index, 0);
      expect(sector.floorHeight, 0);
      expect(sector.ceilingHeight, 128);
      expect(sector.floorPic, 1);
      expect(sector.ceilingPic, 2);
      expect(sector.lightLevel, 160);
      expect(sector.special, 9);
      expect(sector.tag, 5);
    });

    test('has default runtime values', () {
      final sector = Sector(
        index: 0,
        floorHeight: 0,
        ceilingHeight: 128,
        floorPic: 0,
        ceilingPic: 0,
        lightLevel: 0,
        special: 0,
        tag: 0,
      );

      expect(sector.validCount, 0);
      expect(sector.lineCount, 0);
      expect(sector.lines, isEmpty);
    });
  });

  group('Side', () {
    test('stores all properties', () {
      final sector = Sector(
        index: 0,
        floorHeight: 0,
        ceilingHeight: 128,
        floorPic: 0,
        ceilingPic: 0,
        lightLevel: 0,
        special: 0,
        tag: 0,
      );

      final side = Side(
        textureOffset: 16,
        rowOffset: 32,
        topTexture: 1,
        bottomTexture: 2,
        midTexture: 3,
        sector: sector,
      );

      expect(side.textureOffset, 16);
      expect(side.rowOffset, 32);
      expect(side.topTexture, 1);
      expect(side.bottomTexture, 2);
      expect(side.midTexture, 3);
      expect(side.sector, sector);
    });
  });

  group('Line', () {
    test('stores all properties', () {
      final v1 = Vertex(0, 0);
      final v2 = Vertex(64, 0);
      final bbox = Int32List.fromList([0, 0, 64, 0]);

      final line = Line(
        v1: v1,
        v2: v2,
        dx: 64,
        dy: 0,
        flags: 1,
        special: 0,
        tag: 0,
        sideNum: [0, -1],
        slopeType: SlopeType.horizontal,
        bbox: bbox,
      );

      expect(line.v1, v1);
      expect(line.v2, v2);
      expect(line.dx, 64);
      expect(line.dy, 0);
      expect(line.flags, 1);
      expect(line.slopeType, SlopeType.horizontal);
    });

    test('optional sides default to null', () {
      final line = Line(
        v1: Vertex(0, 0),
        v2: Vertex(64, 0),
        dx: 64,
        dy: 0,
        flags: 0,
        special: 0,
        tag: 0,
        sideNum: [0, -1],
        slopeType: SlopeType.horizontal,
        bbox: Int32List(4),
      );

      expect(line.frontSide, isNull);
      expect(line.backSide, isNull);
      expect(line.frontSector, isNull);
      expect(line.backSector, isNull);
    });
  });

  group('ClipRange', () {
    test('stores first and last', () {
      final range = ClipRange(10, 50);

      expect(range.first, 10);
      expect(range.last, 50);
    });

    test('values are mutable', () {
      final range = ClipRange(0, 0);
      range.first = 5;
      range.last = 20;

      expect(range.first, 5);
      expect(range.last, 20);
    });
  });

  group('Visplane', () {
    test('initializes with correct dimensions', () {
      final plane = Visplane(
        height: 100,
        picNum: 5,
        lightLevel: 200,
      );

      expect(plane.height, 100);
      expect(plane.picNum, 5);
      expect(plane.lightLevel, 200);
      expect(plane.top.length, Visplane.screenWidth);
      expect(plane.bottom.length, Visplane.screenWidth);
    });

    test('initializes top array with 0xff', () {
      final plane = Visplane(
        height: 0,
        picNum: 0,
        lightLevel: 0,
      );

      for (var i = 0; i < Visplane.screenWidth; i++) {
        expect(plane.top[i], 0xff);
      }
    });

    test('initializes minX and maxX correctly', () {
      final plane = Visplane(
        height: 0,
        picNum: 0,
        lightLevel: 0,
      );

      expect(plane.minX, Visplane.screenWidth);
      expect(plane.maxX, -1);
    });
  });

  group('Vissprite', () {
    test('has default values', () {
      final sprite = Vissprite();

      expect(sprite.x1, 0);
      expect(sprite.x2, 0);
      expect(sprite.scale, 0);
      expect(sprite.colormap, isNull);
      expect(sprite.prev, isNull);
      expect(sprite.next, isNull);
    });

    test('can form linked list', () {
      final sprite1 = Vissprite();
      final sprite2 = Vissprite();
      final sprite3 = Vissprite();

      sprite1.next = sprite2;
      sprite2.prev = sprite1;
      sprite2.next = sprite3;
      sprite3.prev = sprite2;

      expect(sprite1.next, sprite2);
      expect(sprite2.prev, sprite1);
      expect(sprite2.next, sprite3);
      expect(sprite3.prev, sprite2);
    });
  });

  group('SpriteFrame', () {
    test('stores frame data', () {
      final frame = SpriteFrame(
        rotate: true,
        lump: Int32List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        flip: Uint8List.fromList([0, 1, 0, 1, 0, 1, 0, 1]),
      );

      expect(frame.rotate, isTrue);
      expect(frame.lump.length, 8);
      expect(frame.flip.length, 8);
    });
  });

  group('SpriteDef', () {
    test('stores sprite definition', () {
      final frames = [
        SpriteFrame(
          rotate: false,
          lump: Int32List.fromList([1]),
          flip: Uint8List.fromList([0]),
        ),
      ];

      final def = SpriteDef(
        numFrames: 1,
        spriteFrames: frames,
      );

      expect(def.numFrames, 1);
      expect(def.spriteFrames, frames);
    });
  });
}
