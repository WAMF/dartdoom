import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _SegConstants {
  static const int heightBits = 12;
  static const int heightUnit = 1 << heightBits;
}

class SegRenderer {
  SegRenderer(this._state, this._renderer, this._drawContext);

  final RenderState _state;
  final Renderer _renderer;
  final DrawContext _drawContext;

  final List<DrawSeg> drawSegs = [];

  PlaneCallback? onFloorPlane;
  PlaneCallback? onCeilingPlane;
  PlaneCheckCallback? onCheckFloorPlane;
  PlaneCheckCallback? onCheckCeilingPlane;

  Int16List _floorClip = Int16List(0);
  Int16List _ceilingClip = Int16List(0);

  Seg? _curLine;
  Side? _curSide;
  Line? _curLinedef;
  Sector? _frontSector;
  Sector? _backSector;

  int _rwX = 0;
  int _rwStopX = 0;
  int _rwAngle1 = 0;

  int _rwScale = 0;
  int _rwScaleStep = 0;
  int _rwMidTextureMid = 0;
  int _rwTopTextureMid = 0;
  int _rwBottomTextureMid = 0;

  int _worldTop = 0;
  int _worldBottom = 0;
  int _worldHigh = 0;
  int _worldLow = 0;

  int _pixHigh = 0;
  int _pixLow = 0;
  int _pixHighStep = 0;
  int _pixLowStep = 0;

  int _topFrac = 0;
  int _topStep = 0;
  int _bottomFrac = 0;
  int _bottomStep = 0;

  int _midTexture = 0;
  int _topTexture = 0;
  int _bottomTexture = 0;

  bool _markFloor = false;
  bool _markCeiling = false;
  bool _maskedTexture = false;

  int _rwNormalAngleVal = 0;
  int _rwCenterAngle = 0;
  int _rwOffset = 0;
  int _rwDistance = 0;

  List<Uint8List?>? _wallLights;

  void initClipArrays(int width) {
    _floorClip = Int16List(width);
    _ceilingClip = Int16List(width);
  }

  void clearClips(int height) {
    for (var i = 0; i < _floorClip.length; i++) {
      _floorClip[i] = height;
      _ceilingClip[i] = -1;
    }
  }

  void clearDrawSegs() {
    drawSegs.clear();
  }

  void storeWallRange(Seg seg, int start, int stop, int rwAngle1) {
    _curLine = seg;
    _curSide = seg.sidedef;
    _curLinedef = seg.linedef;
    _frontSector = seg.frontSector;
    _backSector = seg.backSector;

    _rwX = start;
    _rwStopX = stop;
    _rwAngle1 = rwAngle1;

    _calculateScales();
    _setupTextures();
    _setupMarking();
    _openPlanes();

    if (_backSector == null) {
      _renderSolidWall();
    } else {
      _renderTwoSidedWall();
    }
  }

  void _calculateScales() {
    final seg = _curLine!;
    final v1 = seg.v1;

    _rwNormalAngle();

    var offsetAngle = (_rwAngle1 - _rwNormalAngleVal).abs().u32.s32;
    if (offsetAngle > Angle.ang90) {
      offsetAngle = Angle.ang90;
    }
    final offsetFineAngle =
        (offsetAngle >> Angle.angleToFineShift) & Angle.fineMask;
    _rwOffset = Fixed32.mul(
      _hypotenuse(
        _state.viewX - v1.x,
        _state.viewY - v1.y,
      ),
      fineSine(offsetFineAngle),
    );

    _rwOffset += seg.offset + _curSide!.textureOffset;

    var offsetAngleForDist = (_rwNormalAngleVal - _rwAngle1).u32;
    final hypotenuse = _hypotenuse(_state.viewX - v1.x, _state.viewY - v1.y);

    if (offsetAngleForDist.u32 < Angle.ang180.u32) {
      offsetAngleForDist = (Angle.ang90 - offsetAngleForDist.s32).u32;
    } else {
      offsetAngleForDist = (Angle.ang90 + offsetAngleForDist.s32).u32;
    }

    final distAngle = (offsetAngleForDist >> Angle.angleToFineShift) & Angle.fineMask;
    _rwDistance = Fixed32.mul(hypotenuse, fineSine(distAngle).abs());

    _state.rwDistance = _rwDistance;
    _state.rwNormalAngle = _rwNormalAngleVal;

    _rwScale = _renderer.scaleFromGlobalAngle(
      (_state.viewAngle + _state.xToViewAngle[_rwX]).u32.s32,
    );

    if (_rwStopX > _rwX) {
      final scale2 = _renderer.scaleFromGlobalAngle(
        (_state.viewAngle + _state.xToViewAngle[_rwStopX]).u32.s32,
      );
      _rwScaleStep = (scale2 - _rwScale) ~/ (_rwStopX - _rwX);
    } else {
      _rwScaleStep = 0;
    }

    _worldTop = _frontSector!.ceilingHeight - _state.viewZ;
    _worldBottom = _frontSector!.floorHeight - _state.viewZ;

    final scaledWorldTop = _worldTop >> 4;
    final scaledWorldBottom = _worldBottom >> 4;

    _topFrac = (_state.centerYFrac >> 4) -
        Fixed32.mul(scaledWorldTop, _rwScale);
    _topStep = -Fixed32.mul(_rwScaleStep, scaledWorldTop);

    _bottomFrac = (_state.centerYFrac >> 4) -
        Fixed32.mul(scaledWorldBottom, _rwScale);
    _bottomStep = -Fixed32.mul(_rwScaleStep, scaledWorldBottom);
  }

