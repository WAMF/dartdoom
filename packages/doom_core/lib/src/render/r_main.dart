import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _ViewConstants {
  static const int fineFieldOfView = Angle.fineAngles ~/ 4;
  static const int clipAngle = Angle.ang45;
}

class Renderer {
  Renderer(this.state);

  final RenderState state;
  final DrawContext drawContext = DrawContext();

  Uint8List? _frameBuffer;

  void init() {
    _initBuffer();
    _initTables();
    drawContext.setLookups(state.yLookup, state.columnOfs);
  }

  void _initTables() {
    _initClipAngle();
    _initViewAngleToX();
    _initXToViewAngle();
    _initLightTables();
  }

  void _initClipAngle() {
    const tanIndex = Angle.fineAngles ~/ 4 + _ViewConstants.fineFieldOfView ~/ 2;
    final focalLength = Fixed32.div(
      state.centerXFrac,
      fineTangent(tanIndex.clamp(0, Angle.fineAngles ~/ 2 - 1)),
    );
    state.projection = focalLength;
    state.clipAngle = _ViewConstants.clipAngle;
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

    final fineAngle = (viewAngle >> Angle.angleToFineShift) & Angle.fineMask;
    state.viewCos = fineCosine(fineAngle);
    state.viewSin = fineSine(fineAngle);

    state.frameCount++;
    state.validCount++;

    state.extraLight = 0;
    state.fixedColormap = null;
  }

  void renderPlayerView(Uint8List frameBuffer) {
    _frameBuffer = frameBuffer;
    state.floorPlane = null;
    state.ceilingPlane = null;
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

  int pointToAngle(int x, int y) {
    final dx = x - state.viewX;
    final dy = y - state.viewY;

    if (dx == 0 && dy == 0) {
      return 0;
    }

    if (dx >= 0) {
      if (dy >= 0) {
        if (dx > dy) {
          return _tanToAngle(slopeDiv(dy, dx));
        } else {
          return Angle.ang90 - 1 - _tanToAngle(slopeDiv(dx, dy));
        }
      } else {
        final absDy = -dy;
        if (dx > absDy) {
          return -_tanToAngle(slopeDiv(absDy, dx));
        } else {
          return (Angle.ang270 + _tanToAngle(slopeDiv(dx, absDy))).u32.s32;
        }
      }
    } else {
      final absDx = -dx;
      if (dy >= 0) {
        if (absDx > dy) {
          return (Angle.ang180 - 1 - _tanToAngle(slopeDiv(dy, absDx))).u32.s32;
        } else {
          return Angle.ang90 + _tanToAngle(slopeDiv(absDx, dy));
        }
      } else {
        final absDy = -dy;
        if (absDx > absDy) {
          return (Angle.ang180 + _tanToAngle(slopeDiv(absDy, absDx))).u32.s32;
        } else {
          return (Angle.ang270 - 1 - _tanToAngle(slopeDiv(absDx, absDy))).u32.s32;
        }
      }
    }
  }

  int _tanToAngle(int slope) {
    return tanToAngle(slope.clamp(0, Angle.slopeRange));
  }

  int scaleFromGlobalAngle(int visAngle) {
    final viewAngle = state.viewAngle;
    final rwNormalAngle = state.rwNormalAngle;
    final rwDistance = state.rwDistance;
    final projection = state.projection;

    final anglea = (Angle.ang90 + visAngle - viewAngle).u32.s32;
    final angleb = (Angle.ang90 + visAngle - rwNormalAngle).u32.s32;

    final sinea = fineSine((anglea >> Angle.angleToFineShift) & Angle.fineMask);
    final sineb = fineSine((angleb >> Angle.angleToFineShift) & Angle.fineMask);

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
    final rawFineAngle =
        (angle + Angle.ang90).u32 >> Angle.angleToFineShift;
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

  Uint8List? get frameBuffer => _frameBuffer;
}
