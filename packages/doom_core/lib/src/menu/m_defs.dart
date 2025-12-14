enum MenuItemStatus {
  disabled,
  selectable,
  slider,
}

typedef MenuItemCallback = void Function(int choice);
typedef MenuDrawRoutine = void Function();

class MenuItem {
  const MenuItem({
    required this.status,
    required this.patchName,
    this.callback,
    this.alphaKey = 0,
  });

  final MenuItemStatus status;
  final String patchName;
  final MenuItemCallback? callback;
  final int alphaKey;
}

class MenuDef {
  MenuDef({
    required this.items,
    required this.x,
    required this.y,
    this.prevMenu,
    this.drawRoutine,
    this.lastOn = 0,
  });

  final List<MenuItem> items;
  final MenuDef? prevMenu;
  final MenuDrawRoutine? drawRoutine;
  final int x;
  final int y;
  int lastOn;

  int get numItems => items.length;
}

abstract final class MenuConstants {
  static const int skullXOffset = -32;
  static const int lineHeight = 16;
  static const int skullAnimTics = 8;

  static const String skull1 = 'M_SKULL1';
  static const String skull2 = 'M_SKULL2';
  static const String mainTitle = 'M_DOOM';
  static const String titlePic = 'TITLEPIC';

  static const String help = 'HELP';
  static const String help1 = 'HELP1';
  static const String help2 = 'HELP2';
  static const String credit = 'CREDIT';
}

abstract final class MenuPatchNames {
  static const String doom = 'M_DOOM';
  static const String newGame = 'M_NGAME';
  static const String options = 'M_OPTION';
  static const String loadGame = 'M_LOADG';
  static const String saveGame = 'M_SAVEG';
  static const String readThis = 'M_RDTHIS';
  static const String quitGame = 'M_QUITG';

  static const String newGameTitle = 'M_NEWG';
  static const String skill = 'M_SKILL';
  static const String episode = 'M_EPISOD';

  static const String epi1 = 'M_EPI1';
  static const String epi2 = 'M_EPI2';
  static const String epi3 = 'M_EPI3';
  static const String epi4 = 'M_EPI4';

  static const String jKill = 'M_JKILL';
  static const String rough = 'M_ROUGH';
  static const String hurt = 'M_HURT';
  static const String ultra = 'M_ULTRA';
  static const String nmare = 'M_NMARE';

  static const List<String> allPatches = [
    doom,
    newGame,
    options,
    loadGame,
    saveGame,
    readThis,
    quitGame,
    newGameTitle,
    skill,
    episode,
    epi1,
    epi2,
    epi3,
    epi4,
    jKill,
    rough,
    hurt,
    ultra,
    nmare,
  ];
}

abstract final class MainMenuIndices {
  static const int newGame = 0;
  static const int options = 1;
  static const int loadGame = 2;
  static const int saveGame = 3;
  static const int readThis = 4;
  static const int quitDoom = 5;
}

abstract final class SkillIndices {
  static const int imTooYoungToDie = 0;
  static const int heyNotTooRough = 1;
  static const int hurtMePlenty = 2;
  static const int ultraViolence = 3;
  static const int nightmare = 4;
}
