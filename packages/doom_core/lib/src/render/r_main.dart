import 'dart:typed_data';

import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_bsp.dart';
import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_plane.dart';
import 'package:doom_core/src/render/r_segs.dart';
import 'package:doom_core/src/render/r_sky.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/render/r_things.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _ViewConstants {
  static const int fineFieldOfView = Angle.fineAngles ~/ 4;
}

class Renderer {
  Renderer(this.state);

  final RenderState state;
  final DrawContext drawContext = DrawContext();

  Uint8List? _frameBuffer;

  late final BspTraversal _bsp;
  late final SegRenderer _segRenderer;
  late final PlaneRenderer _planeRenderer;
  late final SkyRenderer _skyRenderer;
  late final SpriteRenderer _spriteRenderer;

  void init() {
    _initBuffer();
    _initTables();
    drawContext.setLookups(state.yLookup, state.columnOfs, state.centerY, state.viewHeight);

    _skyRenderer = SkyRenderer(state, drawContext)
      ..init()
      ..onGetSkyTexture = _getSkyColumn;
    _planeRenderer = PlaneRenderer(state, drawContext)
      ..onDrawSky = _drawSky;
    _segRenderer = SegRenderer(state, this, drawContext)
      ..initClipArrays(state.viewWidth)
      ..onFloorPlane = _planeRenderer.setFloorPlane
      ..onCeilingPlane = _planeRenderer.setCeilingPlane
      ..onCheckFloorPlane = _planeRenderer.checkFloorPlane
      ..onCheckCeilingPlane = _planeRenderer.checkCeilingPlane;
    _spriteRenderer = SpriteRenderer(state, drawContext, _segRenderer)
      ..initClipArrays(state.viewWidth)
      ..onGetSpriteData = _getSpriteData
      ..onDrawMaskedColumn = _renderMaskedSegRange;
    _bsp = BspTraversal(state, this)
      ..onAddLine = _segRenderer.storeWallRange
      ..onEnterSubsector = _onEnterSubsector;
  }

  void _initTables() {
    _initProjection();
    _initViewAngleToX();
    _initXToViewAngle();
    _initClipAngle();
    _initLightTables();
  }

  void _initProjection() {
    const tanIndex = Angle.fineAngles ~/ 4 + _ViewConstants.fineFieldOfView ~/ 2;
    final focalLength = Fixed32.div(
      state.centerXFrac,
      fineTangent(tanIndex.clamp(0, Angle.fineAngles ~/ 2 - 1)),
    );
    state.projection = focalLength;
  }

  void _initClipAngle() {
    state.clipAngle = state.xToViewAngle[0];
  }

  void _initViewAngleToX() {
    final focalLength = state.projection;

    for (var i = 0; i < Angle.fineAngles ~/ 2; i++) {
      int t;
      if (fineTangent(i) > Fixed32.fracUnit * 2) {
        t = -1;
      } else if (fineTangent(i) < -Fixed32.fracUnit * 2) {
        t = state.viewWidth + 1;
      } else {
        t = Fixed32.toInt(
          state.centerXFrac -
              Fixed32.mul(fineTangent(i), focalLength) +
              Fixed32.fracUnit -
              1,
        );

        if (t < -1) {
          t = -1;
        } else if (t > state.viewWidth + 1) {
          t = state.viewWidth + 1;
        }
      }

      state.viewAngleToX[i] = t;
    }

    for (var i = 0; i < Angle.fineAngles ~/ 2; i++) {
      if (state.viewAngleToX[i] == -1) {
        state.viewAngleToX[i] = 0;
      } else if (state.viewAngleToX[i] == state.viewWidth + 1) {
        state.viewAngleToX[i] = state.viewWidth;
      }
    }

    for (var i = Angle.fineAngles ~/ 2;
        i < state.viewAngleToX.length;
        i++) {
      state.viewAngleToX[i] = 0;
    }
  }

  void _initXToViewAngle() {
    for (var x = 0; x <= state.viewWidth; x++) {
      var i = 0;
      while (state.viewAngleToX[i] > x) {
        i++;
      }

      state.xToViewAngle[x] =
          ((i << Angle.angleToFineShift) - Angle.ang90).u32.s32;
    }
  }

  void _initLightTables() {
    final scaleLightFixed = state.scaleLightFixed;
    for (var i = 0; i < RenderConstants.maxLightScale; i++) {
      scaleLightFixed[i] = null;
    }
  }

  void _initBuffer() {
    state.centerXFrac = state.centerX << Fixed32.fracBits;
    state.centerYFrac = state.centerY << Fixed32.fracBits;
    state.initBuffer();
  }

