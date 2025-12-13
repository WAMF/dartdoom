import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

int approxDistance(int dx, int dy) {
  final adx = dx.abs();
  final ady = dy.abs();
  if (adx < ady) {
    return adx + ady - (adx >> 1);
  }
  return adx + ady - (ady >> 1);
}

int pointOnLineSide(int x, int y, Line line) {
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

  if (right < left) return 0;
  return 1;
}

int boxOnLineSide(List<int> tmbox, Line ld) {
  int p1;
  int p2;

  switch (ld.slopeType) {
    case SlopeType.horizontal:
      p1 = tmbox[_Box.top] > ld.v1.y ? 1 : 0;
      p2 = tmbox[_Box.bottom] > ld.v1.y ? 1 : 0;
      if (ld.dx < 0) {
        p1 ^= 1;
        p2 ^= 1;
      }

    case SlopeType.vertical:
      p1 = tmbox[_Box.right] < ld.v1.x ? 1 : 0;
      p2 = tmbox[_Box.left] < ld.v1.x ? 1 : 0;
      if (ld.dy < 0) {
        p1 ^= 1;
        p2 ^= 1;
      }

    case SlopeType.positive:
      p1 = pointOnLineSide(tmbox[_Box.left], tmbox[_Box.top], ld);
      p2 = pointOnLineSide(tmbox[_Box.right], tmbox[_Box.bottom], ld);

    case SlopeType.negative:
      p1 = pointOnLineSide(tmbox[_Box.right], tmbox[_Box.top], ld);
      p2 = pointOnLineSide(tmbox[_Box.left], tmbox[_Box.bottom], ld);

    default:
      p1 = 0;
      p2 = 0;
  }

  if (p1 == p2) return p1;
  return -1;
}

class LineOpening {
  int openTop = 0;
  int openBottom = 0;
  int openRange = 0;
  int lowFloor = 0;
}

LineOpening lineOpening(Line linedef) {
  final result = LineOpening();

  if (linedef.sideNum[1] == -1) {
    result.openRange = 0;
    return result;
  }

  final front = linedef.frontSector;
  final back = linedef.backSector;

  if (front == null || back == null) {
    result.openRange = 0;
    return result;
  }

  if (front.ceilingHeight < back.ceilingHeight) {
    result.openTop = front.ceilingHeight;
  } else {
    result.openTop = back.ceilingHeight;
  }

  if (front.floorHeight > back.floorHeight) {
    result
      ..openBottom = front.floorHeight
      ..lowFloor = back.floorHeight;
  } else {
    result
      ..openBottom = back.floorHeight
      ..lowFloor = front.floorHeight;
  }

  result.openRange = result.openTop - result.openBottom;
  return result;
}

void unsetThingPosition(Mobj thing) {
  if ((thing.flags & MobjFlag.noSector) == 0) {
    if (thing.sNext != null) {
      thing.sNext!.sPrev = thing.sPrev;
    }

    if (thing.sPrev != null) {
      thing.sPrev!.sNext = thing.sNext;
    } else {
      final subsector = thing.subsector;
      if (subsector is Subsector) {
        subsector.sector.thingList = thing.sNext;
      }
    }
  }

  thing
    ..sNext = null
    ..sPrev = null
    ..bNext = null
    ..bPrev = null;
}

void setThingPosition(Mobj thing, RenderState state) {
  final ss = pointInSubsector(thing.x, thing.y, state);
  thing.subsector = ss;

  if ((thing.flags & MobjFlag.noSector) == 0) {
    final sec = ss.sector;

    thing
      ..sPrev = null
      ..sNext = sec.thingList;

    if (sec.thingList != null) {
      sec.thingList!.sPrev = thing;
    }

    sec.thingList = thing;
  }
}

Subsector pointInSubsector(int x, int y, RenderState state) {
  if (state.nodes.isEmpty) {
    return state.subsectors.isNotEmpty
        ? state.subsectors[0]
        : Subsector(
            sector: Sector(
              floorHeight: 0,
              ceilingHeight: 0,
              floorPic: 0,
              ceilingPic: 0,
              lightLevel: 0,
              special: 0,
              tag: 0,
            ),
            numLines: 0,
            firstLine: 0,
          );
  }

  var nodeNum = state.nodes.length - 1;

  while (!BspConstants.isSubsector(nodeNum)) {
    final node = state.nodes[nodeNum];
    final side = _pointOnNodeSide(x, y, node);
    nodeNum = node.children[side];
  }

  return state.subsectors[BspConstants.getIndex(nodeNum)];
}

int _pointOnNodeSide(int x, int y, Node node) {
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

abstract final class _Box {
  static const int top = 0;
  static const int bottom = 1;
  static const int left = 2;
  static const int right = 3;
}

class Divline {
  int x = 0;
  int y = 0;
  int dx = 0;
  int dy = 0;
}

void makeDivline(Line li, Divline dl) {
  dl
    ..x = li.v1.x
    ..y = li.v1.y
    ..dx = li.dx
    ..dy = li.dy;
}

int interceptVector(Divline v2, Divline v1) {
  final den =
      Fixed32.mul(v1.dy >> 8, v2.dx) - Fixed32.mul(v1.dx >> 8, v2.dy);

  if (den == 0) return 0;

  final num = Fixed32.mul((v1.x - v2.x) >> 8, v1.dy) +
      Fixed32.mul((v2.y - v1.y) >> 8, v1.dx);

  return Fixed32.div(num, den);
}

int pointOnDivlineSide(int x, int y, Divline line) {
  if (line.dx == 0) {
    if (x <= line.x) {
      return line.dy > 0 ? 1 : 0;
    }
    return line.dy < 0 ? 1 : 0;
  }

  if (line.dy == 0) {
    if (y <= line.y) {
      return line.dx < 0 ? 1 : 0;
    }
    return line.dx > 0 ? 1 : 0;
  }

  final dx = x - line.x;
  final dy = y - line.y;

  if ((line.dy ^ line.dx ^ dx ^ dy) & 0x80000000 != 0) {
    if ((line.dy ^ dx) & 0x80000000 != 0) {
      return 1;
    }
    return 0;
  }

  final left = Fixed32.mul(line.dy >> 8, dx >> 8);
  final right = Fixed32.mul(dy >> 8, line.dx >> 8);

  if (right < left) return 0;
  return 1;
}