  void _rwNormalAngle() {
    _rwNormalAngleVal = (_curLine!.angle + Angle.ang90).u32.s32;
    _rwCenterAngle = (Angle.ang90 + _state.viewAngle - _rwNormalAngleVal).u32.s32;
  }

  int _hypotenuse(int dx, int dy) {
    final adx = dx.abs();
    final ady = dy.abs();
    if (adx > ady) {
      return adx + (ady >> 1);
    }
    return ady + (adx >> 1);
  }

  void _setupTextures() {
    final side = _curSide!;

    _midTexture = 0;
    _topTexture = 0;
    _bottomTexture = 0;
    _maskedTexture = false;

    if (_backSector == null) {
      _midTexture = _state.textureTranslation[side.midTexture];
      _rwMidTextureMid = side.rowOffset;

      if ((_curLinedef!.flags & LineFlags.dontPegBottom) != 0) {
        _rwMidTextureMid += _frontSector!.floorHeight - _state.viewZ;
      } else {
        _rwMidTextureMid += _frontSector!.ceilingHeight - _state.viewZ;
      }
    } else {
      if (_frontSector!.ceilingHeight > _backSector!.ceilingHeight) {
        _topTexture = _state.textureTranslation[side.topTexture];
        _rwTopTextureMid = side.rowOffset;

        if ((_curLinedef!.flags & LineFlags.dontPegTop) != 0) {
          _rwTopTextureMid += _frontSector!.ceilingHeight - _state.viewZ;
        } else {
          _rwTopTextureMid += _backSector!.ceilingHeight - _state.viewZ;
        }
      }

      if (_frontSector!.floorHeight < _backSector!.floorHeight) {
        _bottomTexture = _state.textureTranslation[side.bottomTexture];
        _rwBottomTextureMid = side.rowOffset;

        if ((_curLinedef!.flags & LineFlags.dontPegBottom) != 0) {
          _rwBottomTextureMid += _frontSector!.ceilingHeight - _state.viewZ;
        } else {
          _rwBottomTextureMid += _backSector!.floorHeight - _state.viewZ;
        }
      }

      if (side.midTexture != 0) {
        _maskedTexture = true;
      }
    }
  }

