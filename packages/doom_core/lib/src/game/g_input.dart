import 'package:doom_core/src/events/doom_event.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:doom_core/src/game/player.dart';

abstract final class GameKey {
  static const int forward = 119;
  static const int backward = 115;
  static const int strafeLeft = 97;
  static const int strafeRight = 100;
  static const int turnLeft = DoomKey.leftArrow;
  static const int turnRight = DoomKey.rightArrow;
  static const int up = DoomKey.upArrow;
  static const int down = DoomKey.downArrow;
  static const int fire = DoomKey.rctrl;
  static const int use = 32;
  static const int run = DoomKey.rshift;
  static const int strafe = DoomKey.ralt;
}

abstract final class _TurnConstants {
  static const int slowTurn = 640;
  static const int normalTurn = 1280;
  static const int fastTurnThreshold = 6;
}

class InputHandler {
  final Set<int> _pressedKeys = {};
  int _turnHeld = 0;

  void keyDown(int keyCode) {
    _pressedKeys.add(keyCode);
  }

  void keyUp(int keyCode) {
    _pressedKeys.remove(keyCode);
  }

  bool isPressed(int keyCode) => _pressedKeys.contains(keyCode);

  void buildTicCmd(TicCmd cmd) {
    cmd.clear();

    final running = isPressed(GameKey.run);
    final strafing = isPressed(GameKey.strafe);
    final speedMultiplier = running ? PlayerConstants.runMultiplier : 1;

    final forwardMove = PlayerConstants.forwardMove * speedMultiplier;
    final sideMove = PlayerConstants.sideMove * speedMultiplier;

    if (isPressed(GameKey.forward) || isPressed(GameKey.up)) {
      cmd.forwardMove += forwardMove;
    }
    if (isPressed(GameKey.backward) || isPressed(GameKey.down)) {
      cmd.forwardMove -= forwardMove;
    }

    if (isPressed(GameKey.strafeRight)) {
      cmd.sideMove += sideMove;
    }
    if (isPressed(GameKey.strafeLeft)) {
      cmd.sideMove -= sideMove;
    }

    final turningLeft = isPressed(GameKey.turnLeft);
    final turningRight = isPressed(GameKey.turnRight);

    if (strafing) {
      if (turningRight) {
        cmd.sideMove += sideMove;
      }
      if (turningLeft) {
        cmd.sideMove -= sideMove;
      }
    } else {
      if (turningLeft || turningRight) {
        _turnHeld++;
      } else {
        _turnHeld = 0;
      }

      final turnSpeed = _turnHeld >= _TurnConstants.fastTurnThreshold
          ? _TurnConstants.normalTurn
          : _TurnConstants.slowTurn;
      final adjustedTurnSpeed = running ? turnSpeed * 2 : turnSpeed;

      if (turningRight) {
        cmd.angleTurn -= adjustedTurnSpeed;
      }
      if (turningLeft) {
        cmd.angleTurn += adjustedTurnSpeed;
      }
    }

    if (isPressed(GameKey.fire)) {
      cmd.buttons |= TicCmdButtons.attack;
    }
    if (isPressed(GameKey.use)) {
      cmd.buttons |= TicCmdButtons.use;
    }

    cmd.forwardMove = cmd.forwardMove.clamp(-50, 50);
    cmd.sideMove = cmd.sideMove.clamp(-50, 50);
  }

  void clear() {
    _pressedKeys.clear();
    _turnHeld = 0;
  }
}
