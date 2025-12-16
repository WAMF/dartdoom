# DartDoom Completion Plan

## Feature Parity Assessment

Assessment of feature parity with original linuxdoom-1.10 C code (excluding sound and multiplayer).

### Summary by Category

| Category | Parity | Notes |
|----------|--------|-------|
| **Rendering** | 85-90% | Complete BSP, walls, floors/ceilings, sprites, sky parallax, lighting, animated textures |
| **Map Features** | 85-90% | Doors, lifts, crushers with proper crushing detection, teleporters, switches, locked doors, sector specials |
| **Status Bar/HUD** | 85-90% | Health, armor, ammo, weapons, keys, face animations |
| **Game Logic** | 80-85% | Physics, collision, damage, item pickups, power-ups |
| **Weapon Mechanics** | 75-80% | All 9 weapons functional with ammo system |
| **Intermission** | 75-80% | Stats display works, limited finale sequences |
| **Menus/UI** | 75-80% | Core menus work, quit confirmation, screen wipe, save/load missing |
| **Enemy AI** | 85-90% | 19 monster types, infighting, Pain Elemental, Arch-vile resurrection, bosses |
| **Game Flow** | 60-65% | Progression works, save/load and cheats limited |
| **Overall** | **~81%** | Highly functional implementation |

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

### Menus/UI (75-80%)
- [x] Main menu with navigation
- [x] Episode selection
- [x] Skill selection (all 5 levels)
- [x] Help screens
- [x] Title screen
- [x] Quit confirmation dialog with random messages
- [x] Screen wipe transitions (melt effect)

### Enemy AI (85-90%)
- [x] 19 monster types implemented (including Arch-vile, Cyberdemon, Spider Mastermind, Pain Elemental)
- [x] Player seeking with line-of-sight
- [x] Chase behavior
- [x] Melee and ranged attacks
- [x] Pain and death states
- [x] 8-directional movement
- [x] Monster infighting (threshold-based target switching)
- [x] Lost Soul charging attack (aSkullAttack)
- [x] Pain Elemental spawning Lost Souls (aPainAttack, aPainDie)
- [x] Monster-specific missile range checks (Vile, Revenant, Cyberdemon, Spider, Lost Soul)
- [x] Arch-vile resurrection (aVileChase finds corpses to raise)
- [x] Arch-vile fire attack (aVileTarget, aVileAttack, aFire)
- [x] Cyberdemon triple rocket attack (cyberAttack)
- [x] Spider Mastermind chaingun attack (spidRefire)

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
- [x] **Monster Infighting** - Monsters fight each other when hit by friendly fire
- [x] **Lost Soul charging attack** - aSkullAttack with momentum toward target
- [x] **Pain Elemental spawning Lost Souls** - aPainAttack and aPainDie spawn skulls
- [x] **Monster-specific missile range** - Vile, Revenant, Cyberdemon, Spider, Skull adjustments
- [x] **Complex AI Behaviors**:
  - [x] Arch-vile resurrection logic (aVileChase)
  - [x] Cyberdemon/Spider Mastermind boss patterns (states and attacks)

### Medium Priority
- [ ] **Save/Load Game** - Game persistence
- [ ] **Options Menu** - Settings and configuration UI
- [ ] **End-Game Sequences** - Finale text screens and victory sequence
- [ ] **Demo Recording/Playback** - Record and playback demos
- [ ] **Advanced Weapon Effects** - Muzzle flash, better projectile visuals

### Low Priority
- [x] **Wind/Push Sectors** - Not in vanilla DOOM (BOOM feature)
- [x] **Conveyor Belts** - Not in vanilla DOOM (BOOM feature)
- [x] **Parallax Sky** - Sky scrolls with view angle (implemented in r_sky.dart)
- [x] **Screen Wipe Transitions** - Melt effect between game states (implemented in f_wipe.dart)
- [x] **Quit Confirmation Dialog** - Shows random quit message, requires Y/N confirmation

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

### Monster Infighting (Implemented)
Reference: `original/linuxdoom-1.10/p_inter.c` (lines 904-915)

Implementation in `p_inter.dart` (`damageMobj` function, lines 622-636):
- When damaged and `threshold == 0` (or monster is Arch-vile), acquire attacker as target
- Set `threshold` to 100 tics to prevent rapid target switching
- Transition to `seeState` if in spawn state
- Arch-viles (type 64) never fight each other
- Chase behavior in `p_enemy.dart` continues attacking monster targets until they die or become non-shootable

### Pain Elemental Skull Spawning (Implemented)
Reference: `original/linuxdoom-1.10/p_enemy.c` (lines 1449-1505)

Implementation in `p_enemy.dart` (`_painShootSkull` function):
- Counts existing skulls on level (max 20 limit)
- Calculates spawn position with prestep offset from Pain Elemental
- Spawns Lost Soul at calculated position
- Validates position with `tryMove` - kills skull if blocked
- Sets skull target to Pain Elemental's target
- Immediately launches skull with `aSkullAttack`

### Monster-Specific Missile Range (Implemented)
Reference: `original/linuxdoom-1.10/p_enemy.c` (lines 197-256)

Implementation in `p_enemy.dart` (`checkMissileRange` function):
- Arch-vile (64): Max range of 14*64 units
- Revenant (66): Min range of 196 units, distance halved
- Cyberdemon (16): Distance halved, max 160 units
- Spider Mastermind (7): Distance halved
- Lost Soul (3006): Distance halved

### Arch-vile AI (Implemented)
Reference: `original/linuxdoom-1.10/p_enemy.c` (lines 1164-1338)

Implementation in `p_enemy.dart`:
- `aVileChase`: Searches for corpses within range, resurrects them by restoring health/flags/state
- `aVileTarget`: Spawns fire object at target location, links tracer chain
- `aVileAttack`: Deals 20 damage, applies vertical thrust, triggers radius attack via fire
- `aFire`: Keeps fire positioned in front of target during attack

State definitions in `info.dart`:
- 40 Vile states (stand, run, attack, heal, pain, death)
- 30 Fire states (animated fire effect)

### Boss Monsters (Implemented)
Reference: `original/linuxdoom-1.10/info.c` (mobjinfo entries)

Cyberdemon (type 16):
- 4000 HP, speed 16, 40 unit radius, 110 unit height
- Triple rocket attack via `cyberAttack` action
- States: stand, run (8 frames), attack (6 frames), pain, death (10 frames)

Spider Mastermind (type 7):
- 3000 HP, speed 12, 128 unit radius, 100 unit height
- Chaingun attack via `sPosAttack` with `spidRefire` loop
- States: stand, run (12 frames), attack (4 frames), pain, death (11 frames)

Pain Elemental (type 71):
- 400 HP, floating, 31 unit radius
- Spawns Lost Souls via `painAttack` and `painDie`
- States: stand, run (6 frames), attack (4 frames), pain, death (6 frames), raise (6 frames)

---

## Version History

- **2025-12-16**: Added quit confirmation dialog, fixed door crushing bug (movePlane now calls changeSector for proper crush detection), verified sky parallax and screen wipe already implemented - ~81% feature parity
- **2025-12-16**: Added Arch-vile, Cyberdemon, Spider Mastermind, Pain Elemental - ~80% feature parity
- **2025-12-16**: Added Pain Elemental skull spawning, monster-specific missile ranges - ~77% feature parity
- **2025-12-16**: Monster infighting verified as implemented - ~76% feature parity
- **2024-12-15**: Initial assessment - ~75% feature parity
