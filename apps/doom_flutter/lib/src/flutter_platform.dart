import 'dart:async';

import 'package:doom_core/doom_core.dart';
import 'package:doom_wad/doom_wad.dart';

class FlutterInputSource implements DoomInputSource {
  FlutterInputSource();

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

  void postEvent(DoomEvent event) {
    _pendingEvents.add(event);
  }

  void postKeyDown(int key) {
    postEvent(DoomEvent(type: DoomEventType.keyDown, data1: key));
  }

  void postKeyUp(int key) {
    postEvent(DoomEvent(type: DoomEventType.keyUp, data1: key));
  }

  void dispose() {
    _eventController.close();
  }
}

class FlutterVideoOutput implements DoomVideoOutput {
  FlutterVideoOutput({this.onFrameReady});

  final void Function(FrameBuffer frame)? onFrameReady;
  final _paletteConverter = PaletteConverter();
  int _startTime = 0;
  bool _started = false;

  @override
  void setPalette(DoomPalette palette) {
    _paletteConverter.setPalette(palette);
  }

  @override
  void finishUpdate(FrameBuffer frame) {
    _paletteConverter.convertFrame(frame.indexedPixels, frame.rgbaPixels);
    onFrameReady?.call(frame);
  }

  @override
  int getTime() {
    if (!_started) {
      _started = true;
      _startTime = DateTime.now().millisecondsSinceEpoch;
    }
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startTime;
    return (elapsed * GameConstants.ticRate / 1000).floor();
  }

  void resetTime() {
    _started = false;
    _startTime = 0;
  }
}

class FlutterPlatform implements DoomPlatform {
  FlutterPlatform({void Function(FrameBuffer frame)? onFrameReady})
      : input = FlutterInputSource(),
        video = FlutterVideoOutput(onFrameReady: onFrameReady);

  @override
  final FlutterInputSource input;

  @override
  final FlutterVideoOutput video;

  @override
  void init() {}

  @override
  void shutdown() {
    input.dispose();
  }

  @override
  void error(String message) {
    throw StateError('DOOM Error: $message');
  }
}
