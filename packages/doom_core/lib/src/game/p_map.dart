import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _MapConstants {
  static const int useRange = 64 * Fixed32.fracUnit;
  static const int maxStepHeight = 24 * Fixed32.fracUnit;
  static const int maxDropOff = 24 * Fixed32.fracUnit;
}

class CollisionContext {
  Mobj? thing;
  int tmX = 0;
  int tmY = 0;
  int tmFloorZ = 0;
  int tmCeilingZ = 0;
  int tmDropoffZ = 0;
  Line? tmCeilingLine;
  Line? blockingLine;
  final List<Line> specHit = [];
  int tmBBox0 = 0;
  int tmBBox1 = 0;
  int tmBBox2 = 0;
  int tmBBox3 = 0;
  int tmFlags = 0;
}

final _ctx = CollisionContext();

bool tryMove(Mobj thing, int x, int y, LevelLocals level) {
  if (!checkPosition(thing, x, y, level)) {
    return false;
  }

  if ((thing.flags & MobjFlag.noClip) == 0) {
    if (_ctx.tmCeilingZ - _ctx.tmFloorZ < thing.height) {
      return false;
    }

    if (_ctx.tmCeilingZ - thing.z < thing.height) {
      return false;
    }

    if (_ctx.tmFloorZ - thing.z > _MapConstants.maxStepHeight) {
      return false;
    }

    if ((thing.flags & (MobjFlag.dropOff | MobjFlag.float)) == 0) {
      if (_ctx.tmFloorZ - _ctx.tmDropoffZ > _MapConstants.maxDropOff) {
        return false;
      }
    }
  }

  _unsetThingPosition(thing, level);

  thing.floorZ = _ctx.tmFloorZ;
  thing.ceilingZ = _ctx.tmCeilingZ;
  thing.x = x;
  thing.y = y;

  _setThingPosition(thing, level);

  for (final line in _ctx.specHit) {
    if (line.special != 0) {
      crossSpecialLine(line, thing, level);
    }
  }

  return true;
}

bool checkPosition(Mobj thing, int x, int y, LevelLocals level) {
  _ctx.thing = thing;
  _ctx.tmFlags = thing.flags;
  _ctx.tmX = x;
  _ctx.tmY = y;

  _ctx.tmBBox0 = y + thing.radius;
  _ctx.tmBBox1 = y - thing.radius;
  _ctx.tmBBox2 = x - thing.radius;
  _ctx.tmBBox3 = x + thing.radius;

  final ss = _pointInSubsector(x, y, level);
  if (ss == null) {
    _ctx.tmFloorZ = _ctx.tmDropoffZ = 0;
    _ctx.tmCeilingZ = 0;
    return false;
  }

  final sector = ss.sector;
  _ctx.tmFloorZ = _ctx.tmDropoffZ = sector.floorHeight;
  _ctx.tmCeilingZ = sector.ceilingHeight;
  _ctx.specHit.clear();
  _ctx.tmCeilingLine = null;
  _ctx.blockingLine = null;

  level.renderState.validCount++;
  final validCount = level.renderState.validCount;

  if ((thing.flags & MobjFlag.noClip) != 0) {
    return true;
  }

  final blockmap = level.blockmap;
  if (blockmap == null) {
    return true;
  }

  final (bxMin, byMin) = blockmap.worldToBlock(_ctx.tmBBox2, _ctx.tmBBox1);
  final (bxMax, byMax) = blockmap.worldToBlock(_ctx.tmBBox3, _ctx.tmBBox0);

  for (var by = byMin; by <= byMax; by++) {
    for (var bx = bxMin; bx <= bxMax; bx++) {
      if (!blockmap.isValidBlock(bx, by)) continue;

      for (final lineNum in blockmap.getLinesInBlock(bx, by)) {
        final line = level.renderState.lines[lineNum];

        if (line.validCount == validCount) continue;
        line.validCount = validCount;

        if (!_checkLine(line, thing)) {
          return false;
        }
      }
    }
  }

  return true;
}

