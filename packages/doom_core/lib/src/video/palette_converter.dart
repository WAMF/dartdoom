import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _PaletteIndices {
  static const int startRedPals = 1;
  static const int numRedPals = 8;
  static const int startBonusPals = 9;
  static const int numBonusPals = 4;
  static const int radiationPal = 13;
}

class PaletteConverter {
  PaletteConverter();

  final List<Uint32List> _rgbaLookups = [];
  int _currentPalette = 0;

  void loadPalettes(PlayPal playPal) {
    _rgbaLookups.clear();
    for (var i = 0; i < playPal.length; i++) {
      _rgbaLookups.add(playPal[i].toRgba32());
    }
    _currentPalette = 0;
  }

  void setPalette(DoomPalette palette) {
    if (_rgbaLookups.isEmpty) {
      _rgbaLookups.add(palette.toRgba32());
    } else {
      _rgbaLookups[0] = palette.toRgba32();
    }
    _currentPalette = 0;
  }

  void setPaletteIndex(int index) {
    if (index >= 0 && index < _rgbaLookups.length) {
      _currentPalette = index;
    }
  }

  int get currentPaletteIndex => _currentPalette;

  int calculatePaletteForPlayer(Player player) {
    var cnt = player.damageCount;

    if (player.powers[PowerType.strength.index] > 0) {
      final bzc = 12 - (player.powers[PowerType.strength.index] >> 6);
      if (bzc > cnt) {
        cnt = bzc;
      }
    }

    if (cnt > 0) {
      var palette = (cnt + 7) >> 3;
      if (palette >= _PaletteIndices.numRedPals) {
        palette = _PaletteIndices.numRedPals - 1;
      }
      return palette + _PaletteIndices.startRedPals;
    }

    if (player.bonusCount > 0) {
      var palette = (player.bonusCount + 7) >> 3;
      if (palette >= _PaletteIndices.numBonusPals) {
        palette = _PaletteIndices.numBonusPals - 1;
      }
      return palette + _PaletteIndices.startBonusPals;
    }

    final ironFeetPower = player.powers[PowerType.ironFeet.index];
    if (ironFeetPower > 4 * 32 || (ironFeetPower & 8) != 0) {
      return _PaletteIndices.radiationPal;
    }

    return 0;
  }

  void updatePaletteForPlayer(Player player) {
    final newPalette = calculatePaletteForPlayer(player);
    if (newPalette != _currentPalette) {
      setPaletteIndex(newPalette);
    }
  }

  void convertFrame(Uint8List indexed, Uint8List rgba) {
    final lookup = _rgbaLookups.isNotEmpty
        ? _rgbaLookups[_currentPalette]
        : Uint32List(256);
    final pixels = rgba.buffer.asUint32List();
    for (var i = 0; i < indexed.length; i++) {
      pixels[i] = lookup[indexed[i]];
    }
  }

  int getRgba(int colorIndex) {
    if (_rgbaLookups.isEmpty) return 0;
    return _rgbaLookups[_currentPalette][colorIndex];
  }
}
