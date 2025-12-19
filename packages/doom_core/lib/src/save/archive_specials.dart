import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/specials/ceiling_thinker.dart';
import 'package:doom_core/src/game/specials/door_thinker.dart';
import 'package:doom_core/src/game/specials/floor_thinker.dart';
import 'package:doom_core/src/game/specials/light_thinker.dart';
import 'package:doom_core/src/game/specials/plat_thinker.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/serialization/game_serializer.dart';

/// Thinker class tags for specials.
///
/// Original C (p_saveg.c):
/// ```c
/// typedef enum
/// {
///     tc_ceiling,
///     tc_door,
///     tc_floor,
///     tc_plat,
///     tc_flash,
///     tc_strobe,
///     tc_glow,
///     tc_endspecials
/// } specials_e;
/// ```
abstract final class SpecialClass {
  static const int ceiling = 1;
  static const int door = 2;
  static const int floor = 3;
  static const int plat = 4;
  static const int flash = 5;
  static const int strobe = 6;
  static const int glow = 7;
  static const int fireFlicker = 8;
  static const int endSpecials = 0;
}

/// Archive all active special thinkers to the writer.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_ArchiveSpecials (void)
/// {
///     thinker_t*  th;
///     ceiling_t*  ceiling;
///     vldoor_t*   door;
///     floormove_t* floor;
///     plat_t*     plat;
///     lightflash_t* flash;
///     strobe_t*   strobe;
///     glow_t*     glow;
///
///     for (th = thinkercap.next ; th != &thinkercap ; th=th->next)
///     {
///         // Check for each thinker type and serialize
///     }
///     *save_p++ = tc_endspecials;
/// }
/// ```
void archiveSpecials(
  LevelLocals level,
  RenderState renderState,
  GameDataWriter writer,
) {
  // Iterate through all thinkers and serialize active specials
  for (final thinker in level.thinkers.all) {
    if (thinker is CeilingThinker) {
      writer.writeByte(SpecialClass.ceiling);
      writer.pad();
      _writeCeiling(thinker, renderState, writer);
    } else if (thinker is DoorThinker) {
      writer.writeByte(SpecialClass.door);
      writer.pad();
      _writeDoor(thinker, renderState, writer);
    } else if (thinker is FloorThinker) {
      writer.writeByte(SpecialClass.floor);
      writer.pad();
      _writeFloor(thinker, renderState, writer);
    } else if (thinker is PlatThinker) {
      writer.writeByte(SpecialClass.plat);
      writer.pad();
      _writePlat(thinker, renderState, writer);
    } else if (thinker is LightFlashThinker) {
      writer.writeByte(SpecialClass.flash);
      writer.pad();
      _writeLightFlash(thinker, renderState, writer);
    } else if (thinker is StrobeThinker) {
      writer.writeByte(SpecialClass.strobe);
      writer.pad();
      _writeStrobe(thinker, renderState, writer);
    } else if (thinker is GlowThinker) {
      writer.writeByte(SpecialClass.glow);
      writer.pad();
      _writeGlow(thinker, renderState, writer);
    } else if (thinker is FireFlickerThinker) {
      writer.writeByte(SpecialClass.fireFlicker);
      writer.pad();
      _writeFireFlicker(thinker, renderState, writer);
    }
  }

  // Write end marker
  writer.writeByte(SpecialClass.endSpecials);
}

void _writeCeiling(
  CeilingThinker ceiling,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(ceiling.sector, renderState))
    ..writeInt(ceiling.type.index)
    ..writeFixed(ceiling.bottomHeight)
    ..writeFixed(ceiling.topHeight)
    ..writeFixed(ceiling.speed)
    ..writeInt(ceiling.direction)
    ..writeInt(ceiling.oldDirection)
    ..writeBool(value: ceiling.crush)
    ..writeInt(ceiling.tag);
}

void _writeDoor(
  DoorThinker door,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(door.sector, renderState))
    ..writeInt(door.type.index)
    ..writeFixed(door.topHeight)
    ..writeFixed(door.speed)
    ..writeInt(door.direction)
    ..writeInt(door.topWait)
    ..writeInt(door.topCountdown);
}

