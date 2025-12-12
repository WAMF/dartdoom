import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';

class PaletteConverter {
  PaletteConverter();

  Uint32List _rgbaLookup = Uint32List(256);

  void setPalette(DoomPalette palette) {
    _rgbaLookup = palette.toRgba32();
  }

  void convertFrame(Uint8List indexed, Uint8List rgba) {
    final pixels = rgba.buffer.asUint32List();
    for (var i = 0; i < indexed.length; i++) {
      pixels[i] = _rgbaLookup[indexed[i]];
    }
  }

  int getRgba(int colorIndex) => _rgbaLookup[colorIndex];
}
