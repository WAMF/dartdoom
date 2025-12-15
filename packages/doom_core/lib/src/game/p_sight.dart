import 'dart:typed_data';

import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

class _Divline {
  int x = 0;
  int y = 0;
  int dx = 0;
  int dy = 0;
}

class _SightContext {
  int sightZStart = 0;
  int topSlope = 0;
  int bottomSlope = 0;
  int t2x = 0;
  int t2y = 0;
  final _Divline strace = _Divline();
  int validCount = 0;
}

int _divlineSide(int x, int y, _Divline node) {
  if (node.dx == 0) {
    if (x == node.x) return 2;
    if (x <= node.x) return node.dy > 0 ? 1 : 0;
    return node.dy < 0 ? 1 : 0;
  }

  if (node.dy == 0) {
    if (y == node.y) return 2;
    if (y <= node.y) return node.dx < 0 ? 1 : 0;
    return node.dx > 0 ? 1 : 0;
  }

  final dx = x - node.x;
  final dy = y - node.y;

  final left = (node.dy >> Fixed32.fracBits) * (dx >> Fixed32.fracBits);
  final right = (dy >> Fixed32.fracBits) * (node.dx >> Fixed32.fracBits);

  if (right < left) return 0;
  if (left == right) return 2;
  return 1;
}

int _nodeDivlineSide(int x, int y, Node node) {
  if (node.dx == 0) {
    if (x == node.x) return 2;
    if (x <= node.x) return node.dy > 0 ? 1 : 0;
    return node.dy < 0 ? 1 : 0;
  }

  if (node.dy == 0) {
    if (y == node.y) return 2;
    if (y <= node.y) return node.dx < 0 ? 1 : 0;
    return node.dx > 0 ? 1 : 0;
  }

  final dx = x - node.x;
  final dy = y - node.y;

  final left = (node.dy >> Fixed32.fracBits) * (dx >> Fixed32.fracBits);
  final right = (dy >> Fixed32.fracBits) * (node.dx >> Fixed32.fracBits);

  if (right < left) return 0;
  if (left == right) return 2;
  return 1;
}

int _interceptVector2(_Divline v2, _Divline v1) {
  final den = Fixed32.mul(v1.dy >> 8, v2.dx) - Fixed32.mul(v1.dx >> 8, v2.dy);

  if (den == 0) return 0;

  final num = Fixed32.mul((v1.x - v2.x) >> 8, v1.dy) +
      Fixed32.mul((v2.y - v1.y) >> 8, v1.dx);

  return Fixed32.div(num, den);
}

bool _crossSubsector(
  int num,
  RenderState state,
  _SightContext ctx,
) {
  if (num < 0 || num >= state.subsectors.length) {
    return true;
  }

  final sub = state.subsectors[num];
  final segs = state.segs;
  final firstLine = sub.firstLine;
  final numLines = sub.numLines;

  for (var i = 0; i < numLines; i++) {
    final segIndex = firstLine + i;
    if (segIndex >= segs.length) continue;

    final seg = segs[segIndex];
    final line = seg.linedef;

    if (line.validCount == ctx.validCount) continue;
    line.validCount = ctx.validCount;

    final v1 = line.v1;
    final v2 = line.v2;

    var s1 = _divlineSide(v1.x, v1.y, ctx.strace);
    var s2 = _divlineSide(v2.x, v2.y, ctx.strace);

    if (s1 == s2) continue;

    final divl = _Divline()
      ..x = v1.x
      ..y = v1.y
      ..dx = v2.x - v1.x
      ..dy = v2.y - v1.y;

    s1 = _divlineSide(ctx.strace.x, ctx.strace.y, divl);
    s2 = _divlineSide(ctx.t2x, ctx.t2y, divl);

    if (s1 == s2) continue;

    if ((line.flags & LineFlags.twoSided) == 0) {
      return false;
    }

    final front = seg.frontSector;
    final back = seg.backSector;
    if (back == null) {
      return false;
    }

    if (front.floorHeight == back.floorHeight &&
        front.ceilingHeight == back.ceilingHeight) {
      continue;
    }

    final opentop = front.ceilingHeight < back.ceilingHeight
        ? front.ceilingHeight
        : back.ceilingHeight;

    final openbottom = front.floorHeight > back.floorHeight
        ? front.floorHeight
        : back.floorHeight;

    if (openbottom >= opentop) {
      return false;
    }

    final frac = _interceptVector2(ctx.strace, divl);

    if (front.floorHeight != back.floorHeight) {
      final slope = Fixed32.div(openbottom - ctx.sightZStart, frac);
      if (slope > ctx.bottomSlope) {
        ctx.bottomSlope = slope;
      }
    }

    if (front.ceilingHeight != back.ceilingHeight) {
      final slope = Fixed32.div(opentop - ctx.sightZStart, frac);
      if (slope < ctx.topSlope) {
        ctx.topSlope = slope;
      }
    }

    if (ctx.topSlope <= ctx.bottomSlope) {
      return false;
    }
  }

  return true;
}

bool _crossBSPNode(
  int bspnum,
  RenderState state,
  _SightContext ctx,
) {
  if (BspConstants.isSubsector(bspnum)) {
    if (bspnum == -1) {
      return _crossSubsector(0, state, ctx);
    }
    return _crossSubsector(BspConstants.getIndex(bspnum), state, ctx);
  }

  if (bspnum < 0 || bspnum >= state.nodes.length) {
    return true;
  }

  final bsp = state.nodes[bspnum];

  var side = _nodeDivlineSide(ctx.strace.x, ctx.strace.y, bsp);
  if (side == 2) side = 0;

  if (!_crossBSPNode(bsp.children[side], state, ctx)) {
    return false;
  }

  if (side == _nodeDivlineSide(ctx.t2x, ctx.t2y, bsp)) {
    return true;
  }

  return _crossBSPNode(bsp.children[side ^ 1], state, ctx);
}

bool checkSight(
  Mobj t1,
  Mobj t2,
  RenderState state, {
  Uint8List? rejectMatrix,
  int numSectors = 0,
}) {
  final sub1 = t1.subsector;
  final sub2 = t2.subsector;
  if (sub1 is! Subsector || sub2 is! Subsector) {
    return false;
  }

  if (rejectMatrix != null && numSectors > 0) {
    final s1 = sub1.sector.index;
    final s2 = sub2.sector.index;
    final pnum = s1 * numSectors + s2;
    final byteNum = pnum >> 3;
    final bitNum = 1 << (pnum & 7);

    if (byteNum < rejectMatrix.length && (rejectMatrix[byteNum] & bitNum) != 0) {
      return false;
    }
  }

  final ctx = _SightContext()
    ..validCount = state.validCount++
    ..sightZStart = t1.z + t1.height - (t1.height >> 2)
    ..topSlope = (t2.z + t2.height) - (t1.z + t1.height - (t1.height >> 2))
    ..bottomSlope = t2.z - (t1.z + t1.height - (t1.height >> 2))
    ..t2x = t2.x
    ..t2y = t2.y;

  ctx.strace
    ..x = t1.x
    ..y = t1.y
    ..dx = t2.x - t1.x
    ..dy = t2.y - t1.y;

  if (state.nodes.isEmpty) {
    return true;
  }

  return _crossBSPNode(state.nodes.length - 1, state, ctx);
}
