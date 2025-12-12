import 'dart:async';

import 'package:doom_core/src/events/doom_event.dart';
import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_wad/doom_wad.dart';

abstract class DoomInputSource {
  Stream<DoomEvent> get events;

  void startTic();
}

abstract class DoomVideoOutput {
  void setPalette(DoomPalette palette);

  void finishUpdate(FrameBuffer frame);

  int getTime();
}

abstract class DoomPlatform {
  DoomInputSource get input;
  DoomVideoOutput get video;

  void init();
  void shutdown();
  void error(String message);
}