void _writeFloor(
  FloorThinker floor,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(floor.sector, renderState))
    ..writeInt(floor.type.index)
    ..writeBool(value: floor.crush)
    ..writeInt(floor.direction)
    ..writeInt(floor.newSpecial)
    ..writeInt(floor.texture)
    ..writeFixed(floor.floorDestHeight)
    ..writeFixed(floor.speed);
}

void _writePlat(
  PlatThinker plat,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(plat.sector, renderState))
    ..writeFixed(plat.speed)
    ..writeFixed(plat.low)
    ..writeFixed(plat.high)
    ..writeInt(plat.wait)
    ..writeInt(plat.count)
    ..writeInt(plat.status.index)
    ..writeInt(plat.oldStatus.index)
    ..writeInt(plat.type.index)
    ..writeBool(value: plat.crush)
    ..writeInt(plat.tag);
}

void _writeLightFlash(
  LightFlashThinker flash,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(flash.sector, renderState))
    ..writeInt(flash.count)
    ..writeInt(flash.maxLight)
    ..writeInt(flash.minLight)
    ..writeInt(flash.maxTime)
    ..writeInt(flash.minTime);
}

void _writeStrobe(
  StrobeThinker strobe,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(strobe.sector, renderState))
    ..writeInt(strobe.count)
    ..writeInt(strobe.minLight)
    ..writeInt(strobe.maxLight)
    ..writeInt(strobe.darkTime)
    ..writeInt(strobe.brightTime);
}

void _writeGlow(
  GlowThinker glow,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(glow.sector, renderState))
    ..writeInt(glow.minLight)
    ..writeInt(glow.maxLight)
    ..writeInt(glow.direction);
}

void _writeFireFlicker(
  FireFlickerThinker flicker,
  RenderState renderState,
  GameDataWriter writer,
) {
  writer
    ..writeInt(_sectorIndex(flicker.sector, renderState))
    ..writeInt(flicker.count)
    ..writeInt(flicker.maxLight)
    ..writeInt(flicker.minLight);
}

int _sectorIndex(dynamic sector, RenderState renderState) {
  final sectors = renderState.sectors;
  for (var i = 0; i < sectors.length; i++) {
    if (sectors[i] == sector) return i;
  }
  return -1;
}

/// Unarchive all special thinkers from the reader.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_UnArchiveSpecials (void)
/// {
///     byte        tclass;
///     ceiling_t*  ceiling;
///     vldoor_t*   door;
///     floormove_t* floor;
///     plat_t*     plat;
///     lightflash_t* flash;
///     strobe_t*   strobe;
///     glow_t*     glow;
///
///     while (1)
///     {
///         tclass = *save_p++;
///         switch (tclass)
///         {
///             case tc_endspecials:
///                 return;
///             // Handle each type...
///         }
///     }
/// }
/// ```
void unarchiveSpecials(
  LevelLocals level,
  RenderState renderState,
  GameDataReader reader, {
  required ActiveCeilings activeCeilings,
  required ActivePlatforms activePlatforms,
}) {
  while (true) {
    final tclass = reader.readByte();

    switch (tclass) {
      case SpecialClass.endSpecials:
        return;

      case SpecialClass.ceiling:
        reader.skipPadding();
        final ceiling = _readCeiling(renderState, reader);
        ceiling.function =
            (t) => ceilingThink(t as CeilingThinker, activeCeilings, level);
        level.thinkers.add(ceiling);
        activeCeilings.add(ceiling);

      case SpecialClass.door:
        reader.skipPadding();
        final door = _readDoor(renderState, reader);
        door.function = (t) => doorThink(t as DoorThinker, level);
        level.thinkers.add(door);

      case SpecialClass.floor:
        reader.skipPadding();
        final floor = _readFloor(renderState, reader);
        floor.function = (t) => floorThink(t as FloorThinker, level);
        level.thinkers.add(floor);

      case SpecialClass.plat:
        reader.skipPadding();
        final plat = _readPlat(renderState, reader);
        plat.function = (t) => platThink(t as PlatThinker, level);
        level.thinkers.add(plat);
        activePlatforms.add(plat);

      case SpecialClass.flash:
        reader.skipPadding();
        final flash = _readLightFlash(renderState, reader);
        flash.function =
            (t) => lightFlashThink(t as LightFlashThinker, level.random);
        level.thinkers.add(flash);

      case SpecialClass.strobe:
        reader.skipPadding();
        final strobe = _readStrobe(renderState, reader);
        strobe.function = (t) => strobeThink(t as StrobeThinker);
        level.thinkers.add(strobe);

      case SpecialClass.glow:
        reader.skipPadding();
        final glow = _readGlow(renderState, reader);
        glow.function = (t) => glowThink(t as GlowThinker);
        level.thinkers.add(glow);

      case SpecialClass.fireFlicker:
        reader.skipPadding();
        final flicker = _readFireFlicker(renderState, reader);
        flicker.function =
            (t) => fireFlickerThink(t as FireFlickerThinker, level.random);
        level.thinkers.add(flicker);

      default:
        throw StateError('Unknown special class $tclass in save game');
    }
  }
}

