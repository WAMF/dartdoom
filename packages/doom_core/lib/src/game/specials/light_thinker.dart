import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class LightConstants {
  static const int glowSpeed = 8;
  static const int strobeBright = 5;
  static const int fastDark = 15;
  static const int slowDark = 35;
}

abstract final class GlowDirection {
  static const int down = -1;
  static const int up = 1;
}

class FireFlickerThinker extends Thinker {
  FireFlickerThinker(this.sector);

  final Sector sector;
  int count = 4;
  int maxLight = 0;
  int minLight = 0;
}

class LightFlashThinker extends Thinker {
  LightFlashThinker(this.sector);

  final Sector sector;
  int count = 0;
  int maxLight = 0;
  int minLight = 0;
  int maxTime = 64;
  int minTime = 7;
}

class StrobeThinker extends Thinker {
  StrobeThinker(this.sector);

  final Sector sector;
  int count = 0;
  int minLight = 0;
  int maxLight = 0;
  int darkTime = 0;
  int brightTime = LightConstants.strobeBright;
}

class GlowThinker extends Thinker {
  GlowThinker(this.sector);

  final Sector sector;
  int minLight = 0;
  int maxLight = 0;
  int direction = GlowDirection.down;
}

void fireFlickerThink(FireFlickerThinker flicker, DoomRandom random) {
  flicker.count--;
  if (flicker.count > 0) return;

  final amount = (random.pRandom() & 3) * 16;

  if (flicker.sector.lightLevel - amount < flicker.minLight) {
    flicker.sector.lightLevel = flicker.minLight;
  } else {
    flicker.sector.lightLevel = flicker.maxLight - amount;
  }

  flicker.count = 4;
}

void lightFlashThink(LightFlashThinker flash, DoomRandom random) {
  flash.count--;
  if (flash.count > 0) return;

  if (flash.sector.lightLevel == flash.maxLight) {
    flash.sector.lightLevel = flash.minLight;
    flash.count = (random.pRandom() & flash.minTime) + 1;
  } else {
    flash.sector.lightLevel = flash.maxLight;
    flash.count = (random.pRandom() & flash.maxTime) + 1;
  }
}

void strobeThink(StrobeThinker strobe) {
  strobe.count--;
  if (strobe.count > 0) return;

  if (strobe.sector.lightLevel == strobe.minLight) {
    strobe.sector.lightLevel = strobe.maxLight;
    strobe.count = strobe.brightTime;
  } else {
    strobe.sector.lightLevel = strobe.minLight;
    strobe.count = strobe.darkTime;
  }
}

void glowThink(GlowThinker glow) {
  switch (glow.direction) {
    case GlowDirection.down:
      glow.sector.lightLevel -= LightConstants.glowSpeed;
      if (glow.sector.lightLevel <= glow.minLight) {
        glow.sector.lightLevel += LightConstants.glowSpeed;
        glow.direction = GlowDirection.up;
      }

    case GlowDirection.up:
      glow.sector.lightLevel += LightConstants.glowSpeed;
      if (glow.sector.lightLevel >= glow.maxLight) {
        glow.sector.lightLevel -= LightConstants.glowSpeed;
        glow.direction = GlowDirection.down;
      }
  }
}

FireFlickerThinker spawnFireFlicker(
  Sector sector,
  LevelLocals level,
  DoomRandom random,
) {
  sector.special = 0;

  final flicker = FireFlickerThinker(sector)
    ..maxLight = sector.lightLevel
    ..minLight = _findMinSurroundingLight(sector) + 16
    ..count = 4;

  level.thinkers.add(flicker);
  flicker.function = (_) => fireFlickerThink(flicker, random);

  return flicker;
}

LightFlashThinker spawnLightFlash(
  Sector sector,
  LevelLocals level,
  DoomRandom random,
) {
  sector.special = 0;

  final flash = LightFlashThinker(sector)
    ..maxLight = sector.lightLevel
    ..minLight = _findMinSurroundingLight(sector)
    ..maxTime = 64
    ..minTime = 7
    ..count = (random.pRandom() & 64) + 1;

  level.thinkers.add(flash);
  flash.function = (_) => lightFlashThink(flash, random);

  return flash;
}

StrobeThinker spawnStrobeFlash(
  Sector sector,
  int fastOrSlow,
  LevelLocals level,
  DoomRandom random, {
  required bool inSync,
}) {
  final strobe = StrobeThinker(sector)
    ..darkTime = fastOrSlow
    ..brightTime = LightConstants.strobeBright
    ..maxLight = sector.lightLevel
    ..minLight = _findMinSurroundingLight(sector);

  if (strobe.minLight == strobe.maxLight) {
    strobe.minLight = 0;
  }

  sector.special = 0;

  if (inSync) {
    strobe.count = 1;
  } else {
    strobe.count = (random.pRandom() & 7) + 1;
  }

  level.thinkers.add(strobe);
  strobe.function = (_) => strobeThink(strobe);

  return strobe;
}

GlowThinker spawnGlowingLight(Sector sector, LevelLocals level) {
  final glow = GlowThinker(sector)
    ..minLight = _findMinSurroundingLight(sector)
    ..maxLight = sector.lightLevel
    ..direction = GlowDirection.down;

  sector.special = 0;

  level.thinkers.add(glow);
  glow.function = (_) => glowThink(glow);

  return glow;
}

void evStartLightStrobing(Line line, LevelLocals level, DoomRandom random) {
  final sectors = _findSectorsFromTag(line.tag, level);
  for (final sector in sectors) {
    if (sector.specialData != null) continue;
    spawnStrobeFlash(
      sector,
      LightConstants.slowDark,
      level,
      random,
      inSync: false,
    );
  }
}

void evTurnTagLightsOff(Line line, LevelLocals level) {
  for (final sector in level.renderState.sectors) {
    if (sector.tag == line.tag) {
      var minLight = sector.lightLevel;
      for (final secLine in sector.lines) {
        final neighbor = _getNextSector(secLine, sector);
        if (neighbor != null && neighbor.lightLevel < minLight) {
          minLight = neighbor.lightLevel;
        }
      }
      sector.lightLevel = minLight;
    }
  }
}

void evLightTurnOn(Line line, int bright, LevelLocals level) {
  for (final sector in level.renderState.sectors) {
    if (sector.tag == line.tag) {
      var targetBright = bright;
      if (targetBright == 0) {
        for (final secLine in sector.lines) {
          final neighbor = _getNextSector(secLine, sector);
          if (neighbor != null && neighbor.lightLevel > targetBright) {
            targetBright = neighbor.lightLevel;
          }
        }
      }
      sector.lightLevel = targetBright;
    }
  }
}

List<Sector> _findSectorsFromTag(int tag, LevelLocals level) {
  final result = <Sector>[];
  for (final sector in level.renderState.sectors) {
    if (sector.tag == tag) {
      result.add(sector);
    }
  }
  return result;
}

int _findMinSurroundingLight(Sector sector) {
  var light = sector.lightLevel;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null && other.lightLevel < light) {
      light = other.lightLevel;
    }
  }

  return light;
}

Sector? _getNextSector(Line line, Sector sector) {
  if ((line.flags & _LineFlags.twoSided) == 0) return null;

  if (line.frontSector == sector) {
    return line.backSector;
  }
  return line.frontSector;
}

abstract final class _LineFlags {
  static const int twoSided = 0x04;
}
