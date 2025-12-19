import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_mobj.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/serialization/game_serializer.dart';

/// Thinker type tags for save/load.
abstract final class ThinkerClass {
  static const int end = 0;
  static const int mobj = 1;
}

/// Archive all thinkers (primarily Mobj instances) to the writer.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_ArchiveThinkers (void)
/// {
///     thinker_t* th;
///     for (th = thinkercap.next ; th != &thinkercap ; th=th->next)
///     {
///         if (th->function.acp1 == (actionf_p1)P_MobjThinker)
///         {
///             *save_p++ = tc_mobj;
///             PADSAVEP();
///             memcpy (save_p, th, sizeof(mobj_t));
///             save_p += sizeof(mobj_t);
///             mobj = (mobj_t *)save_p;
///             mobj->state = (state_t *)(mobj->state - states);
///             if (mobj->player)
///                 mobj->player = (player_t *)((mobj->player-players) + 1);
///         }
///     }
///     *save_p++ = tc_end;
/// }
/// ```
void archiveThinkers(
  LevelLocals level,
  RenderState renderState,
  GameDataWriter writer,
) {
  // Iterate through all thinkers
  for (final thinker in level.thinkers.all) {
    // Check if this is a MobjThinker (has an associated Mobj)
    // In our implementation, we look for Mobj instances in sectors
    if (thinker.function != null) {
      // For now we handle this by iterating sectors directly
      // since our thinker system is structured differently
    }
  }

  // Archive all mobjs by iterating through sectors
  for (final sector in renderState.sectors) {
    var mobj = sector.thingList;
    while (mobj != null) {
      writer.writeByte(ThinkerClass.mobj);
      writer.pad();
      _writeMobj(mobj, level, writer);
      mobj = mobj.sNext;
    }
  }

  // Write end marker
  writer.writeByte(ThinkerClass.end);
}

void _writeMobj(Mobj mobj, LevelLocals level, GameDataWriter writer) {
  // Position
  writer
    ..writeFixed(mobj.x)
    ..writeFixed(mobj.y)
    ..writeFixed(mobj.z)

    // Angle and sprite info
    ..writeInt(mobj.angle)
    ..writeInt(mobj.sprite)
    ..writeInt(mobj.frame)

    // Floor/ceiling
    ..writeFixed(mobj.floorZ)
    ..writeFixed(mobj.ceilingZ)

    // Size
    ..writeFixed(mobj.radius)
    ..writeFixed(mobj.height)

    // Momentum
    ..writeFixed(mobj.momX)
    ..writeFixed(mobj.momY)
    ..writeFixed(mobj.momZ)

    // Type and state
    ..writeInt(mobj.type)
    ..writeInt(mobj.stateNum) // State stored as state number
    ..writeInt(mobj.tics)
    ..writeInt(mobj.flags)
    ..writeInt(mobj.health)

    // Movement
    ..writeInt(mobj.moveDir)
    ..writeInt(mobj.moveCount)

    // Reaction
    ..writeInt(mobj.reactionTime)
    ..writeInt(mobj.threshold)
    ..writeInt(mobj.lastLook)

    // Spawn info
    ..writeFixed(mobj.spawnX)
    ..writeFixed(mobj.spawnY)
    ..writeInt(mobj.spawnAngle)
    ..writeInt(mobj.spawnType)
    ..writeInt(mobj.spawnOptions);

  // Player reference: store player index (1-indexed) or 0 if not a player
  final player = mobj.player;
  if (player != null && player is! int) {
    // Find player index
    for (var i = 0; i < level.players.length; i++) {
      if (level.players[i] == player) {
        writer.writeInt(i + 1); // 1-indexed like original
        break;
      }
    }
  } else {
    writer.writeInt(0);
  }

  // Target and tracer are not saved - they're runtime computed
  // (original DOOM sets them to NULL on load)
}

