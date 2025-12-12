import 'dart:typed_data';

abstract final class RenderConstants {
  static const int maxVisplanes = 128;
  static const int maxDrawSegs = 256;
  static const int maxVissprites = 128;
  static const int maxOpenings = 320 * 64;
  static const int maxSegs = 32;

  static const int lightLevels = 16;
  static const int lightSegShift = 4;
  static const int maxLightScale = 48;
  static const int lightScaleShift = 12;
  static const int maxLightZ = 128;
  static const int lightZShift = 20;

  static const int heightBits = 12;
  static const int heightUnit = 1 << heightBits;
}

abstract final class SlopeType {
  static const int horizontal = 0;
  static const int vertical = 1;
  static const int positive = 2;
  static const int negative = 3;
}

abstract final class Silhouette {
  static const int none = 0;
  static const int bottom = 1;
  static const int top = 2;
  static const int both = 3;
}

abstract final class BspConstants {
  static const int subsectorFlag = 0x8000;

  static bool isSubsector(int child) => (child & subsectorFlag) != 0;
  static int getIndex(int child) => child & ~subsectorFlag;
}

class Vertex {
  Vertex(this.x, this.y);

  int x;
  int y;
}

class Sector {
  Sector({
    required this.floorHeight,
    required this.ceilingHeight,
    required this.floorPic,
    required this.ceilingPic,
    required this.lightLevel,
    required this.special,
    required this.tag,
  });

  int floorHeight;
  int ceilingHeight;
  int floorPic;
  int ceilingPic;
  int lightLevel;
  int special;
  int tag;

  int validCount = 0;
  int lineCount = 0;
  List<Line> lines = [];

  int soundTraversed = 0;
  int blockBox0 = 0;
  int blockBox1 = 0;
  int blockBox2 = 0;
  int blockBox3 = 0;
}

class Side {
  Side({
    required this.textureOffset,
    required this.rowOffset,
    required this.topTexture,
    required this.bottomTexture,
    required this.midTexture,
    required this.sector,
  });

  int textureOffset;
  int rowOffset;
  int topTexture;
  int bottomTexture;
  int midTexture;
  Sector sector;
}

class Line {
  Line({
    required this.v1,
    required this.v2,
    required this.dx,
    required this.dy,
    required this.flags,
    required this.special,
    required this.tag,
    required this.sideNum,
    required this.slopeType,
    required this.bbox,
    this.frontSide,
    this.backSide,
    this.frontSector,
    this.backSector,
  });

  Vertex v1;
  Vertex v2;
  int dx;
  int dy;
  int flags;
  int special;
  int tag;
  List<int> sideNum;
  Side? frontSide;
  Side? backSide;
  Sector? frontSector;
  Sector? backSector;
  int slopeType;
  Int32List bbox;
  int validCount = 0;
}

class Seg {
  Seg({
    required this.v1,
    required this.v2,
    required this.offset,
    required this.angle,
    required this.sidedef,
    required this.linedef,
    required this.frontSector,
    this.backSector,
  });

  Vertex v1;
  Vertex v2;
  int offset;
  int angle;
  Side sidedef;
  Line linedef;
  Sector frontSector;
  Sector? backSector;
}

class Subsector {
  Subsector({
    required this.sector,
    required this.numLines,
    required this.firstLine,
  });

  Sector sector;
  int numLines;
  int firstLine;
}

class Node {
  Node({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.bbox,
    required this.children,
  });

  int x;
  int y;
  int dx;
  int dy;
  List<Int32List> bbox;
  Int32List children;
}

class ClipRange {
  ClipRange(this.first, this.last);

  int first;
  int last;
}

class DrawSeg {
  DrawSeg({
    required this.curLine,
    required this.x1,
    required this.x2,
    required this.scale1,
    required this.scale2,
    required this.scaleStep,
    required this.silhouette,
    required this.bsilHeight,
    required this.tsilHeight,
  });

  Seg curLine;
  int x1;
  int x2;
  int scale1;
  int scale2;
  int scaleStep;
  int silhouette;
  int bsilHeight;
  int tsilHeight;
  Int16List? sprTopClip;
  Int16List? sprBottomClip;
  Int16List? maskedTextureCol;
}

class Visplane {
  Visplane({
    required this.height,
    required this.picNum,
    required this.lightLevel,
  })  : top = Uint8List(screenWidth),
        bottom = Uint8List(screenWidth) {
    minX = screenWidth;
    maxX = -1;
    top.fillRange(0, screenWidth, 0xff);
  }

  static const int screenWidth = 320;

  int height;
  int picNum;
  int lightLevel;
  int minX = 0;
  int maxX = 0;
  final Uint8List top;
  final Uint8List bottom;
}

class Vissprite {
  int x1 = 0;
  int x2 = 0;
  int gx = 0;
  int gy = 0;
  int gz = 0;
  int gzt = 0;
  int startFrac = 0;
  int scale = 0;
  int xiscale = 0;
  int textureMid = 0;
  int patch = 0;
  Uint8List? colormap;
  int mobjFlags = 0;

  Vissprite? prev;
  Vissprite? next;
}

class SpriteFrame {
  SpriteFrame({
    required this.rotate,
    required this.lump,
    required this.flip,
  });

  bool rotate;
  Int32List lump;
  Uint8List flip;
}

class SpriteDef {
  SpriteDef({
    required this.numFrames,
    required this.spriteFrames,
  });

  int numFrames;
  List<SpriteFrame> spriteFrames;
}