  void setupFrame(int viewX, int viewY, int viewZ, int viewAngle) {
    state
      ..viewX = viewX
      ..viewY = viewY
      ..viewZ = viewZ
      ..viewAngle = viewAngle;

    final fineAngle = (viewAngle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
    state.viewCos = fineCosine(fineAngle);
    state.viewSin = fineSine(fineAngle);

    state.frameCount++;
    state.validCount++;

    state.extraLight = 0;
    state.fixedColormap = null;
  }

  void renderPlayerView(Uint8List frameBuffer, {Player? player}) {
    _frameBuffer = frameBuffer;

    if (player != null) {
      state.extraLight = player.extraLight;
    }

    _planeRenderer.clearPlanes();
    _segRenderer
      ..clearDrawSegs()
      ..clearClips(state.viewHeight);
    _spriteRenderer.clearSprites();
    _bsp.clearClipSegs();

    if (state.nodes.isNotEmpty) {
      _bsp.renderBspNode(state.nodes.length - 1);
    }

    _planeRenderer
      ..onGetFlat = _getFlat
      ..drawPlanes(frameBuffer);

    _spriteRenderer.drawMasked(frameBuffer);

    if (player != null) {
      _spriteRenderer.drawPlayerSprites(player, frameBuffer);
    }
  }

  void _onEnterSubsector(Sector sector) {
    _planeRenderer.enterSubsector(sector);
    _spriteRenderer.addSprites(sector);
  }

  Uint8List? _getFlat(int flatNum) {
    final texManager = state.textureManager;
    if (texManager == null) return null;
    final translatedFlat = state.flatTranslation[flatNum];
    return texManager.getFlat(translatedFlat);
  }

  Uint8List? _getSpriteData(int patchNum) {
    final texManager = state.textureManager;
    if (texManager == null) return null;
    return texManager.getSpritePatch(patchNum);
  }

  void _drawSky(Visplane plane) {
    if (_frameBuffer == null) return;
    _skyRenderer.drawSky(plane, _frameBuffer!);
  }

  Uint8List? _getSkyColumn(int texture, int col) {
    final texManager = state.textureManager;
    if (texManager == null) return null;
    return texManager.getTextureColumn(texture, col);
  }

  void _renderMaskedSegRange(DrawSeg ds, int x1, int x2, Uint8List frameBuffer) {
    final seg = ds.curLine;
    final frontSector = seg.frontSector;
    final backSector = seg.backSector;
    if (backSector == null) return;

    final texManager = state.textureManager;
    if (texManager == null) return;

    final texNum = state.textureTranslation[seg.sidedef.midTexture];
    if (texNum <= 0) return;

    var lightNum = (frontSector.lightLevel >> RenderConstants.lightSegShift) + state.extraLight;
    if (seg.v1.y == seg.v2.y) {
      lightNum--;
    } else if (seg.v1.x == seg.v2.x) {
      lightNum++;
    }
    lightNum = lightNum.clamp(0, RenderConstants.lightLevels - 1);
    final wallLights = state.scaleLight[lightNum];

    int textureMid;
    if ((seg.linedef.flags & LineFlags.dontPegBottom) != 0) {
      final openBottom = frontSector.floorHeight > backSector.floorHeight
          ? frontSector.floorHeight
          : backSector.floorHeight;
      textureMid = openBottom + _getTextureHeight(texNum) - state.viewZ;
    } else {
      final openTop = frontSector.ceilingHeight < backSector.ceilingHeight
          ? frontSector.ceilingHeight
          : backSector.ceilingHeight;
      textureMid = openTop - state.viewZ;
    }
    textureMid += seg.sidedef.rowOffset;

    final maskedTextureCol = ds.maskedTextureCol;
    if (maskedTextureCol == null) return;

    final scalestep = ds.scaleStep;
    var spryscale = ds.scale1 + (x1 - ds.x1) * scalestep;

    final mfloorclip = ds.sprBottomClip;
    final mceilingclip = ds.sprTopClip;

    final column = drawContext.column;
    for (var x = x1; x <= x2; x++) {
      final colIndex = x - ds.x1;
      if (colIndex < 0 || colIndex >= maskedTextureCol.length) {
        spryscale += scalestep;
        continue;
      }

      final textureCol = maskedTextureCol[colIndex];
      if (textureCol == 0x7FFF) {
        spryscale += scalestep;
        continue;
      }

      final lightIndex = (spryscale >> RenderConstants.lightScaleShift)
          .clamp(0, RenderConstants.maxLightScale - 1);
      column.colormap = wallLights[lightIndex] ?? state.colormaps?.sublist(0, 256);

      final sprtopscreen = state.centerYFrac - Fixed32.mul(textureMid, spryscale);

      var clipTop = -1;
      var clipBot = state.viewHeight;
      if (mceilingclip != null && colIndex < mceilingclip.length) {
        clipTop = mceilingclip[colIndex];
      }
      if (mfloorclip != null && colIndex < mfloorclip.length) {
        clipBot = mfloorclip[colIndex];
      }

      final posts = texManager.getTextureColumnPosts(texNum, textureCol);
      for (final post in posts) {
        final topscreen = sprtopscreen + Fixed32.mul(post.topDelta.toFixed(), spryscale);
        final bottomscreen = topscreen + Fixed32.mul(post.pixels.length.toFixed(), spryscale);

        var yl = (topscreen + Fixed32.fracUnit - 1) >> Fixed32.fracBits;
        var yh = (bottomscreen - 1) >> Fixed32.fracBits;

        if (yl <= clipTop) yl = clipTop + 1;
        if (yh >= clipBot) yh = clipBot - 1;

        if (yl > yh) continue;

        column
          ..x = x
          ..yl = yl
          ..yh = yh
          ..iscale = Fixed32.div(Fixed32.fracUnit, spryscale)
          ..textureMid = textureMid - post.topDelta.toFixed()
          ..source = post.pixels;

        drawContext.drawColumn(frameBuffer);
      }

      maskedTextureCol[colIndex] = 0x7FFF;
      spryscale += scalestep;
    }
  }

  int _getTextureHeight(int textureNum) {
    final texManager = state.textureManager;
    if (texManager == null || textureNum <= 0) return 0;
    return texManager.getTextureHeight(textureNum) << Fixed32.fracBits;
  }

  int pointOnSide(int x, int y, Node node) {
    if (node.dx == 0) {
      if (x <= node.x) {
        return node.dy > 0 ? 1 : 0;
      }
      return node.dy < 0 ? 1 : 0;
    }

    if (node.dy == 0) {
      if (y <= node.y) {
        return node.dx < 0 ? 1 : 0;
      }
      return node.dx > 0 ? 1 : 0;
    }

    final dx = x - node.x;
    final dy = y - node.y;

    final left = Fixed32.mul(node.dy >> Fixed32.fracBits, dx);
    final right = Fixed32.mul(dy, node.dx >> Fixed32.fracBits);

    if (right < left) {
      return 0;
    }
    return 1;
  }

  int pointToAngleXY(int x, int y) {
    return pointToAngle(x - state.viewX, y - state.viewY);
  }

  int scaleFromGlobalAngle(int visAngle) {
    final viewAngle = state.viewAngle;
    final rwNormalAngle = state.rwNormalAngle;
    final rwDistance = state.rwDistance;
    final projection = state.projection;

    final anglea = (Angle.ang90 + visAngle - viewAngle).u32;
    final angleb = (Angle.ang90 + visAngle - rwNormalAngle).u32;

    final sinea = fineSine((anglea >> Angle.angleToFineShift) & Angle.fineMask).abs();
    final sineb = fineSine((angleb >> Angle.angleToFineShift) & Angle.fineMask).abs();

    final num = Fixed32.mul(projection, sineb) << state.detailShift;
    final den = Fixed32.mul(rwDistance, sinea);

    if (den > num >> 16) {
      final scale = Fixed32.div(num, den);
      if (scale > 64 * Fixed32.fracUnit) {
        return 64 * Fixed32.fracUnit;
      } else if (scale < 256) {
        return 256;
      }
      return scale;
    }
    return 64 * Fixed32.fracUnit;
  }

  int pointToDist(int x, int y) {
    var dx = (x - state.viewX).abs();
    var dy = (y - state.viewY).abs();

    if (dy > dx) {
      final temp = dx;
      dx = dy;
      dy = temp;
    }

    if (dx == 0) return 0;

    final slope = Fixed32.div(dy, dx) >> Angle.dBits;
    final clampedSlope = slope.clamp(0, Angle.slopeRange);
    final angle =
        ((tanToAngle(clampedSlope) + Angle.ang90).u32 >> Angle.angleToFineShift) &
            Angle.fineMask;

    final dist = Fixed32.div(dx, fineSine(angle));
    return dist;
  }

  Subsector pointInSubsector(int x, int y) {
    if (state.nodes.isEmpty) {
      return state.subsectors[0];
    }

    var nodeNum = state.nodes.length - 1;

    while (!BspConstants.isSubsector(nodeNum)) {
      final node = state.nodes[nodeNum];
      final side = pointOnSide(x, y, node);
      nodeNum = node.children[side];
    }

    return state.subsectors[BspConstants.getIndex(nodeNum)];
  }

  int angleToX(int angle) {
    final rawFineAngle = angle.u32 >> Angle.angleToFineShift;
    final fineAngle = rawFineAngle.clamp(0, Angle.fineAngles ~/ 2 - 1);
    final x = state.viewAngleToX[fineAngle];

    if (x < 0) {
      return 0;
    } else if (x > state.viewWidth) {
      return state.viewWidth;
    }
    return x;
  }

  int xToAngle(int x) {
    return state.xToViewAngle[x];
  }

  void setViewSize(int detail) {
    state.detailShift = detail;
    state.viewWidth = state.scaledViewWidth >> detail;

    if (detail == 0) {
      drawContext
        ..columnFunc = DrawerType.column
        ..baseColumnFunc = DrawerType.column
        ..spanFunc = DrawerType.span;
    } else {
      drawContext
        ..columnFunc = DrawerType.columnLow
        ..baseColumnFunc = DrawerType.columnLow
        ..spanFunc = DrawerType.spanLow;
    }

    _initBuffer();
    _initTables();
    drawContext.setLookups(state.yLookup, state.columnOfs, state.centerY, state.viewHeight);

    _segRenderer.initClipArrays(state.viewWidth);
    _spriteRenderer.initClipArrays(state.viewWidth);

    LightTableHelper.initScaleLight(state);
  }

  Uint8List? get frameBuffer => _frameBuffer;
  SpriteRenderer get spriteRenderer => _spriteRenderer;
}
