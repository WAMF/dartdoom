# DartDoom Project

## Overview

This project is a port of the original id Software DOOM (linuxdoom-1.10) from C to Dart. The goal is a faithful recreation of the original rendering and game logic.

## Architecture

```
dartdoom/
├── original/linuxdoom-1.10/    # Original C source code for reference
├── packages/
│   ├── doom_core/              # Pure Dart game engine (no Flutter dependencies)
│   │   ├── lib/src/render/     # Rendering: BSP, segs, planes, things, sky
│   │   └── lib/src/game/       # Game logic: player, physics, specials
│   ├── doom_math/              # Fixed-point math, angle tables, trig
│   └── doom_wad/               # WAD file parsing, textures, sprites
└── apps/
    └── doom_flutter/           # Flutter app with platform interface
```

### Design Principles

1. **Pure Dart Core**: `doom_core` has no Flutter dependencies. It receives input via `TicCmd` and outputs to a `Uint8List` framebuffer.

2. **Interface Boundary**: The Flutter app provides:
   - WAD file bytes
   - Keyboard/touch input
   - Framebuffer display (via `CustomPainter` or texture)

3. **Original Behavior**: Match the original C code behavior exactly, including quirks and limitations.

## C Code Reference

The original C source is in `original/linuxdoom-1.10/`. Key files:

| Dart File | C Reference | Purpose |
|-----------|-------------|---------|
| `r_main.dart` | `r_main.c` | Renderer setup, `R_ScaleFromGlobalAngle`, `R_PointToDist` |
| `r_bsp.dart` | `r_bsp.c` | BSP traversal, `R_RenderBSPNode` |
| `r_segs.dart` | `r_segs.c` | Wall rendering, `R_StoreWallRange`, `R_RenderSegLoop` |
| `r_plane.dart` | `r_plane.c` | Floor/ceiling rendering, visplanes |
| `r_things.dart` | `r_things.c` | Sprite projection, `R_DrawMaskedColumn` |
| `p_mobj.dart` | `p_mobj.c` | Object physics, `P_XYMovement`, `P_ZMovement` |
| `p_map.dart` | `p_map.c` | Collision detection, `P_TryMove` |
| `p_user.dart` | `p_user.c` | Player movement, `P_CalcHeight` |

## Documentation Guidelines

When implementing complex algorithms, include the original C code as a reference comment above the Dart implementation:

```dart
// Original C (r_main.c):
// ```c
// fixed_t R_PointToDist(fixed_t x, fixed_t y)
// {
//     int angle;
//     fixed_t dx, dy, temp, dist;
//     dx = abs(x - viewx);
//     dy = abs(y - viewy);
//     if (dy > dx) { temp = dx; dx = dy; dy = temp; }
//     angle = (tantoangle[FixedDiv(dy,dx)>>DBITS] + ANG90) >> ANGLETOFINESHIFT;
//     dist = FixedDiv(dx, finesine[angle]);
//     return dist;
// }
// ```
int pointToDist(int x, int y) {
  // ... Dart implementation
}
```

This helps verify correctness and debug discrepancies.

## Key Technical Details

### Fixed-Point Arithmetic
- DOOM uses 16.16 fixed-point (`FRACBITS = 16`, `FRACUNIT = 65536`)
- Dart uses 64-bit integers; use `.u32` extension for unsigned 32-bit wraparound
- Use `.s32` to interpret as signed 32-bit

### Angle System (BAM - Binary Angle Measurement)
- Full circle = 2^32 units (0x100000000)
- `ANG90 = 0x40000000`, `ANG180 = 0x80000000`, `ANG270 = 0xC0000000`
- Right shifts on angles need `.u32` first to prevent sign extension

### Sector Heights
- Stored in fixed-point after map loading (via `.toFixed()` in `r_data.dart`)
- Do NOT shift by `FRACBITS` again when reading

## Common Pitfalls

1. **Sign Extension**: Dart integers are 64-bit signed. Use `.u32` before right-shifting angles.

2. **Double Fixed-Point Conversion**: Sector heights are already fixed-point. Don't shift them again.

3. **Texture Coordinate Wrapping**: Use `% length` not `& (length-1)` for non-power-of-2 sprite posts.

4. **Distance Calculation**: Use proper trig (`pointToDist`), not the fast approximation.
