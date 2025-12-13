# DOOM Port to Pure Dart - Implementation Plan

## Overview
Port original DOOM (linuxdoom-1.10) to pure Dart with Flutter frontend. Core engine without sound, playable with shareware WAD.

## Package Structure

```
dartdoom/
├── packages/
│   ├── doom_math/           # Fixed-point math, trig tables, PRNG
│   ├── doom_wad/            # WAD parsing, assets, palettes
│   ├── doom_core/           # Engine: renderer, game logic, platform abstraction
│   └── doom_test_harness/   # Headless testing implementation
├── apps/
│   └── doom_flutter/        # Flutter app with rendering widget
└── original/                # Reference C source
```

## Core Abstractions

### Input Interface (doom_core)
```dart
enum DoomEventType { keyDown, keyUp, mouse }

class DoomEvent {
  final DoomEventType type;
  final int data1;  // key code or mouse buttons
  final int data2;  // mouse x delta
  final int data3;  // mouse y delta
}

abstract class DoomInputSource {
  Stream<DoomEvent> get events;
}
```

### Output Interface (doom_core)
```dart
class FrameBuffer {
  final Uint8List rgbaPixels;  // 320x200x4 RGBA32
  static const int width = 320;
  static const int height = 200;
}

abstract class DoomVideoOutput {
  void setPalette(List<int> palette);
  void finishUpdate(FrameBuffer frame);
  int getTime();  // tics since start (35/sec)
}
```

### Platform Abstraction (doom_core)
```dart
abstract class DoomPlatform {
  DoomInputSource get input;
  DoomVideoOutput get video;
  void init();
  void shutdown();
}
```

### DI Setup (kiss_dependencies)
```dart
void initializeDoom(DoomPlatform platform) {
  register<DoomPlatform>(() => platform);
  register<WadManager>(() => WadManager());
  register<GameState>(() => GameState());
  register<Renderer>(() => Renderer());
}
```

## Dart Type Mappings

| C Type | Dart Type | Notes |
|--------|-----------|-------|
| `fixed_t` | `int` | 16.16 fixed-point, use bit ops |
| `angle_t` | `int` | Mask with `& 0xFFFFFFFF` |
| `byte` | `int` / `Uint8List` | For arrays |
| `short` | `int` | Use `.toSigned(16)` when needed |

## Implementation Phases

### Phase 1: Foundation
**Files to create:**
- `packages/doom_math/lib/src/fixed.dart` - Fixed-point ops
- `packages/doom_math/lib/src/tables.dart` - Trig tables from tables.c
- `packages/doom_math/lib/src/random.dart` - M_Random port

**Reference:** `original/linuxdoom-1.10/m_fixed.c`, `tables.c`, `m_random.c`

### Phase 2: WAD Loading
**Files to create:**
- `packages/doom_wad/lib/src/wad_file.dart` - Header, lump directory
- `packages/doom_wad/lib/src/lump_cache.dart` - Caching with WeakReference
- `packages/doom_wad/lib/src/palette.dart` - PLAYPAL, COLORMAP
- `packages/doom_wad/lib/src/patch.dart` - Column-post RLE decoding
- `packages/doom_wad/lib/src/texture.dart` - Composite texture building
- `packages/doom_wad/lib/src/flat.dart` - 64x64 floor/ceiling textures
- `packages/doom_wad/lib/src/map_data.dart` - THINGS, LINEDEFS, etc.

**Reference:** `original/linuxdoom-1.10/w_wad.c`, `r_data.c`

### Phase 3: Platform & Events
**Files to create:**
- `packages/doom_core/lib/src/platform/doom_platform.dart` - Abstract interface
- `packages/doom_core/lib/src/events/doom_event.dart` - Event types
- `packages/doom_core/lib/src/events/tic_cmd.dart` - ticcmd_t port
- `packages/doom_core/lib/src/doomdef.dart` - Constants, enums

**Reference:** `original/linuxdoom-1.10/d_event.h`, `d_ticcmd.h`, `doomdef.h`

### Phase 4: Video System
**Files to create:**
- `packages/doom_core/lib/src/video/frame_buffer.dart` - Screen buffers
- `packages/doom_core/lib/src/video/v_video.dart` - Patch drawing
- `packages/doom_core/lib/src/video/palette_converter.dart` - Index→RGBA32