bool _checkLine(Line line, Mobj thing) {
  if (_ctx.tmBBox3 <= line.bbox[2] ||
      _ctx.tmBBox2 >= line.bbox[3] ||
      _ctx.tmBBox0 <= line.bbox[1] ||
      _ctx.tmBBox1 >= line.bbox[0]) {
    return true;
  }

  if (_boxOnLineSide(_ctx.tmBBox2, _ctx.tmBBox3, _ctx.tmBBox1, _ctx.tmBBox0, line) != -1) {
    return true;
  }

  if (line.backSector == null) {
    _ctx.blockingLine = line;
    return false;
  }

  if ((line.flags & LineFlags.blocking) != 0) {
    _ctx.blockingLine = line;
    return false;
  }

  if ((thing.flags & MobjFlag.missile) == 0) {
    if (thing.player == null && (line.flags & LineFlags.blockMonsters) != 0) {
      _ctx.blockingLine = line;
      return false;
    }
  }

  final frontSector = line.frontSector;
  final backSector = line.backSector;

  if (frontSector == null || backSector == null) {
    return false;
  }

  final frontFloor = frontSector.floorHeight;
  final frontCeiling = frontSector.ceilingHeight;
  final backFloor = backSector.floorHeight;
  final backCeiling = backSector.ceilingHeight;

  final openTop = frontCeiling < backCeiling ? frontCeiling : backCeiling;
  final openBottom = frontFloor > backFloor ? frontFloor : backFloor;
  final lowFloor = frontFloor < backFloor ? frontFloor : backFloor;

  if (openTop < _ctx.tmCeilingZ) {
    _ctx.tmCeilingZ = openTop;
    _ctx.tmCeilingLine = line;
  }

  if (openBottom > _ctx.tmFloorZ) {
    _ctx.tmFloorZ = openBottom;
  }

  if (lowFloor < _ctx.tmDropoffZ) {
    _ctx.tmDropoffZ = lowFloor;
  }

  if (line.special != 0) {
    _ctx.specHit.add(line);
  }

  return true;
}

int _boxOnLineSide(int left, int right, int bottom, int top, Line line) {
  int p1;
  int p2;

  switch (line.slopeType) {
    case 0:
      p1 = top > line.v1.y ? 1 : 0;
      p2 = bottom > line.v1.y ? 1 : 0;
      if (line.dx < 0) {
        p1 ^= 1;
        p2 ^= 1;
      }
    case 1:
      p1 = right < line.v1.x ? 1 : 0;
      p2 = left < line.v1.x ? 1 : 0;
      if (line.dy < 0) {
        p1 ^= 1;
        p2 ^= 1;
      }
    case 2:
      p1 = _pointOnLineSide(left, top, line);
      p2 = _pointOnLineSide(right, bottom, line);
    default:
      p1 = _pointOnLineSide(right, top, line);
      p2 = _pointOnLineSide(left, bottom, line);
  }

  if (p1 == p2) {
    return p1;
  }
  return -1;
}

int _pointOnLineSide(int x, int y, Line line) {
  if (line.dx == 0) {
    if (x <= line.v1.x) {
      return line.dy > 0 ? 1 : 0;
    }
    return line.dy < 0 ? 1 : 0;
  }

  if (line.dy == 0) {
    if (y <= line.v1.y) {
      return line.dx < 0 ? 1 : 0;
    }
    return line.dx > 0 ? 1 : 0;
  }

  final dx = x - line.v1.x;
  final dy = y - line.v1.y;

  final left = Fixed32.mul(line.dy >> Fixed32.fracBits, dx);
  final right = Fixed32.mul(dy, line.dx >> Fixed32.fracBits);

  return right >= left ? 1 : 0;
}

late int _tmXMove;
late int _tmYMove;
Mobj? _slideMo;
late int _bestSlideFrac;
Line? _bestSlideLine;

abstract final class _SlideConstants {
  static const int fudgeFactor = 0x800;
}

