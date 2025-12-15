# DartDoom Completion Plan

## Feature Parity Assessment

Assessment of feature parity with original linuxdoom-1.10 C code (excluding sound and multiplayer).

### Summary by Category

| Category | Parity | Notes |
|----------|--------|-------|
| **Rendering** | 85-90% | Complete BSP, walls, floors/ceilings, sprites, sky, lighting, animated textures |
| **Map Features** | 85-90% | Doors, lifts, crushers, teleporters, switches, locked doors, sector specials |
| **Status Bar/HUD** | 85-90% | Health, armor, ammo, weapons, keys, face animations |
| **Game Logic** | 80-85% | Physics, collision, damage, item pickups, power-ups |
| **Weapon Mechanics** | 75-80% | All 9 weapons functional with ammo system |
| **Intermission** | 75-80% | Stats display works, limited finale sequences |
| **Menus/UI** | 70-75% | Core menus work, save/load missing |
| **Enemy AI** | 60-70% | 16 monster types, basic behaviors only |
| **Game Flow** | 60-65% | Progression works, save/load and cheats limited |
| **Overall** | **~75%** | Highly functional implementation |

---

## Completed Features

### Rendering (85-90%)
- [x] BSP traversal with proper subsector rendering
- [x] Wall rendering (solid, two-sided, upper/lower/middle textures)
- [x] Masked texture support (transparent walls)
- [x] Floor/ceiling rendering with visplane system
- [x] Flat texture rendering with proper scaling
- [x] Sprite projection with distance scaling
- [x] Vissprite sorting and z-ordering
- [x] Sky rendering (SKY1 texture mapping)
- [x] Dynamic colormaps based on distance and sector light
- [x] Animated textures and flats
- [x] Scrolling textures (line special 48)

### Map Features (85-90%)
- [x] Manual and automatic doors
- [x] Door types: Normal, Close, Open, Close30ThenOpen, RaiseIn5Mins
- [x] Blaze doors (fast variants)
- [x] Locked doors (blue/red/yellow card and skull keys)
- [x] Locked door messages
- [x] Lifts/platforms (raise, lower, perpetual, wait-on-reach)
- [x] Ceiling crushers with damage
- [x] Teleporters with FOG effects
- [x] Switches (46 texture pairs)
- [x] Stairs (8-step and turbo 16-step)
- [x] Sector specials:
  - [x] Secret sectors (type 9)
  - [x] Damage floors (5/10/20 hp per tic)
  - [x] End-level damage (type 11)
  - [x] Light specials (flicker, blink, oscillate, fire)
  - [x] Door specials (close in 30s, open in 5min)

### Status Bar/HUD (85-90%)
- [x] Health display with damage indicator
- [x] Armor display with type indicator
- [x] Current ammo and max capacity
- [x] Weapons owned indicator
- [x] Key cards display (6 keys)
- [x] Face animations (pain, ouch, evil grin, god mode, dead)
- [x] Player messages
- [x] Kill/item/secret tracking

### Game Logic (80-85%)
- [x] Player movement with momentum
- [x] Strafing and view bobbing
- [x] Object physics (gravity, friction)
- [x] Collision detection (line, sector, object)
- [x] Step height limits (24 units)
- [x] Damage calculation with armor absorption
- [x] Radius damage/explosions
- [x] Item pickup system
- [x] Power-ups (invulnerability, strength, invisibility, ironFeet, infrared, allMap)
- [x] Key card system

### Weapon Mechanics (75-80%)
- [x] All 9 weapons: Fist, Pistol, Shotgun, Chaingun, Missile, Plasma, BFG, Chainsaw, Super Shotgun
- [x] 4 ammo types with max limits
- [x] Weapon sprites and animations
- [x] Weapon lower/raise animation
- [x] Hitscan and projectile attacks
- [x] Weapon switching and priority

### Intermission (75-80%)
- [x] End-level intermission display
- [x] Kill/item/secret percentages
- [x] Time spent counter
- [x] Episode-specific backgrounds
- [x] Level completion indicators

### Menus/UI (70-75%)
- [x] Main menu with navigation
- [x] Episode selection
- [x] Skill selection (all 5 levels)
- [x] Help screens
- [x] Title screen

### Enemy AI (60-70%)
- [x] 16 monster types implemented
- [x] Player seeking with line-of-sight
- [x] Chase behavior
- [x] Melee and ranged attacks
- [x] Pain and death states
- [x] 8-directional movement

### Game Flow (60-65%)
- [x] All 5 difficulty levels
- [x] Episode/map progression
- [x] Level loading from WAD
- [x] Player spawning and respawning
- [x] God mode cheat
- [x] No-clip cheat

---

## Missing Features (Priority Order)

### High Priority
- [ ] **Automap** - Essential navigation feature
- [ ] **Additional Cheats** - IDKFA (all keys/weapons/ammo), IDFA (weapons/ammo), IDCLEV (level warp), IDDT (automap reveal), IDBEHOLD (power-ups)
- [ ] **Monster Infighting** - Monsters should fight each other when hit by friendly fire
- [ ] **Complex AI Behaviors**:
  - [ ] Lost Soul charging attack
  - [ ] Arch-vile resurrection logic
  - [ ] Pain Elemental spawning Lost Souls
  - [ ] Cyberdemon/Spider Mastermind specific patterns

### Medium Priority
- [ ] **Save/Load Game** - Game persistence
- [ ] **Options Menu** - Settings and configuration UI
- [ ] **End-Game Sequences** - Finale text screens and victory sequence
- [ ] **Demo Recording/Playback** - Record and playback demos
- [ ] **Advanced Weapon Effects** - Muzzle flash, better projectile visuals

### Low Priority
- [ ] **Wind/Push Sectors** - Sector force effects
- [ ] **Conveyor Belts** - Moving floor textures
- [ ] **Parallax Sky** - Sky parallax with view angle
- [ ] **Screen Wipe Transitions** - Smooth level transitions
- [ ] **Quit Confirmation Dialog**

---

## Implementation Notes

### Automap Implementation
Reference files:
- `original/linuxdoom-1.10/am_map.c` - Automap rendering
- `original/linuxdoom-1.10/am_map.h` - Automap definitions

Key components:
- Line rendering for walls (different colors for 1-sided, 2-sided, secret)
- Player position and direction arrow
- Thing markers (optional with IDDT cheat)
- Zoom and pan controls
- Grid overlay (optional)

### Cheat Code Implementation
Reference: `original/linuxdoom-1.10/st_stuff.c` (cheat handling)

Cheat sequences to implement:
- `iddqd` - God mode (already implemented)
- `idkfa` - All keys, weapons, full ammo
- `idfa` - All weapons, full ammo (no keys)
- `idclip` - No clipping (already implemented)
- `idclev##` - Warp to level (episode/map)
- `iddt` - Toggle automap details
- `idbehold[x]` - Toggle power-up (V=invuln, S=strength, I=invis, R=radsuit, A=automap, L=lite-amp)
- `idmus##` - Change music (N/A - sound excluded)
- `idmypos` - Display coordinates
- `idchoppers` - Chainsaw + invulnerability message

### Monster Infighting
Reference: `original/linuxdoom-1.10/p_enemy.c`

When a monster is damaged by another monster (not player):
- Set `target` to the attacker
- Enter chase/attack state toward attacker
- Continue until one dies or loses sight

---

## Version History

- **2024-12-15**: Initial assessment - ~75% feature parity
