import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/video/frame_buffer.dart';

abstract final class ScreenDimensions {
  static const int width = FrameBuffer.width;
  static const int height = FrameBuffer.height;
  static const int centerX = width ~/ 2;
  static const int centerY = height ~/ 2;
}

class RenderState {
  List<Vertex> vertices = [];
  List<Seg> segs = [];
  List<Sector> sectors = [];
  List<Subsector> subsectors = [];
  List<Node> nodes = [];
  List<Line> lines = [];
  List<Side> sides = [];

  List<SpriteDef> sprites = [];
  int firstSpriteLump = 0;
  int lastSpriteLump = 0;
  int numSpriteLumps = 0;

  List<int> textureHeight = [];
  List<int> spriteWidth = [];
  List<int> spriteOffset = [];
  List<int> spriteTopOffset = [];

  int firstFlat = 0;
  List<int> flatTranslation = [];
  List<int> textureTranslation = [];

  Uint8List? colormaps;

  int viewX = 0;
  int viewY = 0;
  int viewZ = 0;
  int viewAngle = 0;
  int viewCos = 0;
  int viewSin = 0;

  int centerX = ScreenDimensions.centerX;
  int centerY = ScreenDimensions.centerY;
  int centerXFrac = 0;
  int centerYFrac = 0;
  int projection = 0;

  Int32List viewAngleToX = Int32List(4096);
  Int32List xToViewAngle = Int32List(ScreenDimensions.width + 1);
  int clipAngle = 0;

  int validCount = 0;
  int frameCount = 0;

  int extraLight = 0;
  Uint8List? fixedColormap;

  int viewWidth = ScreenDimensions.width;
  int viewHeight = ScreenDimensions.height;
  int scaledViewWidth = ScreenDimensions.width;
  int viewWindowX = 0;
  int viewWindowY = 0;

  int detailShift = 0;

  Int32List yLookup = Int32List(ScreenDimensions.height);
  Int32List columnOfs = Int32List(ScreenDimensions.width);

  int rwDistance = 0;
  int rwNormalAngle = 0;
  int rwAngle1 = 0;

  Visplane? floorPlane;
  Visplane? ceilingPlane;

  List<List<Uint8List?>> scaleLight = List.generate(
    RenderConstants.lightLevels,
    (_) => List<Uint8List?>.filled(RenderConstants.maxLightScale, null),
  );

  List<Uint8List?> scaleLightFixed =
      List<Uint8List?>.filled(RenderConstants.maxLightScale, null);

  List<List<Uint8List?>> zLight = List.generate(
    RenderConstants.lightLevels,
    (_) => List<Uint8List?>.filled(RenderConstants.maxLightZ, null),
  );

  int skyFlatNum = 0;
  int skyTexture = 0;
  int skyColumnOffset = 0;

  void initBuffer() {
    for (var i = 0; i < viewHeight; i++) {
      yLookup[i] = (i + viewWindowY) * ScreenDimensions.width;
    }
    for (var i = 0; i < viewWidth; i++) {
      columnOfs[i] = viewWindowX + i;
    }
  }
}