void slideMove(Mobj mo, LevelLocals level) {
  _slideMo = mo;

  for (var hitCount = 0; hitCount < 3; hitCount++) {

    int leadX;
    int leadY;
    int trailX;
    int trailY;

    if (mo.momX > 0) {
      leadX = mo.x + mo.radius;
      trailX = mo.x - mo.radius;
    } else {
      leadX = mo.x - mo.radius;
      trailX = mo.x + mo.radius;
    }

    if (mo.momY > 0) {
      leadY = mo.y + mo.radius;
      trailY = mo.y - mo.radius;
    } else {
      leadY = mo.y - mo.radius;
      trailY = mo.y + mo.radius;
    }

    _bestSlideFrac = Fixed32.fracUnit + 1;
    _bestSlideLine = null;

    _slidePathTraverse(leadX, leadY, leadX + mo.momX, leadY + mo.momY, level);
    _slidePathTraverse(trailX, leadY, trailX + mo.momX, leadY + mo.momY, level);
    _slidePathTraverse(leadX, trailY, leadX + mo.momX, trailY + mo.momY, level);

    if (_bestSlideFrac == Fixed32.fracUnit + 1) {
      _stairStep(mo, level);
      return;
    }

    _bestSlideFrac -= _SlideConstants.fudgeFactor;

    if (_bestSlideFrac > 0) {
      final newX = Fixed32.mul(mo.momX, _bestSlideFrac);
      final newY = Fixed32.mul(mo.momY, _bestSlideFrac);

      if (!tryMove(mo, mo.x + newX, mo.y + newY, level)) {
        _stairStep(mo, level);
        return;
      }
    }

    _bestSlideFrac = Fixed32.fracUnit - (_bestSlideFrac + _SlideConstants.fudgeFactor);

    if (_bestSlideFrac > Fixed32.fracUnit) {
      _bestSlideFrac = Fixed32.fracUnit;
    }

    if (_bestSlideFrac <= 0) {
      return;
    }

    _tmXMove = Fixed32.mul(mo.momX, _bestSlideFrac);
    _tmYMove = Fixed32.mul(mo.momY, _bestSlideFrac);

    _hitSlideLine(_bestSlideLine!);

    mo.momX = _tmXMove;
    mo.momY = _tmYMove;

    if (tryMove(mo, mo.x + _tmXMove, mo.y + _tmYMove, level)) {
      return;
    }
  }

  _stairStep(mo, level);
}

void _stairStep(Mobj mo, LevelLocals level) {
  if (!tryMove(mo, mo.x, mo.y + mo.momY, level)) {
    tryMove(mo, mo.x + mo.momX, mo.y, level);
  }
}

void _slidePathTraverse(int x1, int y1, int x2, int y2, LevelLocals level) {
  final blockmap = level.blockmap;
  if (blockmap == null) return;

  level.renderState.validCount++;
  final validCount = level.renderState.validCount;

  final dx = x2 - x1;
  final dy = y2 - y1;

  final (bx1, by1) = blockmap.worldToBlock(x1, y1);
  final (bx2, by2) = blockmap.worldToBlock(x2, y2);

  final stepX = bx2 > bx1 ? 1 : (bx2 < bx1 ? -1 : 0);
  final stepY = by2 > by1 ? 1 : (by2 < by1 ? -1 : 0);

  var bx = bx1;
  var by = by1;

  final maxSteps = (bx2 - bx1).abs() + (by2 - by1).abs() + 2;
  var steps = 0;

  while (steps < maxSteps) {
    steps++;

    if (blockmap.isValidBlock(bx, by)) {
      for (final lineNum in blockmap.getLinesInBlock(bx, by)) {
        final line = level.renderState.lines[lineNum];

        if (line.validCount == validCount) continue;
        line.validCount = validCount;

        _addLineIntercept(x1, y1, dx, dy, line);
      }
    }

    if (bx == bx2 && by == by2) break;

    if (stepX != 0 && bx != bx2) {
      bx += stepX;
    } else if (stepY != 0 && by != by2) {
      by += stepY;
    } else {
      break;
    }
  }
}

void _addLineIntercept(int x1, int y1, int dx, int dy, Line line) {
  int s1;
  int s2;

  if (dx.abs() > 16 * Fixed32.fracUnit || dy.abs() > 16 * Fixed32.fracUnit) {
    s1 = _pointOnDivlineSide(line.v1.x, line.v1.y, x1, y1, dx, dy);
    s2 = _pointOnDivlineSide(line.v2.x, line.v2.y, x1, y1, dx, dy);
  } else {
    s1 = _pointOnLineSide(x1, y1, line);
    s2 = _pointOnLineSide(x1 + dx, y1 + dy, line);
  }

  if (s1 == s2) return;

  final frac = _interceptVector(x1, y1, dx, dy, line);

  if (frac < 0) return;

  _slideTraverse(line, frac);
}

