import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _BspConstants {
  static const int screenWidth = 320;
}

abstract final class _BboxIndices {
  static const int top = 0;
  static const int bottom = 1;
  static const int left = 2;
  static const int right = 3;
}

final Int32List _checkCoord = Int32List.fromList([
  3, 0, 2, 1,
  3, 0, 2, 0,
  3, 1, 2, 1,
  0, 0, 0, 0,
  2, 0, 2, 1,
  0, 0, 0, 0,
  3, 1, 3, 0,
  0, 0, 0, 0,
  2, 0, 3, 1,
  2, 1, 3, 1,
  2, 1, 3, 0,
]);

class BspTraversal {
  BspTraversal(this._state, this._renderer);

  final RenderState _state;
  final Renderer _renderer;

  final List<ClipRange> _solidSegs = [];
  SegCallback? onAddLine;

  void clearClipSegs() {
    _solidSegs
      ..clear()
      ..add(ClipRange(-0x7FFFFFFF, -1))
      ..add(ClipRange(_BspConstants.screenWidth, 0x7FFFFFFF));
  }

  void renderBspNode(int nodeNum) {
    if (BspConstants.isSubsector(nodeNum)) {
      if (nodeNum == -1) {
        _renderSubsector(0);
      } else {
        _renderSubsector(BspConstants.getIndex(nodeNum));
      }
      return;
    }

    final node = _state.nodes[nodeNum];
    final side = _renderer.pointOnSide(_state.viewX, _state.viewY, node);

    renderBspNode(node.children[side]);

    if (_checkBBox(node.bbox[side ^ 1])) {
      renderBspNode(node.children[side ^ 1]);
    }
  }

  void _renderSubsector(int num) {
    final sub = _state.subsectors[num];
    final count = sub.numLines;
    final firstLine = sub.firstLine;

    for (var i = 0; i < count; i++) {
      _addLine(_state.segs[firstLine + i]);
    }
  }

  void _addLine(Seg seg) {
    final angle1 = _renderer.pointToAngle(seg.v1.x, seg.v1.y);
    final angle2 = _renderer.pointToAngle(seg.v2.x, seg.v2.y);

    final span = (angle1 - angle2).u32.s32;
    if (span <= 0) {
      return;
    }

    final rwAngle1 = angle1;
    var angle1Adj = (angle1 - _state.viewAngle).u32.s32;
    var angle2Adj = (angle2 - _state.viewAngle).u32.s32;

    var tSpan = (angle1Adj + _state.clipAngle).u32.s32;
    if (tSpan > 2 * _state.clipAngle) {
      tSpan -= 2 * _state.clipAngle;
      if (tSpan >= span) {
        return;
      }
      angle1Adj = _state.clipAngle;
    }

    tSpan = (_state.clipAngle - angle2Adj).u32.s32;
    if (tSpan > 2 * _state.clipAngle) {
      tSpan -= 2 * _state.clipAngle;
      if (tSpan >= span) {
        return;
      }
      angle2Adj = -_state.clipAngle;
    }

    final x1 = _renderer.angleToX((angle1Adj + Angle.ang90).u32.s32);
    final x2 = _renderer.angleToX((angle2Adj + Angle.ang90).u32.s32);

    if (x1 == x2) {
      return;
    }

    final backSector = seg.backSector;

    if (backSector == null) {
      _clipSolidWallSegment(x1, x2 - 1, seg, rwAngle1);
    } else {
      if (backSector.ceilingHeight <= seg.frontSector.floorHeight ||
          backSector.floorHeight >= seg.frontSector.ceilingHeight) {
        _clipSolidWallSegment(x1, x2 - 1, seg, rwAngle1);
      } else if (backSector.ceilingHeight != seg.frontSector.ceilingHeight ||
          backSector.floorHeight != seg.frontSector.floorHeight) {
        _clipPassWallSegment(x1, x2 - 1, seg, rwAngle1);
      } else {
        if (backSector.ceilingPic == seg.frontSector.ceilingPic &&
            backSector.floorPic == seg.frontSector.floorPic &&
            backSector.lightLevel == seg.frontSector.lightLevel &&
            seg.sidedef.midTexture == 0) {
          return;
        }
        _clipPassWallSegment(x1, x2 - 1, seg, rwAngle1);
      }
    }
  }

