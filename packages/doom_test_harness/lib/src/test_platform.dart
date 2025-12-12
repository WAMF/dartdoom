import 'dart:async';

import 'package:doom_core/doom_core.dart';
import 'package:doom_wad/doom_wad.dart';

class TestInputSource implements DoomInputSource {
  TestInputSource();

  final _eventController = StreamController<DoomEvent>.broadcast();
  final List<DoomEvent> _pendingEvents = [];

  @override
  Stream<DoomEvent> get events => _eventController.stream;

  @override
  void startTic() {
    for (final event in _pendingEvents) {
      _eventController.add(event);
    }
    _pendingEvents.clear();
  }

  void injectEvent(DoomEvent event) {
    _pendingEvents.add(event);
  }

  void injectKeyDown(int key) {
    injectEvent(DoomEvent(type: DoomEventType.keyDown, data1: key));
  }

  void injectKeyUp(int key) {
    injectEvent(DoomEvent(type: DoomEventType.keyUp, data1: key));
  }

  void dispose() {
    _eventController.close();
  }
}

class TestVideoOutput implements DoomVideoOutput {
  TestVideoOutput();

  DoomPalette? currentPalette;
  final List<FrameBuffer> capturedFrames = [];
  int ticCount = 0;
  bool captureFrames = false;

  @override
  void setPalette(DoomPalette palette) {
    currentPalette = palette;
  }

  @override
  void finishUpdate(FrameBuffer frame) {
    if (captureFrames) {
      final copy = FrameBuffer()
        ..indexedPixels.setAll(0, frame.indexedPixels)
        ..rgbaPixels.setAll(0, frame.rgbaPixels);
      capturedFrames.add(copy);
    }
  }

  @override
  int getTime() => ticCount;

  void advanceTic() => ticCount++;

  void clearCapturedFrames() => capturedFrames.clear();
}

class TestPlatform implements DoomPlatform {
  TestPlatform()
      : input = TestInputSource(),
        video = TestVideoOutput();

  @override
  final TestInputSource input;

  @override
  final TestVideoOutput video;

  String? lastError;
  bool isInitialized = false;
  bool isShutdown = false;

  @override
  void init() {
    isInitialized = true;
  }

  @override
  void shutdown() {
    isShutdown = true;
    input.dispose();
  }

  @override
  void error(String message) {
    lastError = message;
    throw StateError('DOOM Error: $message');
  }

  void advanceTic() {
    video.advanceTic();
  }
}