int _pointOnDivlineSide(int x, int y, int lineX, int lineY, int lineDx, int lineDy) {
  if (lineDx == 0) {
    if (x <= lineX) {
      return lineDy > 0 ? 1 : 0;
    }
    return lineDy < 0 ? 1 : 0;
  }

  if (lineDy == 0) {
    if (y <= lineY) {
      return lineDx < 0 ? 1 : 0;
    }
    return lineDx > 0 ? 1 : 0;
  }

  final ptDx = x - lineX;
  final ptDy = y - lineY;

  final left = Fixed32.mul(lineDy >> Fixed32.fracBits, ptDx);
  final right = Fixed32.mul(ptDy, lineDx >> Fixed32.fracBits);

  return right < left ? 0 : 1;
}

int _interceptVector(int traceX, int traceY, int traceDx, int traceDy, Line line) {
  final lineX = line.v1.x;
  final lineY = line.v1.y;
  final lineDx = line.dx;
  final lineDy = line.dy;

  final den = Fixed32.mul(lineDy >> 8, traceDx) - Fixed32.mul(lineDx >> 8, traceDy);
  if (den == 0) return 0;

  final num = Fixed32.mul((lineX - traceX) >> 8, lineDy) +
      Fixed32.mul((traceY - lineY) >> 8, lineDx);

  return Fixed32.div(num, den);
}

void _slideTraverse(Line line, int frac) {
  if (line.backSector == null) {
    if (_pointOnLineSide(_slideMo!.x, _slideMo!.y, line) != 0) {
      return;
    }
    _updateBestSlide(line, frac);
    return;
  }

  final front = line.frontSector;
  final back = line.backSector;
  if (front == null || back == null) {
    _updateBestSlide(line, frac);
    return;
  }

  final openTop = front.ceilingHeight < back.ceilingHeight
      ? front.ceilingHeight
      : back.ceilingHeight;
  final openBottom =
      front.floorHeight > back.floorHeight ? front.floorHeight : back.floorHeight;
  final openRange = openTop - openBottom;

  if (openRange < _slideMo!.height) {
    _updateBestSlide(line, frac);
    return;
  }

  if (openTop - _slideMo!.z < _slideMo!.height) {
    _updateBestSlide(line, frac);
    return;
  }

  if (openBottom - _slideMo!.z > _MapConstants.maxStepHeight) {
    _updateBestSlide(line, frac);
    return;
  }
}

void _updateBestSlide(Line line, int frac) {
  if (frac < _bestSlideFrac) {
    _bestSlideFrac = frac;
    _bestSlideLine = line;
  }
}

void _hitSlideLine(Line ld) {
  if (ld.slopeType == SlopeType.horizontal) {
    _tmYMove = 0;
    return;
  }

  if (ld.slopeType == SlopeType.vertical) {
    _tmXMove = 0;
    return;
  }

  final side = _pointOnLineSide(_slideMo!.x, _slideMo!.y, ld);

  var lineAngle = _pointToAngle(0, 0, ld.dx, ld.dy);

  if (side == 1) {
    lineAngle = (lineAngle + Angle.ang180).u32;
  }

  final moveAngle = _pointToAngle(0, 0, _tmXMove, _tmYMove);
  var deltaAngle = (moveAngle - lineAngle).u32;

  if (deltaAngle > Angle.ang180) {
    deltaAngle = (deltaAngle + Angle.ang180).u32;
  }

  final lineFineAngle = (lineAngle >> Angle.angleToFineShift) & Angle.fineMask;
  final deltaFineAngle = (deltaAngle >> Angle.angleToFineShift) & Angle.fineMask;

  final moveDist = _approxDistance(_tmXMove, _tmYMove);
  final newDist = Fixed32.mul(moveDist, fineCosine(deltaFineAngle));

  _tmXMove = Fixed32.mul(newDist, fineCosine(lineFineAngle));
  _tmYMove = Fixed32.mul(newDist, fineSine(lineFineAngle));
}

int _approxDistance(int dx, int dy) {
  dx = dx.abs();
  dy = dy.abs();
  if (dx < dy) {
    return dx + dy - (dx >> 1);
  }
  return dx + dy - (dy >> 1);
}