  void _clipSolidWallSegment(int first, int last, Seg seg, int rwAngle1) {
    var startIdx = 0;
    while (_solidSegs[startIdx].last < first - 1) {
      startIdx++;
    }

    if (first < _solidSegs[startIdx].first) {
      if (last < _solidSegs[startIdx].first - 1) {
        onAddLine?.call(seg, first, last, rwAngle1);
        _solidSegs.insert(startIdx, ClipRange(first, last));
        return;
      }

      onAddLine?.call(seg, first, _solidSegs[startIdx].first - 1, rwAngle1);
      _solidSegs[startIdx].first = first;
    }

    if (last <= _solidSegs[startIdx].last) {
      return;
    }

    var nextIdx = startIdx;
    while (last >= _solidSegs[nextIdx + 1].first - 1) {
      onAddLine?.call(
        seg,
        _solidSegs[nextIdx].last + 1,
        _solidSegs[nextIdx + 1].first - 1,
        rwAngle1,
      );
      nextIdx++;

      if (last <= _solidSegs[nextIdx].last) {
        _solidSegs[startIdx].last = _solidSegs[nextIdx].last;
        _removeRange(startIdx + 1, nextIdx);
        return;
      }
    }

    onAddLine?.call(seg, _solidSegs[nextIdx].last + 1, last, rwAngle1);
    _solidSegs[startIdx].last = last;
    _removeRange(startIdx + 1, nextIdx);
  }

  void _clipPassWallSegment(int first, int last, Seg seg, int rwAngle1) {
    var startIdx = 0;
    while (_solidSegs[startIdx].last < first - 1) {
      startIdx++;
    }

    if (first < _solidSegs[startIdx].first) {
      if (last < _solidSegs[startIdx].first - 1) {
        onAddLine?.call(seg, first, last, rwAngle1);
        return;
      }
      onAddLine?.call(seg, first, _solidSegs[startIdx].first - 1, rwAngle1);
    }

    if (last <= _solidSegs[startIdx].last) {
      return;
    }

    while (last >= _solidSegs[startIdx + 1].first - 1) {
      onAddLine?.call(
        seg,
        _solidSegs[startIdx].last + 1,
        _solidSegs[startIdx + 1].first - 1,
        rwAngle1,
      );
      startIdx++;

      if (last <= _solidSegs[startIdx].last) {
        return;
      }
    }

    onAddLine?.call(seg, _solidSegs[startIdx].last + 1, last, rwAngle1);
  }

  void _removeRange(int start, int end) {
    if (start > end) return;
    _solidSegs.removeRange(start, end + 1);
  }

  bool _checkBBox(Int32List bboxArray) {
    final viewX = _state.viewX;
    final viewY = _state.viewY;

    int boxPos;
    if (viewX <= bboxArray[_BboxIndices.left]) {
      boxPos = 0;
    } else if (viewX < bboxArray[_BboxIndices.right]) {
      boxPos = 1;
    } else {
      boxPos = 2;
    }

    if (viewY >= bboxArray[_BboxIndices.top]) {
      boxPos += 0;
    } else if (viewY > bboxArray[_BboxIndices.bottom]) {
      boxPos += 4;
    } else {
      boxPos += 8;
    }

    if (boxPos == 5) {
      return true;
    }

    final checkIdx = boxPos * 4;
    final x1 = bboxArray[_checkCoord[checkIdx]];
    final y1 = bboxArray[_checkCoord[checkIdx + 1]];
    final x2 = bboxArray[_checkCoord[checkIdx + 2]];
    final y2 = bboxArray[_checkCoord[checkIdx + 3]];

    final angle1 = _renderer.pointToAngle(x1, y1) - _state.viewAngle;
    final angle2 = _renderer.pointToAngle(x2, y2) - _state.viewAngle;

    final span = (angle1 - angle2).u32.s32;
    if (span >= Angle.ang180) {
      return true;
    }

    var tSpan1 = (angle1 + _state.clipAngle).u32.s32;
    if (tSpan1 > 2 * _state.clipAngle) {
      tSpan1 -= 2 * _state.clipAngle;
      if (tSpan1 >= span) {
        return false;
      }
    }

    var tSpan2 = (_state.clipAngle - angle2).u32.s32;
    if (tSpan2 > 2 * _state.clipAngle) {
      tSpan2 -= 2 * _state.clipAngle;
      if (tSpan2 >= span) {
        return false;
      }
    }

    return true;
  }
}

typedef SegCallback = void Function(Seg seg, int start, int stop, int rwAngle1);
