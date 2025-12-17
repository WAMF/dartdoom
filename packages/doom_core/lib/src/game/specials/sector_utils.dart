import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_wad/doom_wad.dart';

Sector? getNextSector(Line line, Sector sector) {
  if ((line.flags & LineFlags.twoSided) == 0) return null;

  if (line.frontSector == sector) {
    return line.backSector;
  }
  return line.frontSector;
}