  void _setupMarking() {
    if (_backSector == null) {
      _markFloor = true;
      _markCeiling = true;
    } else {
      final worldHigh = _backSector!.ceilingHeight - _state.viewZ;
      final worldLow = _backSector!.floorHeight - _state.viewZ;
      var worldTop = _frontSector!.ceilingHeight - _state.viewZ;
      final worldBottom = _frontSector!.floorHeight - _state.viewZ;

      if (_frontSector!.ceilingPic == _state.skyFlatNum &&
          _backSector!.ceilingPic == _state.skyFlatNum) {
        worldTop = worldHigh;
      }

      if (worldLow != worldBottom ||
          _backSector!.floorPic != _frontSector!.floorPic ||
          _backSector!.lightLevel != _frontSector!.lightLevel) {
        _markFloor = true;
      } else {
        _markFloor = false;
      }

      if (worldHigh != worldTop ||
          _backSector!.ceilingPic != _frontSector!.ceilingPic ||
          _backSector!.lightLevel != _frontSector!.lightLevel) {
        _markCeiling = true;
      } else {
        _markCeiling = false;
      }

      if (_backSector!.ceilingHeight <= _frontSector!.floorHeight ||
          _backSector!.floorHeight >= _frontSector!.ceilingHeight) {
        _markCeiling = true;
        _markFloor = true;
      }

      if (_frontSector!.floorHeight >= _state.viewZ) {
        _markFloor = false;
      }

      if (_frontSector!.ceilingHeight <= _state.viewZ &&
          _frontSector!.ceilingPic != _state.skyFlatNum) {
        _markCeiling = false;
      }
    }

    _setupLighting();
  }

  void _setupLighting() {
    var lightNum = (_frontSector!.lightLevel >> RenderConstants.lightSegShift) + _state.extraLight;

    if (_curLine!.v1.y == _curLine!.v2.y) {
      lightNum--;
    } else if (_curLine!.v1.x == _curLine!.v2.x) {
      lightNum++;
    }

    final clampedLight = lightNum.clamp(0, RenderConstants.lightLevels - 1);
    _wallLights = _state.scaleLight[clampedLight];
  }

  void _openPlanes() {
    if (_markFloor) {
      onCheckFloorPlane?.call(_rwX, _rwStopX);
    }

    if (_markCeiling) {
      onCheckCeilingPlane?.call(_rwX, _rwStopX);
    }
  }

  void _renderSolidWall() {
    _createDrawSeg(Silhouette.both);
    _renderSegLoop();
  }

  void _renderTwoSidedWall() {
    _worldHigh = _backSector!.ceilingHeight - _state.viewZ;
    _worldLow = _backSector!.floorHeight - _state.viewZ;

    final scaledWorldHigh = _worldHigh >> 4;
    final scaledWorldLow = _worldLow >> 4;

    _pixHigh = (_state.centerYFrac >> 4) - Fixed32.mul(scaledWorldHigh, _rwScale);
    _pixHighStep = -Fixed32.mul(_rwScaleStep, scaledWorldHigh);

    _pixLow = (_state.centerYFrac >> 4) - Fixed32.mul(scaledWorldLow, _rwScale);
    _pixLowStep = -Fixed32.mul(_rwScaleStep, scaledWorldLow);

    var silhouette = Silhouette.none;
    if (_frontSector!.floorHeight > _backSector!.floorHeight) {
      silhouette |= Silhouette.bottom;
    } else if (_backSector!.floorHeight > _state.viewZ) {
      silhouette |= Silhouette.bottom;
    }

    if (_frontSector!.ceilingHeight < _backSector!.ceilingHeight) {
      silhouette |= Silhouette.top;
    } else if (_backSector!.ceilingHeight < _state.viewZ) {
      silhouette |= Silhouette.top;
    }

    _createDrawSeg(silhouette);
    _renderSegLoop();
  }

  void _createDrawSeg(int silhouette) {
    final ds = DrawSeg(
      curLine: _curLine!,
      x1: _rwX,
      x2: _rwStopX,
      scale1: _rwScale,
      scale2: _rwScale + _rwScaleStep * (_rwStopX - _rwX),
      scaleStep: _rwScaleStep,
      silhouette: silhouette,
      bsilHeight: silhouette & Silhouette.bottom != 0 ? _frontSector!.floorHeight : 0,
      tsilHeight: silhouette & Silhouette.top != 0 ? _frontSector!.ceilingHeight : 0,
    );

    if (_maskedTexture) {
      ds.maskedTextureCol = Int16List(_rwStopX - _rwX + 1);
    }

    drawSegs.add(ds);
  }

