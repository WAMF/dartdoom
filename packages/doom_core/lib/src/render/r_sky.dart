import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _SkyConstants {
  static const int textureWidth = 256;
  static const int textureMid = 100 * Fixed32.fracUnit;
  static const int angleToSkyShift = 22;
}

class SkyRenderer {
  SkyRenderer(this._state, this._drawContext);

  final RenderState _state;
  final DrawContext _drawContext;

  int _skyTexture = 0;
  int _skyColumnOffset = 0;
  int _skyTextureMid = 0;

  Uint8List? _frameBuffer;
  SkyTextureCallback? onGetSkyTexture;

  void init() {
    _skyTexture = _state.skyTexture;
    _skyColumnOffset = _state.skyColumnOffset;
    _skyTextureMid = _SkyConstants.textureMid;
  }

  void setSkyTexture(int texture) {
    _skyTexture = texture;
    _state.skyTexture = texture;
  }

  void setSkyColumnOffset(int offset) {
    _skyColumnOffset = offset;
    _state.skyColumnOffset = offset;
  }

  void drawSky(Visplane plane, Uint8List frameBuffer) {
    _frameBuffer = frameBuffer;

    if (plane.minX > plane.maxX) return;

    for (var x = plane.minX; x <= plane.maxX; x++) {
      final yl = plane.top[x];
      final yh = plane.bottom[x];

      if (yl > yh) continue;
      if (yl == 0xff) continue;

      final angle = (_state.viewAngle + _state.xToViewAngle[x]).u32;
      final col = ((angle + _skyColumnOffset) >> _SkyConstants.angleToSkyShift) & (_SkyConstants.textureWidth - 1);

      _drawSkyColumn(x, yl, yh, col);
    }
  }

  void _drawSkyColumn(int x, int yl, int yh, int textureCol) {
    final skyData = onGetSkyTexture?.call(_skyTexture, textureCol);
    if (skyData == null || _frameBuffer == null) return;

    _drawContext.column
      ..x = x
      ..yl = yl
      ..yh = yh
      ..iscale = Fixed32.fracUnit
      ..textureMid = _skyTextureMid
      ..source = skyData
      ..colormap = _state.colormaps?.sublist(0, 256);

    _drawContext.drawColumn(_frameBuffer!);
  }

  int get skyTexture => _skyTexture;
  int get skyColumnOffset => _skyColumnOffset;
}

typedef SkyTextureCallback = Uint8List? Function(int texture, int col);