int _pointToAngle(int x1, int y1, int x2, int y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;

  if (dx == 0 && dy == 0) {
    return 0;
  }

  if (dx >= 0) {
    if (dy >= 0) {
      if (dx > dy) {
        return _tanToAngle(_slopeDiv(dy, dx));
      }
      return (Angle.ang90 - 1 - _tanToAngle(_slopeDiv(dx, dy))).u32;
    } else {
      final absDy = -dy;
      if (dx > absDy) {
        return (-_tanToAngle(_slopeDiv(absDy, dx))).u32;
      }
      return (Angle.ang270 + _tanToAngle(_slopeDiv(dx, absDy))).u32;
    }
  } else {
    final absDx = -dx;
    if (dy >= 0) {
      if (absDx > dy) {
        return (Angle.ang180 - 1 - _tanToAngle(_slopeDiv(dy, absDx))).u32;
      }
      return (Angle.ang90 + _tanToAngle(_slopeDiv(absDx, dy))).u32;
    } else {
      final absDy = -dy;
      if (absDx > absDy) {
        return (Angle.ang180 + _tanToAngle(_slopeDiv(absDy, absDx))).u32;
      }
      return (Angle.ang270 - 1 - _tanToAngle(_slopeDiv(absDx, absDy))).u32;
    }
  }
}

int _tanToAngle(int slope) {
  return tanToAngle(slope.clamp(0, Angle.slopeRange));
}

int _slopeDiv(int num, int den) {
  if (den < 512) return Angle.slopeRange;
  return ((num << 3) ~/ (den >> 8)).clamp(0, Angle.slopeRange);
}

Subsector? _pointInSubsector(int x, int y, LevelLocals level) {
  final state = level.renderState;

  if (state.nodes.isEmpty) {
    return state.subsectors.isNotEmpty ? state.subsectors[0] : null;
  }

  var nodeNum = state.nodes.length - 1;

  while (!BspConstants.isSubsector(nodeNum)) {
    final node = state.nodes[nodeNum];
    final side = _nodePointOnSide(x, y, node);
    nodeNum = node.children[side];
  }

  return state.subsectors[BspConstants.getIndex(nodeNum)];
}

int _nodePointOnSide(int x, int y, Node node) {
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

  return right < left ? 0 : 1;
}

void _unsetThingPosition(Mobj thing, LevelLocals level) {
  if ((thing.flags & MobjFlag.noSector) == 0) {
    if (thing.sNext != null) {
      thing.sNext!.sPrev = thing.sPrev;
    }

    if (thing.sPrev != null) {
      thing.sPrev!.sNext = thing.sNext;
    } else {
      final ss = thing.subsector;
      if (ss is Subsector) {
        ss.sector.thingList = thing.sNext;
      }
    }
  }
}

void _setThingPosition(Mobj thing, LevelLocals level) {
  final ss = _pointInSubsector(thing.x, thing.y, level);
  if (ss == null) return;

  thing.subsector = ss;

  if ((thing.flags & MobjFlag.noSector) == 0) {
    final sector = ss.sector;

    thing.sPrev = null;
    thing.sNext = sector.thingList;

    if (sector.thingList != null) {
      sector.thingList!.sPrev = thing;
    }

    sector.thingList = thing;
  }
}

void crossSpecialLine(Line line, Mobj thing, LevelLocals level) {
  final side = _pointOnLineSide(thing.x, thing.y, line);
  spec.crossSpecialLine(line, side, thing, level);
}

void useLinesFrom(Mobj mobj, LevelLocals level) {
  final angle = mobj.angle.u32 >> Angle.angleToFineShift;
  final x1 = mobj.x;
  final y1 = mobj.y;
  final x2 = x1 + Fixed32.mul(_MapConstants.useRange, fineCosine(angle & Angle.fineMask));
  final y2 = y1 + Fixed32.mul(_MapConstants.useRange, fineSine(angle & Angle.fineMask));

  _pathTraverse(x1, y1, x2, y2, level, (line) {
    if (line.special == 0) {
      if (_lineOpening(line) <= 0) {
        return false;
      }
      return true;
    }

    final side = _pointOnLineSide(mobj.x, mobj.y, line);
    useSpecialLine(mobj, line, side, level);
    return false;
  });
}

int _lineOpening(Line line) {
  if (line.backSector == null) return 0;

  final front = line.frontSector;
  final back = line.backSector;

  if (front == null || back == null) return 0;

  final frontCeiling = front.ceilingHeight;
  final backCeiling = back.ceilingHeight;
  final frontFloor = front.floorHeight;
  final backFloor = back.floorHeight;

  final openTop = frontCeiling < backCeiling ? frontCeiling : backCeiling;
  final openBottom = frontFloor > backFloor ? frontFloor : backFloor;

  return openTop - openBottom;
}

class _Intercept {
  _Intercept(this.line, this.frac);
  final Line line;
  final int frac;
}

