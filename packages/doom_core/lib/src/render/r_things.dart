import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_segs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _SpriteConstants {
  static const int minZ = Fixed32.fracUnit * 4;
}

class SpriteRenderer {
  SpriteRenderer(this._state, this._drawContext, this._segRenderer);

  final RenderState _state;
  final DrawContext _drawContext;
  final SegRenderer _segRenderer;

  final List<Vissprite> _vissprites = [];
  Vissprite? _visspriteHead;
  Vissprite? _visspriteTail;

  Int16List _clipBot = Int16List(0);
  Int16List _clipTop = Int16List(0);
  Int16List _spriteClipBot = Int16List(0);
  Int16List _spriteClipTop = Int16List(0);

  SpriteDataCallback? onGetSpriteData;
  MaskedColumnCallback? onDrawMaskedColumn;

  void initClipArrays(int width) {
    _clipBot = Int16List(width);
    _clipTop = Int16List(width);
    _spriteClipBot = Int16List(width);
    _spriteClipTop = Int16List(width);
  }

  void clearSprites() {
    _vissprites.clear();
    _visspriteHead = null;
    _visspriteTail = null;
  }

  void addSprite(
    int x,
    int y,
    int z,
    int angle,
    int spriteNum,
    int frame,
    int mobjFlags,
    int lightLevel,
  ) {
    final tr = _transformPoint(x, y);
    if (tr.tz < _SpriteConstants.minZ) return;

    final xScale = Fixed32.div(_state.projection, tr.tz);
    final gzt = z + _getSpriteTopOffset(spriteNum, frame, angle);

    final x1 = _state.centerX + Fixed32.toInt(Fixed32.mul(tr.tx, xScale));
    if (x1 >= _state.viewWidth) return;

    final x2 = _state.centerX +
        Fixed32.toInt(Fixed32.mul(tr.tx + _getSpriteWidth(spriteNum, frame, angle), xScale));
    if (x2 < 0) return;

    final vis = Vissprite()
      ..x1 = x1.clamp(0, _state.viewWidth - 1)
      ..x2 = x2.clamp(0, _state.viewWidth - 1)
      ..gx = x
      ..gy = y
      ..gz = z
      ..gzt = gzt
      ..scale = xScale
      ..xiscale = Fixed32.div(Fixed32.fracUnit, xScale)
      ..textureMid = gzt - _state.viewZ
      ..patch = _getSpritePatch(spriteNum, frame, angle)
      ..mobjFlags = mobjFlags;

    _setupSpriteLight(vis, lightLevel);
    _addToSortedList(vis);
    _vissprites.add(vis);
  }

  _TransformResult _transformPoint(int x, int y) {
    final dx = x - _state.viewX;
    final dy = y - _state.viewY;

    final tx = Fixed32.mul(dx, _state.viewCos) -
        Fixed32.mul(dy, _state.viewSin);
    final tz = Fixed32.mul(dx, _state.viewSin) +
        Fixed32.mul(dy, _state.viewCos);

    return _TransformResult(tx, tz);
  }

  void _setupSpriteLight(Vissprite vis, int lightLevel) {
    if (_state.fixedColormap != null) {
      vis.colormap = _state.fixedColormap;
    } else {
      final index = (vis.scale >> RenderConstants.lightScaleShift).clamp(0, RenderConstants.maxLightScale - 1);
      final lightNum = (lightLevel >> RenderConstants.lightSegShift) + _state.extraLight;
      vis.colormap = _state.scaleLight[lightNum.clamp(0, RenderConstants.lightLevels - 1)][index];
    }
  }

  void _addToSortedList(Vissprite vis) {
    if (_visspriteHead == null) {
      _visspriteHead = vis;
      _visspriteTail = vis;
      return;
    }

    var current = _visspriteHead;
    while (current != null && current.scale > vis.scale) {
      current = current.next;
    }

    if (current == null) {
      vis.prev = _visspriteTail;
      _visspriteTail!.next = vis;
      _visspriteTail = vis;
    } else if (current == _visspriteHead) {
      vis.next = _visspriteHead;
      _visspriteHead!.prev = vis;
      _visspriteHead = vis;
    } else {
      vis
        ..prev = current.prev
        ..next = current;
      current.prev!.next = vis;
      current.prev = vis;
    }
  }

  int _getSpriteWidth(int spriteNum, int frame, int angle) {
    if (spriteNum < _state.spriteWidth.length) {
      return _state.spriteWidth[spriteNum];
    }
    return 0;
  }

  int _getSpriteTopOffset(int spriteNum, int frame, int angle) {
    if (spriteNum < _state.spriteTopOffset.length) {
      return _state.spriteTopOffset[spriteNum];
    }
    return 0;
  }

