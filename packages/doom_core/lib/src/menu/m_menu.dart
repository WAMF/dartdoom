import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/doom_event.dart';
import 'package:doom_core/src/hud/hu_lib.dart';
import 'package:doom_core/src/menu/m_defs.dart';
import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/v_video.dart';
import 'package:doom_wad/doom_wad.dart';

typedef NewGameCallback = void Function(Skill skill, int episode, int map);
typedef QuitGameCallback = void Function();

class MenuSystem {
  MenuSystem(this._wadManager, this._screenBuffers);

  final WadManager _wadManager;
  final ScreenBuffers _screenBuffers;

  late List<Patch> _font;
  late Patch _skull1;
  late Patch _skull2;
  final Map<String, Patch> _menuPatches = {};
  final Map<String, Patch> _helpPatches = {};
  Patch? _titlePic;

  bool _menuActive = false;
  MenuDef? _currentMenu;
  int _itemOn = 0;
  int _whichSkull = 0;
  int _skullAnimCounter = 10;

  int _selectedEpisode = 1;

  late MenuDef _mainDef;
  late MenuDef _episodeDef;
  late MenuDef _newGameDef;
  late MenuDef _readDef1;
  late MenuDef _readDef2;

  NewGameCallback? onNewGame;
  QuitGameCallback? onQuitGame;

  bool get isActive => _menuActive;

  Uint8List get _screen => _screenBuffers.primary;

  void init() {
    _loadGraphics();
    _setupMenuDefinitions();

    _currentMenu = _mainDef;
    _menuActive = false;
    _itemOn = _currentMenu!.lastOn;
    _whichSkull = 0;
    _skullAnimCounter = 10;
  }

  void _loadGraphics() {
    _skull1 = _loadPatch(MenuConstants.skull1);
    _skull2 = _loadPatch(MenuConstants.skull2);

    for (final name in MenuPatchNames.allPatches) {
      final lumpNum = _wadManager.checkNumForName(name);
      if (lumpNum >= 0) {
        final data = _wadManager.cacheLumpNum(lumpNum);
        _menuPatches[name] = Patch.parse(data);
      }
    }

    final titleLumpNum = _wadManager.checkNumForName(MenuConstants.titlePic);
    if (titleLumpNum >= 0) {
      final data = _wadManager.cacheLumpNum(titleLumpNum);
      _titlePic = Patch.parse(data);
    }

    _loadHelpPatches();
    _loadFont();
  }

  void _loadHelpPatches() {
    const helpNames = [
      MenuConstants.help,
      MenuConstants.help1,
      MenuConstants.help2,
      MenuConstants.credit,
    ];

    for (final name in helpNames) {
      final lumpNum = _wadManager.checkNumForName(name);
      if (lumpNum >= 0) {
        final data = _wadManager.cacheLumpNum(lumpNum);
        _helpPatches[name] = Patch.parse(data);
      }
    }
  }

  Patch _loadPatch(String name) {
    final data = _wadManager.cacheLumpName(name);
    return Patch.parse(data);
  }

  void _loadFont() {
    _font = [];
    var charCode = HuConstants.fontStart;

    for (var i = 0; i < _FontConstants.fontSize; i++) {
      final lumpName = 'STCFN${charCode.toString().padLeft(3, '0')}';
      final lumpNum = _wadManager.checkNumForName(lumpName);
      if (lumpNum >= 0) {
        final data = _wadManager.cacheLumpNum(lumpNum);
        _font.add(Patch.parse(data));
      } else if (_font.isNotEmpty) {
        _font.add(_font[0]);
      }
      charCode++;
    }
  }

  void _setupMenuDefinitions() {
    _mainDef = MenuDef(
      items: [
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.newGame,
          callback: _newGame,
          alphaKey: 110,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.options,
          callback: _options,
          alphaKey: 111,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.loadGame,
          callback: _loadGame,
          alphaKey: 108,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.saveGame,
          callback: _saveGame,
          alphaKey: 115,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.readThis,
          callback: _readThis,
          alphaKey: 114,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.quitGame,
          callback: _quitDoom,
          alphaKey: 113,
        ),
      ],
      x: 97,
      y: 64,
      drawRoutine: _drawMainMenu,
    );

