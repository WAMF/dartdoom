import 'dart:typed_data';

abstract final class _FlatConstants {
  static const int size = 64;
  static const int dataSize = size * size;
}

class Flat {
  Flat(this.data) {
    if (data.length != _FlatConstants.dataSize) {
      throw ArgumentError('Flat must have ${_FlatConstants.dataSize} bytes');
    }
  }

  static const int size = _FlatConstants.size;
  static const int dataSize = _FlatConstants.dataSize;

  final Uint8List data;

  int getPixel(int x, int y) =>
      data[(y & (_FlatConstants.size - 1)) * _FlatConstants.size +
          (x & (_FlatConstants.size - 1))];
}
