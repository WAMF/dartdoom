import 'dart:typed_data';

abstract final class _PaletteConstants {
  static const int numColors = 256;
  static const int colormapSize = 256;
  static const int paletteSize = numColors * 3;
}

class DoomPalette {

  DoomPalette(this._rgb) {
    if (_rgb.length != _PaletteConstants.paletteSize) {
      throw ArgumentError(
        'Palette must have ${_PaletteConstants.paletteSize} bytes',
      );
    }
  }
  final Uint8List _rgb;

  int getRed(int index) => _rgb[index * 3];
  int getGreen(int index) => _rgb[index * 3 + 1];
  int getBlue(int index) => _rgb[index * 3 + 2];

  int getRgba(int index) {
    final r = getRed(index);
    final g = getGreen(index);
    final b = getBlue(index);
    return (255 << 24) | (b << 16) | (g << 8) | r;
  }

  Uint32List toRgba32() {
    final result = Uint32List(_PaletteConstants.numColors);
    for (var i = 0; i < _PaletteConstants.numColors; i++) {
      result[i] = getRgba(i);
    }
    return result;
  }
}

class PlayPal {

  PlayPal(this.palettes);

  factory PlayPal.parse(Uint8List data) {
    final palettes = <DoomPalette>[];
    final numPalettes = data.length ~/ _PaletteConstants.paletteSize;

    for (var i = 0; i < numPalettes; i++) {
      final offset = i * _PaletteConstants.paletteSize;
      final rgb = Uint8List.sublistView(
        data,
        offset,
        offset + _PaletteConstants.paletteSize,
      );
      palettes.add(DoomPalette(rgb));
    }

    return PlayPal(palettes);
  }
  final List<DoomPalette> palettes;

  DoomPalette operator [](int index) => palettes[index];

  int get length => palettes.length;
}

class Colormap {

  Colormap(this._data);
  final Uint8List _data;

  int map(int colorIndex) => _data[colorIndex];

  Uint8List get data => _data;
}

class ColormapSet {

  ColormapSet(this.colormaps);

  factory ColormapSet.parse(Uint8List data) {
    final colormaps = <Colormap>[];
    final numMaps = data.length ~/ _PaletteConstants.colormapSize;

    for (var i = 0; i < numMaps; i++) {
      final offset = i * _PaletteConstants.colormapSize;
      final mapData = Uint8List.sublistView(
        data,
        offset,
        offset + _PaletteConstants.colormapSize,
      );
      colormaps.add(Colormap(mapData));
    }

    return ColormapSet(colormaps);
  }
  final List<Colormap> colormaps;

  Colormap operator [](int index) => colormaps[index];

  int get length => colormaps.length;
}
