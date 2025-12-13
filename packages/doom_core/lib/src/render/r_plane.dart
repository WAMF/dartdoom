import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';


class PlaneRenderer {
  PlaneRenderer(this._state, this._drawContext);

  final RenderState _state;
  final DrawContext _drawContext;

  final List<Visplane> _visplanes = [];
  Visplane? _floorPlane;
  Visplane? _ceilingPlane;

  int _planeHeight = 0;
  int _basexScale = 0;
  int _baseyScale = 0;

  final Int32List _spanStart = Int32List(ScreenDimensions.height);

  List<Uint8List?>? _planezLight;

  Uint8List? _frameBuffer;

  SkyCallback? onDrawSky;
  FlatCallback? onGetFlat;

  void clearPlanes() {
    _visplanes.clear();

    _floorPlane = Visplane(
      height: 0,
      picNum: 0,
      lightLevel: 0,
    );

    _ceilingPlane = Visplane(
      height: 0,
      picNum: 0,
      lightLevel: 0,
    );

    _visplanes
      ..add(_floorPlane!)
      ..add(_ceilingPlane!);
  }

  Visplane findPlane(int height, int picNum, int lightLevel) {
    var planeHeight = height;
    var planeLightLevel = lightLevel;

    if (picNum == _state.skyFlatNum) {
      planeHeight = 0;
      planeLightLevel = 0;
    }

    for (final plane in _visplanes) {
      if (plane.height == planeHeight &&
          plane.picNum == picNum &&
          plane.lightLevel == planeLightLevel) {
        return plane;
      }
    }

    if (_visplanes.length >= RenderConstants.maxVisplanes) {
      throw StateError('R_FindPlane: no more visplanes');
    }

    final plane = Visplane(
      height: planeHeight,
      picNum: picNum,
      lightLevel: planeLightLevel,
    );
    _visplanes.add(plane);
    return plane;
  }

  Visplane checkPlane(Visplane plane, int start, int stop) {
    int intrl;
    int intrh;
    int unionl;
    int unionh;

    if (start < plane.minX) {
      intrl = plane.minX;
      unionl = start;
    } else {
      unionl = plane.minX;
      intrl = start;
    }

    if (stop > plane.maxX) {
      intrh = plane.maxX;
      unionh = stop;
    } else {
      unionh = plane.maxX;
      intrh = stop;
    }

    var x = intrl;
    for (; x <= intrh; x++) {
      if (plane.top[x] != 0xff) {
        break;
      }
    }

    if (x > intrh) {
      plane.minX = unionl;
      plane.maxX = unionh;
      return plane;
    }

    final newPlane = Visplane(
      height: plane.height,
      picNum: plane.picNum,
      lightLevel: plane.lightLevel,
    )
      ..minX = start
      ..maxX = stop;

    _visplanes.add(newPlane);
    return newPlane;
  }

  void makeSpans(int x, int t1Param, int b1Param, int t2Param, int b2Param) {
    var t1 = t1Param;
    var b1 = b1Param;
    var t2 = t2Param;
    var b2 = b2Param;

    while (t1 < t2 && t1 <= b1) {
      _mapPlane(t1, _spanStart[t1], x - 1);
      t1++;
    }
    while (b1 > b2 && b1 >= t1) {
      _mapPlane(b1, _spanStart[b1], x - 1);
      b1--;
    }

    while (t2 < t1 && t2 <= b2) {
      _spanStart[t2] = x;
      t2++;
    }
    while (b2 > b1 && b2 >= t2) {
      _spanStart[b2] = x;
      b2--;
    }
  }

  void _mapPlane(int y, int x1, int x2) {
    if (x2 < x1 || y < 0 || y >= ScreenDimensions.height) return;
    if (_frameBuffer == null) return;

    final distance = Fixed32.mul(
      _planeHeight,
      _ySlope(y),
    );

    final length = Fixed32.mul(distance, _distScale(x1));

    final angle = (_state.viewAngle + _state.xToViewAngle[x1]).u32.s32;
    final fineAngle = (angle >> Angle.angleToFineShift) & Angle.fineMask;

    _drawContext.span
      ..y = y
      ..x1 = x1
      ..x2 = x2
      ..xFrac = _state.viewX +
          Fixed32.mul(fineCosine(fineAngle), length)
      ..yFrac = -_state.viewY -
          Fixed32.mul(fineSine(fineAngle), length)
      ..xStep = Fixed32.mul(distance, _basexScale)
      ..yStep = Fixed32.mul(distance, _baseyScale);

    if (_planezLight != null) {
      final index = (distance >> RenderConstants.lightZShift).clamp(0, RenderConstants.maxLightZ - 1);
      _drawContext.span.colormap = _planezLight![index];
    }

    _drawContext.drawSpan(_frameBuffer!);
  }

  int _ySlope(int y) {
    final dy = ((y - _state.centerY) << Fixed32.fracBits) + Fixed32.fracUnit ~/ 2;
    final numerator = (_state.viewWidth >> _state.detailShift) ~/ 2 * Fixed32.fracUnit;
    return Fixed32.div(numerator, dy.abs());
  }