**Reference:** `original/linuxdoom-1.10/v_video.c`, `i_video.c`

### Phase 5: Renderer
**Files to create:**
- `packages/doom_core/lib/src/render/r_main.dart` - R_RenderPlayerView
- `packages/doom_core/lib/src/render/r_bsp.dart` - BSP traversal
- `packages/doom_core/lib/src/render/r_segs.dart` - Wall segments
- `packages/doom_core/lib/src/render/r_plane.dart` - Floors/ceilings
- `packages/doom_core/lib/src/render/r_things.dart` - Sprites
- `packages/doom_core/lib/src/render/r_draw.dart` - Column/span drawing
- `packages/doom_core/lib/src/render/r_sky.dart` - Sky rendering

**Reference:** `original/linuxdoom-1.10/r_*.c`

### Phase 6: Play Simulation
**Files to create:**
- `packages/doom_core/lib/src/play/p_mobj.dart` - Map objects
- `packages/doom_core/lib/src/play/p_tick.dart` - Thinker system
- `packages/doom_core/lib/src/play/p_setup.dart` - Level loading
- `packages/doom_core/lib/src/play/p_map.dart` - Movement/collision
- `packages/doom_core/lib/src/play/p_enemy.dart` - Monster AI
- `packages/doom_core/lib/src/play/p_spec.dart` - Doors, lifts, etc.
- `packages/doom_core/lib/src/play/p_user.dart` - Player movement

**Reference:** `original/linuxdoom-1.10/p_*.c`

### Phase 7: Game Loop
**Files to create:**
- `packages/doom_core/lib/src/game/g_game.dart` - G_BuildTiccmd, G_Responder
- `packages/doom_core/lib/src/game/d_main.dart` - D_DoomMain, D_DoomLoop

**Reference:** `original/linuxdoom-1.10/g_game.c`, `d_main.c`

### Phase 8: UI Systems

#### 8a: HUD & Status Bar ✅ COMPLETE
**Files created:**
- `packages/doom_core/lib/src/video/v_video.dart` - Patch drawing (V_DrawPatch, V_CopyRect)
- `packages/doom_core/lib/src/hud/st_lib.dart` - Status bar widgets (StNumber, StPercent, StMultIcon, StBinIcon)
- `packages/doom_core/lib/src/hud/st_stuff.dart` - Status bar logic, face state machine
- `packages/doom_core/lib/src/hud/hu_lib.dart` - HUD text widgets (HuTextLine, HuScrollText, HuInputText)
- `packages/doom_core/lib/src/hud/hu_stuff.dart` - HUD message display

**Files modified:**
- `packages/doom_core/lib/src/video/palette_converter.dart` - Multi-palette support (damage red, pickup gold, radiation green)
- `packages/doom_core/lib/src/game/doom_game.dart` - HUD integration

#### 8b: Menu System
**Files to create:**
- `packages/doom_core/lib/src/menu/m_menu.dart` - Menu state machine and input handling

**Data Structures (from m_menu.c):**
```dart
enum MenuItemStatus { inactive, selectable, slider }

class MenuItem {
  final MenuItemStatus status;
  final String lumpName;      // WAD graphic (e.g. "M_NGAME")
  final void Function(int) routine;
  final String alphaKey;      // Hotkey
}

class MenuDef {
  final List<MenuItem> items;
  final MenuDef? prevMenu;
  final void Function() drawRoutine;
  final int x, y;
  int lastOn;                 // Remember cursor position
}
```

**Menu Hierarchy:**
```
MainMenu (M_DOOM title)
├── New Game → EpisodeMenu → SkillMenu → Start game
├── Options → OptionsMenu
│   ├── End Game
│   ├── Messages On/Off
│   ├── Graphic Detail
│   ├── Screen Size (slider)
│   ├── Mouse Sensitivity (slider)
│   └── Sound Volume → SoundMenu
│       ├── SFX Volume (slider)
│       └── Music Volume (slider)
├── Load Game → LoadMenu (6 slots)
├── Save Game → SaveMenu (6 slots with text input)
├── Read This → Help screens
└── Quit Game → Confirm dialog
```

