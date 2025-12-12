class TicCmd {
  TicCmd();

  int forwardMove = 0;
  int sideMove = 0;
  int angleTurn = 0;
  int consistency = 0;
  int chatChar = 0;
  int buttons = 0;

  void clear() {
    forwardMove = 0;
    sideMove = 0;
    angleTurn = 0;
    consistency = 0;
    chatChar = 0;
    buttons = 0;
  }

  void copyFrom(TicCmd other) {
    forwardMove = other.forwardMove;
    sideMove = other.sideMove;
    angleTurn = other.angleTurn;
    consistency = other.consistency;
    chatChar = other.chatChar;
    buttons = other.buttons;
  }
}

abstract final class TicCmdButtons {
  static const int attack = 1;
  static const int use = 2;
  static const int change = 4;
  static const int special = 128;

  static int weaponMask(int weapon) => weapon << 3;
  static int weaponFromButtons(int buttons) => (buttons & 56) >> 3;
}
