enum DoomEventType {
  keyDown,
  keyUp,
  mouse,
}

class DoomEvent {
  const DoomEvent({
    required this.type,
    required this.data1,
    this.data2 = 0,
    this.data3 = 0,
  });

  final DoomEventType type;
  final int data1;
  final int data2;
  final int data3;
}

abstract final class DoomKey {
  static const int rightArrow = 0xae;
  static const int leftArrow = 0xac;
  static const int upArrow = 0xad;
  static const int downArrow = 0xaf;
  static const int escape = 27;
  static const int enter = 13;
  static const int tab = 9;
  static const int f1 = 0x80 + 0x3b;
  static const int f2 = 0x80 + 0x3c;
  static const int f3 = 0x80 + 0x3d;
  static const int f4 = 0x80 + 0x3e;
  static const int f5 = 0x80 + 0x3f;
  static const int f6 = 0x80 + 0x40;
  static const int f7 = 0x80 + 0x41;
  static const int f8 = 0x80 + 0x42;
  static const int f9 = 0x80 + 0x43;
  static const int f10 = 0x80 + 0x44;
  static const int f11 = 0x80 + 0x57;
  static const int f12 = 0x80 + 0x58;
  static const int backspace = 127;
  static const int pause = 0xff;
  static const int equals = 0x3d;
  static const int minus = 0x2d;
  static const int rshift = 0x80 + 0x36;
  static const int rctrl = 0x80 + 0x1d;
  static const int ralt = 0x80 + 0x38;
  static const int lalt = ralt;
  static const int capsLock = 0x80 + 0x3a;
  static const int numLock = 0x80 + 0x45;
  static const int scrollLock = 0x80 + 0x46;
  static const int home = 0x80 + 0x47;
  static const int end = 0x80 + 0x4f;
  static const int pageUp = 0x80 + 0x49;
  static const int pageDown = 0x80 + 0x51;
  static const int insert = 0x80 + 0x52;
  static const int delete = 0x80 + 0x53;
  static const int keyY = 121;
  static const int keyN = 110;
}
