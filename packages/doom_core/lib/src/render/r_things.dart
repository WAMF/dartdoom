import 'dart:typed_data';

import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_segs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

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
    _totalThingsProcessed = 0;
  }

  void addSprites(Sector sector) {
    if (sector.validCount == _state.validCount) {
      return;
    }
    sector.validCount = _state.validCount;

    final lightNum = (sector.lightLevel >> RenderConstants.lightSegShift) + _state.extraLight;
    _spriteLights = _state.scaleLight[lightNum.clamp(0, RenderConstants.lightLevels - 1)];

    var thingCount = 0;
    var thing = sector.thingList;
    while (thing != null) {
      thingCount++;
      _projectSprite(thing);
      thing = thing.sNext;
    }
    _totalThingsProcessed += thingCount;
  }

  int _totalThingsProcessed = 0;
  int get totalThingsProcessed => _totalThingsProcessed;

  List<Uint8List?> _spriteLights = [];

  void _projectSprite(Mobj thing) {
    final trX = thing.x - _state.viewX;
    final trY = thing.y - _state.viewY;

    final gxt = Fixed32.mul(trX, _state.viewCos);
    final gyt = -Fixed32.mul(trY, _state.viewSin);

    final tz = gxt - gyt;

    if (tz < _SpriteConstants.minZ) {
      return;
    }

    final xScale = Fixed32.div(_state.projection, tz);

    final gxtNeg = -Fixed32.mul(trX, _state.viewSin);
    final gytPos = Fixed32.mul(trY, _state.viewCos);
    var tx = -(gytPos + gxtNeg);

    if (tx.abs() > tz << 2) {
      return;
    }

    final spriteNum = thing.sprite;
    final frameNum = thing.frame & FrameFlag.frameMask;

    if (spriteNum >= _state.sprites.length) {
      return;
    }
    final sprdef = _state.sprites[spriteNum];
    if (frameNum >= sprdef.numFrames) {
      return;
    }
    final sprframe = sprdef.spriteFrames[frameNum];

    int lump;
    bool flip;

    if (sprframe.rotate) {
      final ang = _pointToAngle(thing.x, thing.y);
      final rot = ((ang - thing.angle + (Angle.ang45 >> 1) * 9).u32 >> 29) & 7;
      lump = sprframe.lump[rot];
      flip = sprframe.flip[rot] != 0;
    } else {
      lump = sprframe.lump[0];
      flip = sprframe.flip[0] != 0;
    }

    if (lump >= _state.spriteWidth.length || lump >= _state.spriteOffset.length) {
      return;
    }

    tx -= _state.spriteOffset[lump];
    final x1 = (_state.centerXFrac + Fixed32.mul(tx, xScale)) >> Fixed32.fracBits;

    if (x1 > _state.viewWidth) {
      return;
    }

    tx += _state.spriteWidth[lump];
    final x2 = ((_state.centerXFrac + Fixed32.mul(tx, xScale)) >> Fixed32.fracBits) - 1;

    if (x2 < 0) {
      return;
    }

    final vis = Vissprite()
      ..mobjFlags = thing.flags
      ..scale = xScale
      ..gx = thing.x
      ..gy = thing.y
      ..gz = thing.z
      ..gzt = thing.z + _state.spriteTopOffset[lump]
      ..textureMid = thing.z + _state.spriteTopOffset[lump] - _state.viewZ
      ..x1 = x1 < 0 ? 0 : x1
      ..x2 = x2 >= _state.viewWidth ? _state.viewWidth - 1 : x2;

    final iscale = Fixed32.div(Fixed32.fracUnit, xScale);

    if (flip) {
      vis
        ..startFrac = _state.spriteWidth[lump] - 1
        ..xiscale = -iscale;
    } else {
      vis
        ..startFrac = 0
        ..xiscale = iscale;
    }

    if (vis.x1 > x1) {
      vis.startFrac += vis.xiscale * (vis.x1 - x1);
    }

    vis.patch = lump;

    if ((thing.flags & MobjFlag.shadow) != 0) {
      vis.colormap = null;
    } else if (_state.fixedColormap != null) {
      vis.colormap = _state.fixedColormap;
    } else if ((thing.frame & FrameFlag.fullBright) != 0) {
      vis.colormap = _state.colormaps;
    } else {
      final index = (xScale >> RenderConstants.lightScaleShift).clamp(0, RenderConstants.maxLightScale - 1);
      vis.colormap = _spriteLights[index];
    }

    _addToSortedList(vis);
    _vissprites.add(vis);
  }

  int _pointToAngle(int x, int y) {
    final dx = x - _state.viewX;
    final dy = y - _state.viewY;

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

      if ((ds.silhouette & Silhouette.bottom) != 0 && ds.sprBottomClip != null) {
        for (var x = ds.x1; x <= ds.x2; x++) {
          if (_clipBot[x] > ds.sprBottomClip![x]) {
            _clipBot[x] = ds.sprBottomClip![x];
          }
        }
      }

      if ((ds.silhouette & Silhouette.top) != 0 && ds.sprTopClip != null) {
        for (var x = ds.x1; x <= ds.x2; x++) {
          if (_clipTop[x] < ds.sprTopClip![x]) {
            _clipTop[x] = ds.sprTopClip![x];
          }
        }
      }
    }
  }

  int _drawCallCount = 0;
  int get drawCallCount => _drawCallCount;

  void _drawVissprite(Vissprite vis, Uint8List frameBuffer) {
    _drawCallCount++;
    final spriteData = onGetSpriteData?.call(vis.patch);
    if (spriteData == null) {
      return;
    }

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

  int _columnsDrawn = 0;
  int get columnsDrawn => _columnsDrawn;

  void _drawSpriteColumns(Vissprite vis, Uint8List spriteData, Uint8List frameBuffer) {
    final patch = _getPatchFromCache(spriteData);
    if (patch == null) return;

    final column = _drawContext.column..colormap = vis.colormap;

    final sprtopscreen = _state.centerYFrac - Fixed32.mul(vis.textureMid, vis.scale);

    var frac = vis.startFrac;
    for (var x = vis.x1; x <= vis.x2; x++) {
      final textureCol = frac >> Fixed32.fracBits;

      if (textureCol >= 0 && textureCol < patch.width) {
        _drawMaskedColumn(
          column,
          patch,
          textureCol,
          x,
          sprtopscreen,
          vis.scale,
          _spriteClipTop[x],
          _spriteClipBot[x],
          frameBuffer,
        );
      }

      frac += vis.xiscale;
    }
  }

  void _drawMaskedColumn(
    ColumnDrawer column,
    Patch patch,
    int textureCol,
    int x,
    int sprtopscreen,
    int spryscale,
    int clipTop,
    int clipBot,
    Uint8List frameBuffer,
  ) {
    final posts = patch.columns[textureCol];
    if (posts.isEmpty) return;

    column.x = x;

    for (final post in posts) {
      final topscreen = sprtopscreen + Fixed32.mul(post.topDelta.toFixed(), spryscale);
      final bottomscreen = topscreen + Fixed32.mul(post.pixels.length.toFixed(), spryscale);

      var yl = (topscreen + Fixed32.fracUnit - 1) >> Fixed32.fracBits;
      var yh = (bottomscreen - 1) >> Fixed32.fracBits;

      if (yl <= clipTop) yl = clipTop + 1;
      if (yh >= clipBot) yh = clipBot - 1;

      if (yl > yh) continue;

      column
        ..yl = yl
        ..yh = yh
        ..iscale = Fixed32.div(Fixed32.fracUnit, spryscale)
        ..textureMid = post.topDelta.toFixed()
        ..source = Uint8List.fromList(post.pixels);

      _columnsDrawn++;
      _drawContext.drawColumn(frameBuffer);
    }
  }

  Patch? _getPatchFromCache(Uint8List spriteData) {
    if (spriteData.isEmpty) return null;

    final cacheKey = spriteData.hashCode;
    var patch = _spriteCache[cacheKey];
    if (patch == null) {
      try {
        patch = Patch.parse(spriteData);
        _spriteCache[cacheKey] = patch;
      } catch (e) {
        return null;
      }
    }
    return patch;
  }

  final Map<int, Patch> _spriteCache = {};

  List<Vissprite> get vissprites => _vissprites;
}

class _TransformResult {
  _TransformResult(this.tx, this.tz);
  final int tx;
  final int tz;
}

typedef SpriteDataCallback = Uint8List? Function(int patchNum);
typedef MaskedColumnCallback = void Function(DrawSeg ds, Uint8List frameBuffer);