    _episodeDef = MenuDef(
      items: [
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.epi1,
          callback: _episode,
          alphaKey: 107,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.epi2,
          callback: _episode,
          alphaKey: 116,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.epi3,
          callback: _episode,
          alphaKey: 105,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.epi4,
          callback: _episode,
          alphaKey: 116,
        ),
      ],
      prevMenu: _mainDef,
      x: 48,
      y: 63,
      drawRoutine: _drawEpisode,
    );

    _newGameDef = MenuDef(
      items: [
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.jKill,
          callback: _chooseSkill,
          alphaKey: 105,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.rough,
          callback: _chooseSkill,
          alphaKey: 104,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.hurt,
          callback: _chooseSkill,
          alphaKey: 104,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.ultra,
          callback: _chooseSkill,
          alphaKey: 117,
        ),
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: MenuPatchNames.nmare,
          callback: _chooseSkill,
          alphaKey: 110,
        ),
      ],
      prevMenu: _episodeDef,
      x: 48,
      y: 63,
      lastOn: SkillIndices.hurtMePlenty,
      drawRoutine: _drawNewGame,
    );

    _readDef1 = MenuDef(
      items: [
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: '',
          callback: _readThis2,
        ),
      ],
      prevMenu: _mainDef,
      x: 280,
      y: 185,
      drawRoutine: _drawReadThis1,
    );

    _readDef2 = MenuDef(
      items: [
        MenuItem(
          status: MenuItemStatus.selectable,
          patchName: '',
          callback: _finishReadThis,
        ),
      ],
      prevMenu: _readDef1,
      x: 330,
      y: 175,
      drawRoutine: _drawReadThis2,
    );
  }

  void _newGame(int choice) {
    _setupNextMenu(_episodeDef);
  }

  void _episode(int choice) {
    _selectedEpisode = choice + 1;
    _setupNextMenu(_newGameDef);
  }

  void _chooseSkill(int choice) {
    final skill = Skill.values[choice];
    onNewGame?.call(skill, _selectedEpisode, 1);
    clearMenus();
  }

  void _options(int choice) {}

  void _loadGame(int choice) {}

  void _saveGame(int choice) {}

  void _readThis(int choice) {
    _setupNextMenu(_readDef1);
  }

  void _readThis2(int choice) {
    _setupNextMenu(_readDef2);
  }

  void _finishReadThis(int choice) {
    _setupNextMenu(_mainDef);
  }

  void _quitDoom(int choice) {
    onQuitGame?.call();
    clearMenus();
  }

  void _setupNextMenu(MenuDef menu) {
    _currentMenu = menu;
    _itemOn = menu.lastOn;
  }

  bool responder(DoomEvent event) {
    if (event.type != DoomEventType.keyDown) return false;

    final ch = event.data1;

    if (!_menuActive) {
      if (ch == DoomKey.escape) {
        startControlPanel();
        return true;
      }
      return false;
    }

    return _handleMenuKeys(ch);
  }

  bool _handleMenuKeys(int ch) {
    switch (ch) {
      case DoomKey.downArrow:
        _moveDown();
        return true;
      case DoomKey.upArrow:
        _moveUp();
        return true;
      case DoomKey.enter:
        _handleEnter();
        return true;
      case DoomKey.escape:
        _handleEscape();
        return true;
      case DoomKey.backspace:
        _handleBackspace();
        return true;
      default:
        return _handleAlphaKey(ch);
    }
  }

  void _moveDown() {
    final menu = _currentMenu;
    if (menu == null) return;

    do {
      if (_itemOn + 1 > menu.numItems - 1) {
        _itemOn = 0;
      } else {
        _itemOn++;
      }
    } while (menu.items[_itemOn].status == MenuItemStatus.disabled);
  }

  void _moveUp() {
    final menu = _currentMenu;
    if (menu == null) return;

    do {
      if (_itemOn == 0) {
        _itemOn = menu.numItems - 1;
      } else {
        _itemOn--;
      }
    } while (menu.items[_itemOn].status == MenuItemStatus.disabled);
  }

  void _handleEnter() {
    final menu = _currentMenu;
    if (menu == null) return;

    final item = menu.items[_itemOn];
    if (item.callback != null && item.status != MenuItemStatus.disabled) {
      menu.lastOn = _itemOn;
      item.callback!(_itemOn);
    }
  }

  void _handleEscape() {
    final menu = _currentMenu;
    if (menu != null) {
      menu.lastOn = _itemOn;
    }
    clearMenus();
  }

  void _handleBackspace() {
    final menu = _currentMenu;
    if (menu == null) return;

    menu.lastOn = _itemOn;
    if (menu.prevMenu != null) {
      _currentMenu = menu.prevMenu;
      _itemOn = _currentMenu!.lastOn;
    }
  }

  bool _handleAlphaKey(int ch) {
    final menu = _currentMenu;
    if (menu == null) return false;

    for (var i = _itemOn + 1; i < menu.numItems; i++) {
      if (menu.items[i].alphaKey == ch) {
        _itemOn = i;
        return true;
      }
    }

    for (var i = 0; i <= _itemOn; i++) {
      if (menu.items[i].alphaKey == ch) {
        _itemOn = i;
        return true;
      }
    }

    return false;
  }

  void ticker() {
    _skullAnimCounter--;
    if (_skullAnimCounter <= 0) {
      _whichSkull ^= 1;
      _skullAnimCounter = MenuConstants.skullAnimTics;
    }
  }

  void drawer() {
    if (!_menuActive) return;

    final menu = _currentMenu;
    if (menu == null) return;

    menu.drawRoutine?.call();

    final isFullscreenMenu = _isFullscreenMenu(menu);

    if (!isFullscreenMenu) {
      var y = menu.y;
      for (var i = 0; i < menu.numItems; i++) {
        final item = menu.items[i];
        if (item.patchName.isNotEmpty) {
          final patch = _menuPatches[item.patchName];
          if (patch != null) {
            VVideo.drawPatchDirect(_screen, menu.x, y, patch);
          }
        }
        y += MenuConstants.lineHeight;
      }

      final skullPatch = _whichSkull == 0 ? _skull1 : _skull2;
      VVideo.drawPatchDirect(
        _screen,
        menu.x + MenuConstants.skullXOffset,
        menu.y - 5 + _itemOn * MenuConstants.lineHeight,
        skullPatch,
      );
    }
  }

  bool _isFullscreenMenu(MenuDef menu) {
    return menu == _readDef1 || menu == _readDef2;
  }

  void drawTitlePic() {
    if (_titlePic != null) {
      VVideo.drawPatchDirect(_screen, 0, 0, _titlePic!);
    }
  }

  void _drawMainMenu() {
    final patch = _menuPatches[MenuPatchNames.doom];
    if (patch != null) {
      VVideo.drawPatchDirect(_screen, 94, 2, patch);
    }
  }

  void _drawEpisode() {
    final patch = _menuPatches[MenuPatchNames.episode];
    if (patch != null) {
      VVideo.drawPatchDirect(_screen, 54, 38, patch);
    }
  }

  void _drawNewGame() {
    var patch = _menuPatches[MenuPatchNames.newGameTitle];
    if (patch != null) {
      VVideo.drawPatchDirect(_screen, 96, 14, patch);
    }
    patch = _menuPatches[MenuPatchNames.skill];
    if (patch != null) {
      VVideo.drawPatchDirect(_screen, 54, 38, patch);
    }
  }

  void _drawReadThis1() {
    final patch = _helpPatches[MenuConstants.help1];
    if (patch != null) {
      VVideo.drawPatchDirect(_screen, 0, 0, patch);
    }
  }

  void _drawReadThis2() {
    final patch = _helpPatches[MenuConstants.help2];
    if (patch != null) {
      VVideo.drawPatchDirect(_screen, 0, 0, patch);
    }
  }

  void startControlPanel() {
    if (_menuActive) return;

    _menuActive = true;
    _currentMenu = _mainDef;
    _itemOn = _currentMenu!.lastOn;
  }

  void clearMenus() {
    _menuActive = false;
  }
}

abstract final class _FontConstants {
  static const int fontSize = 63;
}