  int _distScale(int x) {
    final angle = _state.xToViewAngle[x];
    final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
    return Fixed32.div(Fixed32.fracUnit, fineCosine(fineAngle).abs().clamp(1, Fixed32.fracUnit));
  }

  void drawPlanes(Uint8List frameBuffer) {
    _frameBuffer = frameBuffer;

    for (final plane in _visplanes) {
      if (plane.minX > plane.maxX) continue;

      if (plane.picNum == _state.skyFlatNum) {
        onDrawSky?.call(plane);
        continue;
      }

      _planeHeight = (plane.height - _state.viewZ).abs();

      final lightNum = (plane.lightLevel >> RenderConstants.lightSegShift) + _state.extraLight;
      _planezLight = _state.zLight[lightNum.clamp(0, RenderConstants.lightLevels - 1)];

      final flat = onGetFlat?.call(plane.picNum);
      if (flat != null) {
        _drawContext.span.source = flat;
      }

      _setupBaseScale();

      final stop = plane.maxX + 1;

      for (var x = plane.minX; x <= stop; x++) {
        var t1 = (x == plane.minX) ? 0xff : plane.top[x - 1];
        var b1 = (x == plane.minX) ? 0 : plane.bottom[x - 1];
        var t2 = x <= plane.maxX ? plane.top[x] : 0xff;
        var b2 = x <= plane.maxX ? plane.bottom[x] : 0;

        while (t1 < t2 && t1 <= b1) {
          _mapPlane(t1, _spanStart[t1], x - 1);
          t1++;
        }
        while (b1 > b2 && b1 >= t1) {
          _mapPlane(b1, _spanStart[b1], x - 1);
          b1--;
        }

        while (t2 < t1 && t2 <= b2) {
          _spanStart[t2] = x;
          t2++;
        }
        while (b2 > b1 && b2 >= t2) {
          _spanStart[b2] = x;
          b2--;
        }
      }
    }
  }

  void _setupBaseScale() {
    final angle = (_state.viewAngle - Angle.ang90).u32.s32;
    final fineAngle = (angle >> Angle.angleToFineShift) & Angle.fineMask;

    _basexScale = Fixed32.div(fineCosine(fineAngle), _state.centerXFrac);
    _baseyScale = -Fixed32.div(fineSine(fineAngle), _state.centerXFrac);
  }

  void checkFloorPlane(int start, int stop) {
    if (_floorPlane != null) {
      _floorPlane = checkPlane(_floorPlane!, start, stop);
      _state.floorPlane = _floorPlane;
    }
  }

  void checkCeilingPlane(int start, int stop) {
    if (_ceilingPlane != null) {
      _ceilingPlane = checkPlane(_ceilingPlane!, start, stop);
      _state.ceilingPlane = _ceilingPlane;
    }
  }

  void setFloorPlane(int x, int top, int bottom) {
    if (_floorPlane == null) return;
    if (bottom < top) return;
    if (x < 0 || x >= ScreenDimensions.width) return;

    if (x < _floorPlane!.minX) {
      _floorPlane!.minX = x;
    }
    if (x > _floorPlane!.maxX) {
      _floorPlane!.maxX = x;
    }

    _floorPlane!.top[x] = top;
    _floorPlane!.bottom[x] = bottom;
  }

  void setCeilingPlane(int x, int top, int bottom) {
    if (_ceilingPlane == null) return;
    if (bottom < top) return;
    if (x < 0 || x >= ScreenDimensions.width) return;

    if (x < _ceilingPlane!.minX) {
      _ceilingPlane!.minX = x;
    }
    if (x > _ceilingPlane!.maxX) {
      _ceilingPlane!.maxX = x;
    }

    _ceilingPlane!.top[x] = top;
    _ceilingPlane!.bottom[x] = bottom;
  }

  void enterSubsector(Sector sector) {
    if (sector.floorHeight < _state.viewZ) {
      _floorPlane = findPlane(
        sector.floorHeight,
        sector.floorPic,
        sector.lightLevel,
      );
      _state.floorPlane = _floorPlane;
    } else {
      _floorPlane = null;
      _state.floorPlane = null;
    }

    if (sector.ceilingHeight > _state.viewZ ||
        sector.ceilingPic == _state.skyFlatNum) {
      _ceilingPlane = findPlane(
        sector.ceilingHeight,
        sector.ceilingPic,
        sector.lightLevel,
      );
      _state.ceilingPlane = _ceilingPlane;
    } else {
      _ceilingPlane = null;
      _state.ceilingPlane = null;
    }
  }

  Visplane? get floorPlane => _floorPlane;
  Visplane? get ceilingPlane => _ceilingPlane;
  List<Visplane> get visplanes => _visplanes;
}

typedef SkyCallback = void Function(Visplane plane);
typedef FlatCallback = Uint8List? Function(int flatNum);