void _pathTraverse(
  int x1,
  int y1,
  int x2,
  int y2,
  LevelLocals level,
  bool Function(Line) callback,
) {
  final blockmap = level.blockmap;
  if (blockmap == null) {
    _pathTraverseFallback(x1, y1, x2, y2, level, callback);
    return;
  }

  level.renderState.validCount++;
  final validCount = level.renderState.validCount;

  final dx = x2 - x1;
  final dy = y2 - y1;

  final (bx1, by1) = blockmap.worldToBlock(x1, y1);
  final (bx2, by2) = blockmap.worldToBlock(x2, y2);

  final stepX = bx2 > bx1 ? 1 : (bx2 < bx1 ? -1 : 0);
  final stepY = by2 > by1 ? 1 : (by2 < by1 ? -1 : 0);

  var bx = bx1;
  var by = by1;

  final maxSteps = (bx2 - bx1).abs() + (by2 - by1).abs() + 1;
  var steps = 0;

  final intercepts = <_Intercept>[];

  while (steps < maxSteps) {
    steps++;

    if (blockmap.isValidBlock(bx, by)) {
      for (final lineNum in blockmap.getLinesInBlock(bx, by)) {
        final line = level.renderState.lines[lineNum];

        if (line.validCount == validCount) continue;
        line.validCount = validCount;

        final frac = _getLineFrac(line, x1, y1, dx, dy);
        if (frac < 0 || frac > Fixed32.fracUnit) continue;

        intercepts.add(_Intercept(line, frac));
      }
    }

    if (bx == bx2 && by == by2) break;

    if (stepX != 0 && bx != bx2) {
      bx += stepX;
    } else if (stepY != 0 && by != by2) {
      by += stepY;
    } else {
      break;
    }
  }

  intercepts.sort((a, b) => a.frac.compareTo(b.frac));

  for (final intercept in intercepts) {
    if (!callback(intercept.line)) return;
  }
}

int _getLineFrac(Line line, int traceX, int traceY, int traceDx, int traceDy) {
  final s1 = _pointOnTraceSide(line.v1.x, line.v1.y, traceX, traceY, traceDx, traceDy);
  final s2 = _pointOnTraceSide(line.v2.x, line.v2.y, traceX, traceY, traceDx, traceDy);

  if (s1 == s2) return -1;

  return _traceInterceptFrac(traceX, traceY, traceDx, traceDy, line);
}

void _pathTraverseFallback(
  int x1,
  int y1,
  int x2,
  int y2,
  LevelLocals level,
  bool Function(Line) callback,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;

  final intercepts = <_Intercept>[];

  for (final line in level.renderState.lines) {
    final frac = _getLineFrac(line, x1, y1, dx, dy);
    if (frac < 0 || frac > Fixed32.fracUnit) continue;
    intercepts.add(_Intercept(line, frac));
  }

  intercepts.sort((a, b) => a.frac.compareTo(b.frac));

  for (final intercept in intercepts) {
    if (!callback(intercept.line)) return;
  }
}

int _pointOnTraceSide(int x, int y, int traceX, int traceY, int traceDx, int traceDy) {
  if (traceDx == 0) {
    if (x <= traceX) {
      return traceDy > 0 ? 1 : 0;
    }
    return traceDy < 0 ? 1 : 0;
  }

  if (traceDy == 0) {
    if (y <= traceY) {
      return traceDx < 0 ? 1 : 0;
    }
    return traceDx > 0 ? 1 : 0;
  }

  final dx = x - traceX;
  final dy = y - traceY;

  final left = Fixed32.mul(traceDy >> Fixed32.fracBits, dx);
  final right = Fixed32.mul(dy, traceDx >> Fixed32.fracBits);

  return right < left ? 0 : 1;
}

int _traceInterceptFrac(int traceX, int traceY, int traceDx, int traceDy, Line line) {
  final lineX = line.v1.x;
  final lineY = line.v1.y;
  final lineDx = line.dx;
  final lineDy = line.dy;

  final den = Fixed32.mul(lineDy >> 8, traceDx) - Fixed32.mul(lineDx >> 8, traceDy);
  if (den == 0) return -1;

  final num = Fixed32.mul((lineX - traceX) >> 8, lineDy) +
      Fixed32.mul((traceY - lineY) >> 8, lineDx);

  return Fixed32.div(num, den);
}

void useSpecialLine(Mobj thing, Line line, int side, LevelLocals level) {
  spec.useSpecialLine(thing, line, side, level);
}