CeilingThinker _readCeiling(RenderState renderState, GameDataReader reader) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  final ceiling = CeilingThinker(sector)
    ..type = CeilingType.values[reader.readInt()]
    ..bottomHeight = reader.readFixed()
    ..topHeight = reader.readFixed()
    ..speed = reader.readFixed()
    ..direction = reader.readInt()
    ..oldDirection = reader.readInt()
    ..crush = reader.readBool()
    ..tag = reader.readInt();

  sector.specialData = ceiling;
  return ceiling;
}

DoorThinker _readDoor(RenderState renderState, GameDataReader reader) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  final door = DoorThinker(sector)
    ..type = DoorType.values[reader.readInt()]
    ..topHeight = reader.readFixed()
    ..speed = reader.readFixed()
    ..direction = reader.readInt()
    ..topWait = reader.readInt()
    ..topCountdown = reader.readInt();

  sector.specialData = door;
  return door;
}

FloorThinker _readFloor(RenderState renderState, GameDataReader reader) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  final floor = FloorThinker(sector)
    ..type = FloorType.values[reader.readInt()]
    ..crush = reader.readBool()
    ..direction = reader.readInt()
    ..newSpecial = reader.readInt()
    ..texture = reader.readInt()
    ..floorDestHeight = reader.readFixed()
    ..speed = reader.readFixed();

  sector.specialData = floor;
  return floor;
}

PlatThinker _readPlat(RenderState renderState, GameDataReader reader) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  final plat = PlatThinker(sector)
    ..speed = reader.readFixed()
    ..low = reader.readFixed()
    ..high = reader.readFixed()
    ..wait = reader.readInt()
    ..count = reader.readInt()
    ..status = PlatStatus.values[reader.readInt()]
    ..oldStatus = PlatStatus.values[reader.readInt()]
    ..type = PlatType.values[reader.readInt()]
    ..crush = reader.readBool()
    ..tag = reader.readInt();

  sector.specialData = plat;
  return plat;
}

LightFlashThinker _readLightFlash(
  RenderState renderState,
  GameDataReader reader,
) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  return LightFlashThinker(sector)
    ..count = reader.readInt()
    ..maxLight = reader.readInt()
    ..minLight = reader.readInt()
    ..maxTime = reader.readInt()
    ..minTime = reader.readInt();
}

StrobeThinker _readStrobe(RenderState renderState, GameDataReader reader) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  return StrobeThinker(sector)
    ..count = reader.readInt()
    ..minLight = reader.readInt()
    ..maxLight = reader.readInt()
    ..darkTime = reader.readInt()
    ..brightTime = reader.readInt();
}

GlowThinker _readGlow(RenderState renderState, GameDataReader reader) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  return GlowThinker(sector)
    ..minLight = reader.readInt()
    ..maxLight = reader.readInt()
    ..direction = reader.readInt();
}

FireFlickerThinker _readFireFlicker(
  RenderState renderState,
  GameDataReader reader,
) {
  final sectorIndex = reader.readInt();
  final sector = renderState.sectors[sectorIndex];

  return FireFlickerThinker(sector)
    ..count = reader.readInt()
    ..maxLight = reader.readInt()
    ..minLight = reader.readInt();
}
