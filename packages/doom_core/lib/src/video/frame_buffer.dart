import 'dart:typed_data';

abstract final class ScreenConstants {
  static const int width = 320;
  static const int height = 200;
  static const int pixelCount = width * height;
  static const int rgbaSize = pixelCount * 4;
}

class FrameBuffer {
  FrameBuffer()
      : indexedPixels = Uint8List(ScreenConstants.pixelCount),
        rgbaPixels = Uint8List(ScreenConstants.rgbaSize);

  final Uint8List indexedPixels;
  final Uint8List rgbaPixels;

  static const int width = ScreenConstants.width;
  static const int height = ScreenConstants.height;

  void clear([int colorIndex = 0]) {
    indexedPixels.fillRange(0, indexedPixels.length, colorIndex);
  }

  void setPixel(int x, int y, int colorIndex) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      indexedPixels[y * width + x] = colorIndex;
    }
  }

  int getPixel(int x, int y) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return indexedPixels[y * width + x];
    }
    return 0;
  }
}

class ScreenBuffers {
  ScreenBuffers()
      : screens = List.generate(5, (_) => Uint8List(ScreenConstants.pixelCount));

  final List<Uint8List> screens;

  Uint8List operator [](int index) => screens[index];

  Uint8List get primary => screens[0];
  Uint8List get background => screens[1];
}