  int _getSpritePatch(int spriteNum, int frame, int angle) {
    if (spriteNum < _state.sprites.length) {
      final spriteDef = _state.sprites[spriteNum];
      if (frame < spriteDef.numFrames) {
        final spriteFrame = spriteDef.spriteFrames[frame];
        if (spriteFrame.rotate) {
          final rot = ((angle - Angle.ang90) >> 29) & 7;
          return spriteFrame.lump[rot];
        }
        return spriteFrame.lump[0];
      }
    }
    return 0;
  }

  void drawMasked(Uint8List frameBuffer) {
    _drawMaskedTextures(frameBuffer);
    _drawSprites(frameBuffer);
  }

  void _drawMaskedTextures(Uint8List frameBuffer) {
    for (final ds in _segRenderer.drawSegs.reversed) {
      if (ds.maskedTextureCol == null) continue;

      final seg = ds.curLine;
      final midTexture = seg.sidedef.midTexture;
      if (midTexture == 0) continue;

      onDrawMaskedColumn?.call(ds, frameBuffer);
    }
  }

  void _drawSprites(Uint8List frameBuffer) {
    _initClipArrays();

    var vis = _visspriteHead;
    while (vis != null) {
      _drawVissprite(vis, frameBuffer);
      vis = vis.next;
    }
  }

  void _initClipArrays() {
    for (var i = 0; i < _state.viewWidth; i++) {
      _clipBot[i] = _state.viewHeight;
      _clipTop[i] = -1;
    }

    for (final ds in _segRenderer.drawSegs) {
      if (ds.silhouette == Silhouette.none) continue;

      if ((ds.silhouette & Silhouette.bottom) != 0) {
        for (var x = ds.x1; x <= ds.x2; x++) {
          if (_clipBot[x] > ds.sprBottomClip![x]) {
            _clipBot[x] = ds.sprBottomClip![x];
          }
        }
      }

      if ((ds.silhouette & Silhouette.top) != 0) {
        for (var x = ds.x1; x <= ds.x2; x++) {
          if (_clipTop[x] < ds.sprTopClip![x]) {
            _clipTop[x] = ds.sprTopClip![x];
          }
        }
      }
    }
  }

  void _drawVissprite(Vissprite vis, Uint8List frameBuffer) {
    final spriteData = onGetSpriteData?.call(vis.patch);
    if (spriteData == null) return;

    for (var x = vis.x1; x <= vis.x2; x++) {
      _spriteClipBot[x] = _clipBot[x];
      _spriteClipTop[x] = _clipTop[x];
    }

    for (final ds in _segRenderer.drawSegs) {
      if (ds.x1 > vis.x2 || ds.x2 < vis.x1) continue;
      if (ds.scale1 > vis.scale && ds.scale2 > vis.scale) continue;

      final r1 = ds.x1 < vis.x1 ? vis.x1 : ds.x1;
      final r2 = ds.x2 > vis.x2 ? vis.x2 : ds.x2;

      var scale = ds.scale1 + ds.scaleStep * (r1 - ds.x1);
      for (var x = r1; x <= r2; x++) {
        if (scale > vis.scale) {
          if (ds.sprTopClip != null && _spriteClipTop[x] < ds.sprTopClip![x]) {
            _spriteClipTop[x] = ds.sprTopClip![x];
          }
          if (ds.sprBottomClip != null && _spriteClipBot[x] > ds.sprBottomClip![x]) {
            _spriteClipBot[x] = ds.sprBottomClip![x];
          }
        }
        scale += ds.scaleStep;
      }
    }

    _drawSpriteColumns(vis, spriteData, frameBuffer);
  }

  void _drawSpriteColumns(Vissprite vis, Uint8List spriteData, Uint8List frameBuffer) {
    final column = _drawContext.column..colormap = vis.colormap;

    var frac = vis.startFrac;
    for (var x = vis.x1; x <= vis.x2; x++) {
      final textureCol = frac >> Fixed32.fracBits;

      column
        ..x = x
        ..yl = ((_state.centerYFrac - Fixed32.mul(vis.textureMid, vis.scale)) >> Fixed32.fracBits)
            .clamp(_spriteClipTop[x] + 1, _state.viewHeight - 1)
        ..yh = ((_state.centerYFrac + Fixed32.mul(vis.gz - _state.viewZ - vis.textureMid, vis.scale)) >> Fixed32.fracBits)
            .clamp(0, _spriteClipBot[x] - 1)
        ..iscale = vis.xiscale
        ..textureMid = vis.textureMid;

      if (column.yl <= column.yh && textureCol >= 0) {
        column.source = _getSpriteColumn(spriteData, textureCol);
        _drawContext.drawColumn(frameBuffer);
      }

      frac += vis.xiscale;
    }
  }

  Uint8List _getSpriteColumn(Uint8List spriteData, int col) {
    return Uint8List(128);
  }

  List<Vissprite> get vissprites => _vissprites;
}

class _TransformResult {
  _TransformResult(this.tx, this.tz);
  final int tx;
  final int tz;
}

typedef SpriteDataCallback = Uint8List? Function(int patchNum);
typedef MaskedColumnCallback = void Function(DrawSeg ds, Uint8List frameBuffer);
