import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/serialization/game_serializer.dart';
import 'package:doom_math/doom_math.dart';

/// Archive world state (sectors, linedefs, sidedefs) to the writer.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_ArchiveWorld (void)
/// {
///     int         i, j;
///     sector_t*   sec;
///     line_t*     li;
///     side_t*     si;
///
///     // do sectors
///     for (i=0, sec = sectors ; i<numsectors ; i++,sec++)
///     {
///         *((short *)save_p) = sec->floorheight >> FRACBITS; save_p += 2;
///         *((short *)save_p) = sec->ceilingheight >> FRACBITS; save_p += 2;
///         *((short *)save_p) = sec->floorpic; save_p += 2;
///         *((short *)save_p) = sec->ceilingpic; save_p += 2;
///         *((short *)save_p) = sec->lightlevel; save_p += 2;
///         *((short *)save_p) = sec->special; save_p += 2;
///         *((short *)save_p) = sec->tag; save_p += 2;
///     }
///
///     // do lines
///     for (i=0, li = lines ; i<numlines ; i++,li++)
///     {
///         *((short *)save_p) = li->flags; save_p += 2;
///         *((short *)save_p) = li->special; save_p += 2;
///         *((short *)save_p) = li->tag; save_p += 2;
///         for (j=0 ; j<2 ; j++)
///         {
///             if (li->sidenum[j] == -1)
///                 continue;
///             si = &sides[li->sidenum[j]];
///             *((short *)save_p) = si->textureoffset >> FRACBITS; save_p += 2;
///             *((short *)save_p) = si->rowoffset >> FRACBITS; save_p += 2;
///             *((short *)save_p) = si->toptexture; save_p += 2;
///             *((short *)save_p) = si->bottomtexture; save_p += 2;
///             *((short *)save_p) = si->midtexture; save_p += 2;
///         }
///     }
/// }
/// ```
void archiveWorld(RenderState renderState, GameDataWriter writer) {
  final sectors = renderState.sectors;
  final lines = renderState.lines;

  // Archive sectors
  for (final sector in sectors) {
    writer
      // Heights stored as plain integers (>>FRACBITS)
      ..writeShort(sector.floorHeight >> Fixed32.fracBits)
      ..writeShort(sector.ceilingHeight >> Fixed32.fracBits)
      ..writeShort(sector.floorPic)
      ..writeShort(sector.ceilingPic)
      ..writeShort(sector.lightLevel)
      ..writeShort(sector.special)
      ..writeShort(sector.tag);
  }

  // Archive lines
  for (final line in lines) {
    writer
      ..writeShort(line.flags)
      ..writeShort(line.special)
      ..writeShort(line.tag);

    // Archive sides
    for (var j = 0; j < 2; j++) {
      if (line.sideNum[j] == -1) continue;

      final side = j == 0 ? line.frontSide : line.backSide;
      if (side == null) continue;

      writer
        // Offsets stored as plain integers (>>FRACBITS)
        ..writeShort(side.textureOffset >> Fixed32.fracBits)
        ..writeShort(side.rowOffset >> Fixed32.fracBits)
        ..writeShort(side.topTexture)
        ..writeShort(side.bottomTexture)
        ..writeShort(side.midTexture);
    }
  }
}

/// Unarchive world state (sectors, linedefs, sidedefs) from the reader.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_UnArchiveWorld (void)
/// {
///     int         i, j;
///     sector_t*   sec;
///     line_t*     li;
///     side_t*     si;
///
///     // do sectors
///     for (i=0, sec = sectors ; i<numsectors ; i++,sec++)
///     {
///         sec->floorheight = *((short *)save_p) << FRACBITS; save_p += 2;
///         sec->ceilingheight = *((short *)save_p) << FRACBITS; save_p += 2;
///         sec->floorpic = *((short *)save_p); save_p += 2;
///         sec->ceilingpic = *((short *)save_p); save_p += 2;
///         sec->lightlevel = *((short *)save_p); save_p += 2;
///         sec->special = *((short *)save_p); save_p += 2;
///         sec->tag = *((short *)save_p); save_p += 2;
///         sec->specialdata = 0;
///         sec->soundtarget = 0;
///     }
///
///     // do lines
///     for (i=0, li = lines ; i<numlines ; i++,li++)
///     {
///         li->flags = *((short *)save_p); save_p += 2;
///         li->special = *((short *)save_p); save_p += 2;
///         li->tag = *((short *)save_p); save_p += 2;
///         for (j=0 ; j<2 ; j++)
///         {
///             if (li->sidenum[j] == -1)
///                 continue;
///             si = &sides[li->sidenum[j]];
///             si->textureoffset = *((short *)save_p) << FRACBITS; save_p += 2;
///             si->rowoffset = *((short *)save_p) << FRACBITS; save_p += 2;
///             si->toptexture = *((short *)save_p); save_p += 2;
///             si->bottomtexture = *((short *)save_p); save_p += 2;
///             si->midtexture = *((short *)save_p); save_p += 2;
///         }
///     }
/// }
/// ```
void unarchiveWorld(RenderState renderState, GameDataReader reader) {
  final sectors = renderState.sectors;
  final lines = renderState.lines;

  // Unarchive sectors
  for (final sector in sectors) {
    sector
      // Heights converted back to fixed-point (<<FRACBITS)
      ..floorHeight = reader.readShort() << Fixed32.fracBits
      ..ceilingHeight = reader.readShort() << Fixed32.fracBits
      ..floorPic = reader.readShort()
      ..ceilingPic = reader.readShort()
      ..lightLevel = reader.readShort()
      ..special = reader.readShort()
      ..tag = reader.readShort()
      // Clear runtime pointers
      ..specialData = null
      ..soundTarget = null;
  }

  // Unarchive lines
  for (final line in lines) {
    line
      ..flags = reader.readShort()
      ..special = reader.readShort()
      ..tag = reader.readShort();

    // Unarchive sides
    for (var j = 0; j < 2; j++) {
      if (line.sideNum[j] == -1) continue;

      final side = j == 0 ? line.frontSide : line.backSide;
      if (side == null) continue;

      side
        // Offsets converted back to fixed-point (<<FRACBITS)
        ..textureOffset = reader.readShort() << Fixed32.fracBits
        ..rowOffset = reader.readShort() << Fixed32.fracBits
        ..topTexture = reader.readShort()
        ..bottomTexture = reader.readShort()
        ..midTexture = reader.readShort();
    }
  }
}