  void _renderSegLoop() {
    var rwScaleCurrent = _rwScale;
    var topFracCurrent = _topFrac;
    var bottomFracCurrent = _bottomFrac;
    var pixHighCurrent = _pixHigh;
    var pixLowCurrent = _pixLow;

    for (var x = _rwX; x <= _rwStopX; x++) {
      final top = (topFracCurrent + _SegConstants.heightUnit - 1) >> _SegConstants.heightBits;
      final bottom = bottomFracCurrent >> _SegConstants.heightBits;

      final yl = top.clamp(_ceilingClip[x] + 1, _state.viewHeight);
      final yh = bottom.clamp(-1, _floorClip[x] - 1);

      if (_markCeiling) {
        final ceilTop = _ceilingClip[x] + 1;
        var ceilBottom = yl - 1;
        if (ceilBottom >= _floorClip[x]) {
          ceilBottom = _floorClip[x] - 1;
        }
        if (ceilTop <= ceilBottom) {
          onCeilingPlane?.call(x, ceilTop, ceilBottom);
        }
      }

      if (_markFloor) {
        var floorTop = yh + 1;
        final floorBottom = _floorClip[x] - 1;
        if (floorTop <= _ceilingClip[x]) {
          floorTop = _ceilingClip[x] + 1;
        }
        if (floorTop <= floorBottom) {
          onFloorPlane?.call(x, floorTop, floorBottom);
        }
      }

      if (_backSector == null) {
        if (_midTexture != 0 && yl <= yh) {
          _drawColumn(x, yl, yh, _midTexture, _rwMidTextureMid, rwScaleCurrent);
        }
        _ceilingClip[x] = _state.viewHeight;
        _floorClip[x] = -1;
      } else {
        var midYl = yl;
        var midYh = yh;

        if (_topTexture != 0) {
          final mid = pixHighCurrent >> _SegConstants.heightBits;
          if (mid >= _floorClip[x]) {
            midYl = _floorClip[x];
          } else if (mid > _ceilingClip[x]) {
            if (mid > yl) {
              _drawColumn(x, yl, mid - 1, _topTexture, _rwTopTextureMid, rwScaleCurrent);
            }
            midYl = mid;
          }
        }

        if (_bottomTexture != 0) {
          final mid = (pixLowCurrent + _SegConstants.heightUnit - 1) >> _SegConstants.heightBits;
          if (mid <= _ceilingClip[x]) {
            midYh = _ceilingClip[x];
          } else if (mid < _floorClip[x]) {
            if (mid < yh) {
              _drawColumn(x, mid + 1, yh, _bottomTexture, _rwBottomTextureMid, rwScaleCurrent);
            }
            midYh = mid;
          }
        }

        if (_markCeiling) {
          _ceilingClip[x] = midYl.clamp(0, _state.viewHeight - 1);
        }
        if (_markFloor) {
          _floorClip[x] = midYh.clamp(0, _state.viewHeight - 1);
        }

        pixHighCurrent += _pixHighStep;
        pixLowCurrent += _pixLowStep;
      }

      rwScaleCurrent += _rwScaleStep;
      topFracCurrent += _topStep;
      bottomFracCurrent += _bottomStep;
    }
  }

  void _drawColumn(
    int x,
    int yl,
    int yh,
    int textureNum,
    int textureMid,
    int scale,
  ) {
    if (yl > yh) return;

    final angle = (_rwCenterAngle + _state.xToViewAngle[x]).u32.s32;
    final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
    final textureCol = Fixed32.toInt(
      _rwOffset - Fixed32.mul(fineTangent(fineAngle), _rwDistance),
    );
    final index = (scale >> RenderConstants.lightScaleShift).clamp(0, RenderConstants.maxLightScale - 1);

    _drawContext.column
      ..x = x
      ..yl = yl
      ..yh = yh
      ..iscale = Fixed32.div(Fixed32.fracUnit, scale)
      ..textureMid = textureMid
      ..source = _getTextureColumn(textureNum, textureCol)
      ..colormap = _wallLights?[index] ?? _state.colormaps?.sublist(0, 256);

    _drawContext.drawColumn(_renderer.frameBuffer!);
  }

  Uint8List _getTextureColumn(int textureNum, int col) {
    final texManager = _state.textureManager;
    if (texManager == null) {
      return _emptyColumn;
    }
    return texManager.getTextureColumn(textureNum, col);
  }

  static final Uint8List _emptyColumn = Uint8List(128);
}

typedef PlaneCallback = void Function(int x, int top, int bottom);
typedef PlaneCheckCallback = void Function(int start, int stop);
