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

  void set(int x, int y, int dx, int dy) {
    this.x = x;
    this.y = y;
    this.dx = dx;
    this.dy = dy;
  }
}

/// Pre-allocated context to avoid heap allocations during sight checks.
/// Mirrors C's global variables: sightzstart, topslope, bottomslope, strace, t2x, t2y
class _SightContext {
  int sightZStart = 0;
  int topSlope = 0;
  int bottomSlope = 0;
  int t2x = 0;
  int t2y = 0;
  final _Divline strace = _Divline();
  int validCount = 0;

  /// Reusable divline for line crossing checks in _crossSubsector.
  /// Mirrors C's stack-allocated 'divl' variable.
  final _Divline divl = _Divline();
}

/// Single pre-allocated context reused for all sight checks.
/// This matches the C code's use of global variables.
final _SightContext _ctx = _SightContext();

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

/// Check if sight trace crosses a subsector successfully.
/// Uses global _ctx to avoid allocations (matches C's use of globals).
bool _crossSubsector(int num, RenderState state) {
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

    if (line.validCount == _ctx.validCount) continue;
    line.validCount = _ctx.validCount;

    final v1 = line.v1;
    final v2 = line.v2;

    var s1 = _divlineSide(v1.x, v1.y, _ctx.strace);
    var s2 = _divlineSide(v2.x, v2.y, _ctx.strace);

    if (s1 == s2) continue;

    // Reuse pre-allocated divl instead of creating new object (matches C's stack variable)
    final divl = _ctx.divl;
    divl.set(v1.x, v1.y, v2.x - v1.x, v2.y - v1.y);

    s1 = _divlineSide(_ctx.strace.x, _ctx.strace.y, divl);
    s2 = _divlineSide(_ctx.t2x, _ctx.t2y, divl);

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

    final frac = _interceptVector2(_ctx.strace, divl);

    if (front.floorHeight != back.floorHeight) {
      final slope = Fixed32.div(openbottom - _ctx.sightZStart, frac);
      if (slope > _ctx.bottomSlope) {
        _ctx.bottomSlope = slope;
      }
    }

    if (front.ceilingHeight != back.ceilingHeight) {
      final slope = Fixed32.div(opentop - _ctx.sightZStart, frac);
      if (slope < _ctx.topSlope) {
        _ctx.topSlope = slope;
      }
    }

    if (_ctx.topSlope <= _ctx.bottomSlope) {
      return false;
    }
  }

  return true;
}

/// Recursive BSP traversal for sight checking.
/// Uses global _ctx to avoid passing context through call stack (matches C).
bool _crossBSPNode(int bspnum, RenderState state) {
  if (BspConstants.isSubsector(bspnum)) {
    if (bspnum == -1) {
      return _crossSubsector(0, state);
    }
    return _crossSubsector(BspConstants.getIndex(bspnum), state);
  }

  if (bspnum < 0 || bspnum >= state.nodes.length) {
    return true;
  }

  final bsp = state.nodes[bspnum];

  var side = _nodeDivlineSide(_ctx.strace.x, _ctx.strace.y, bsp);
  if (side == 2) side = 0;

  if (!_crossBSPNode(bsp.children[side], state)) {
    return false;
  }

  if (side == _nodeDivlineSide(_ctx.t2x, _ctx.t2y, bsp)) {
    return true;
  }

  return _crossBSPNode(bsp.children[side ^ 1], state);
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

  // Reuse pre-allocated context (matches C's global variables)
  final sightZStart = t1.z + t1.height - (t1.height >> 2);
  _ctx
    ..validCount = state.validCount++
    ..sightZStart = sightZStart
    ..topSlope = (t2.z + t2.height) - sightZStart
    ..bottomSlope = t2.z - sightZStart
    ..t2x = t2.x
    ..t2y = t2.y;

  _ctx.strace.set(t1.x, t1.y, t2.x - t1.x, t2.y - t1.y);

  if (state.nodes.isEmpty) {
    return true;
  }

  return _crossBSPNode(state.nodes.length - 1, state);
}