**Key Features to Implement:**
- `M_Responder(event)` - Handle ESC, arrows, Enter, hotkeys
- `M_Ticker()` - Skull cursor animation (M_SKULL1, M_SKULL2)
- `M_Drawer()` - Render current menu using HU font
- `M_StartControlPanel()` - Open menu (ESC key)
- `M_DrawThermo(x, y, width, dot)` - Slider widget
- `M_WriteText(x, y, string)` - Text using HU font
- Message box system with yes/no callbacks
- Save game string editing

**WAD Graphics Required:**
| Lump | Description |
|------|-------------|
| M_DOOM | Title graphic |
| M_SKULL1, M_SKULL2 | Animated cursor |
| M_NGAME, M_OPTION, M_LOADG, M_SAVEG, M_RDTHIS, M_QUITG | Main menu items |
| M_EPI1-4 | Episode names |
| M_SKILL, M_JKILL, M_ROUGH, M_HURT, M_ULTRA, M_NMARE | Skill menu |
| M_NEWG, M_OPTTTL, M_LOADG, M_SAVEG | Menu titles |
| M_THERML, M_THERMM, M_THERMR, M_THERMO | Slider parts |
| M_LSLEFT, M_LSCNTR, M_LSRGHT | Save slot border |

**Integration:**
- Add `menuActive` flag to game state
- Route input to menu when active
- Pause game logic when menu open
- Draw menu over game view

#### 8c: Automap
**Files to create:**
- `packages/doom_core/lib/src/automap/am_map.dart` - Automap rendering

**Features:**
- Line rendering (walls, doors, secrets in different colors)
- Player arrow, thing markers
- Pan/zoom controls
- Grid overlay option
- Follow mode toggle

**Reference:** `original/linuxdoom-1.10/m_menu.c`, `st_stuff.c`, `hu_stuff.c`, `am_map.c`

### Phase 9: Test Harness
**Files to create:**
- `packages/doom_test_harness/lib/src/test_platform.dart` - Mock platform
- `packages/doom_test_harness/lib/src/frame_capture.dart` - Capture frames
- `packages/doom_test_harness/lib/src/demo_player.dart` - Demo playback

### Phase 10: Flutter App
**Files to create:**
- `apps/doom_flutter/lib/src/doom_widget.dart` - Main widget
- `apps/doom_flutter/lib/src/doom_painter.dart` - CustomPainter
- `apps/doom_flutter/lib/src/flutter_platform.dart` - Platform impl
- `apps/doom_flutter/lib/src/key_mapping.dart` - Key translation
- `apps/doom_flutter/lib/src/di_setup.dart` - kiss_dependencies setup

## Key Implementation Details

### Fixed-Point (16.16)
```dart
class Fixed {
  static const int fracBits = 16;
  static const int fracUnit = 1 << fracBits;
  static int mul(int a, int b) => (a * b) >> fracBits;
  static int div(int a, int b) => ((a << fracBits) ~/ b);
}
```

### WAD Binary Parsing
```dart
class WadReader {
  final ByteData _data;
  int readInt16() => _data.getInt16(_pos, Endian.little);
  int readInt32() => _data.getInt32(_pos, Endian.little);
}
```

### Game Loop Timing (35 tics/sec)
```dart
class GameLoop {
  static const double msPerTic = 1000.0 / 35;
  double _accumulator = 0;

  void update(int deltaMs) {
    _accumulator += deltaMs;
    while (_accumulator >= msPerTic) {
      runSingleTic();
      _accumulator -= msPerTic;
    }
    render();
  }
}
```

### Flutter Frame Rendering
```dart
class DoomPainter extends CustomPainter {
  final ui.Image image;

  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, 320, 200),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}
```

## Testing Strategy

1. **Unit tests** - Fixed-point math matches C exactly
2. **WAD tests** - Parse shareware WAD, verify lump counts
3. **Demo playback** - Original demos produce same state
4. **Frame comparison** - Known frames match references

## Critical Reference Files

- `original/linuxdoom-1.10/m_fixed.c` - Fixed-point math
- `original/linuxdoom-1.10/w_wad.c` - WAD parsing
- `original/linuxdoom-1.10/r_main.c` - Render orchestration
- `original/linuxdoom-1.10/d_main.c` - Main loop
- `original/linuxdoom-1.10/g_game.c` - Input handling