/// Unarchive all thinkers from the reader.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_UnArchiveThinkers (void)
/// {
///     byte        tclass;
///     thinker_t*  currentthinker;
///     thinker_t*  next;
///     mobj_t*     mobj;
///
///     // remove all the current thinkers
///     currentthinker = thinkercap.next;
///     while (currentthinker != &thinkercap)
///     {
///         next = currentthinker->next;
///         if (currentthinker->function.acp1 == (actionf_p1)P_MobjThinker)
///             P_RemoveMobj ((mobj_t *)currentthinker);
///         else
///             Z_Free (currentthinker);
///         currentthinker = next;
///     }
///     P_InitThinkers ();
///
///     // read in saved thinkers
///     while (1)
///     {
///         tclass = *save_p++;
///         switch (tclass)
///         {
///           case tc_end:
///             return; // end of list
///           case tc_mobj:
///             PADSAVEP();
///             mobj = Z_Malloc (sizeof(*mobj), PU_LEVEL, NULL);
///             memcpy (mobj, save_p, sizeof(*mobj));
///             save_p += sizeof(*mobj);
///             mobj->state = &states[(int)mobj->state];
///             mobj->target = NULL;
///             if (mobj->player)
///             {
///                 mobj->player = &players[(int)mobj->player-1];
///                 mobj->player->mo = mobj;
///             }
///             P_SetThingPosition (mobj);
///             mobj->info = &mobjinfo[mobj->type];
///             mobj->floorz = mobj->subsector->sector->floorheight;
///             mobj->ceilingz = mobj->subsector->sector->ceilingheight;
///             mobj->thinker.function.acp1 = (actionf_p1)P_MobjThinker;
///             P_AddThinker (&mobj->thinker);
///             break;
///           default:
///             I_Error ("Unknown tclass %i in savegame",tclass);
///         }
///     }
/// }
/// ```
void unarchiveThinkers(
  LevelLocals level,
  RenderState renderState,
  GameDataReader reader,
  void Function(Mobj mobj) setThingPosition,
) {
  // Clear existing mobjs from sectors
  for (final sector in renderState.sectors) {
    sector.thingList = null;
  }

  // Re-initialize thinkers
  level.thinkers.init();

  // Read thinkers until end marker
  while (true) {
    final tclass = reader.readByte();

    switch (tclass) {
      case ThinkerClass.end:
        return;

      case ThinkerClass.mobj:
        reader.skipPadding();
        final mobj = _readMobj(level, reader);

        // Set thing position (links to sector/blockmap)
        setThingPosition(mobj);

        // Note: mobj.info is not restored here because:
        // 1. All mobj data is already serialized/deserialized
        // 2. The MobjInfo is stored in multiple private maps in p_mobj.dart
        // 3. The spawned mobj retains all properties from the save file
        // If MobjInfo is needed later, expose getMobjInfo(type) from p_mobj.dart

        // Update floor/ceiling from subsector
        final ss = mobj.subsector;
        if (ss != null && ss is Subsector) {
          mobj
            ..floorZ = ss.sector.floorHeight
            ..ceilingZ = ss.sector.ceilingHeight;
        }

        // Add mobj thinker
        final thinker = MobjThinker(mobj);
        thinker.function = (t) => mobjThinker((t as MobjThinker).mobj, level);
        level.thinkers.add(thinker);

      default:
        throw StateError('Unknown thinker class $tclass in save game');
    }
  }
}

Mobj _readMobj(LevelLocals level, GameDataReader reader) {
  final mobj = Mobj()
    // Position
    ..x = reader.readFixed()
    ..y = reader.readFixed()
    ..z = reader.readFixed()

    // Angle and sprite info
    ..angle = reader.readInt()
    ..sprite = reader.readInt()
    ..frame = reader.readInt()

    // Floor/ceiling
    ..floorZ = reader.readFixed()
    ..ceilingZ = reader.readFixed()

    // Size
    ..radius = reader.readFixed()
    ..height = reader.readFixed()

    // Momentum
    ..momX = reader.readFixed()
    ..momY = reader.readFixed()
    ..momZ = reader.readFixed()

    // Type and state
    ..type = reader.readInt()
    ..stateNum = reader.readInt()
    ..tics = reader.readInt()
    ..flags = reader.readInt()
    ..health = reader.readInt()

    // Movement
    ..moveDir = reader.readInt()
    ..moveCount = reader.readInt()

    // Reaction
    ..reactionTime = reader.readInt()
    ..threshold = reader.readInt()
    ..lastLook = reader.readInt()

    // Spawn info
    ..spawnX = reader.readFixed()
    ..spawnY = reader.readFixed()
    ..spawnAngle = reader.readInt()
    ..spawnType = reader.readInt()
    ..spawnOptions = reader.readInt();

  // Player reference
  final playerNum = reader.readInt();
  if (playerNum > 0 && playerNum <= level.players.length) {
    final player = level.players[playerNum - 1];
    mobj.player = player;
    player.mobj = mobj;
  }

  // Clear runtime pointers
  mobj
    ..target = null
    ..tracer = null;

  return mobj;
}

/// Mobj thinker wrapper for the thinker list.
class MobjThinker extends Thinker {
  MobjThinker(this.mobj);

  final Mobj mobj;
}
