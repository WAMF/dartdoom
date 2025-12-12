import 'package:doom_wad/doom_wad.dart';

enum LumpCategory {
  maps,
  graphics,
  sprites,
  flats,
  sounds,
  music,
  palettes,
  colormaps,
  textures,
  markers,
  other,
}

class CategorizedLump {
  const CategorizedLump({
    required this.index,
    required this.info,
    required this.category,
    this.groupName,
  });

  final int index;
  final LumpInfo info;
  final LumpCategory category;
  final String? groupName;

  bool get isMarker => info.size == 0;
}

class LumpCategorizer {
  static CategorizedLump categorizeLump(
    int index,
    LumpInfo info,
    List<LumpInfo> lumps,
  ) {
    final category = categorize(info.name, index, lumps, info.size);
    final groupName = _getGroupName(info.name, category);
    return CategorizedLump(
      index: index,
      info: info,
      category: category,
      groupName: groupName,
    );
  }

  static LumpCategory categorize(
    String name,
    int index,
    List<LumpInfo> lumps,
    int size,
  ) {
    final upperName = name.toUpperCase();

    if (_isMarkerLump(upperName, size)) {
      return LumpCategory.markers;
    }

    if (_isMapMarker(upperName)) {
      return LumpCategory.maps;
    }

    if (upperName == 'PLAYPAL') {
      return LumpCategory.palettes;
    }

    if (upperName == 'COLORMAP') {
      return LumpCategory.colormaps;
    }

    if (upperName.startsWith('D_') || upperName.startsWith('MUS_')) {
      return LumpCategory.music;
    }

    if (upperName.startsWith('DS') || upperName.startsWith('DP')) {
      return LumpCategory.sounds;
    }

    if (upperName == 'TEXTURE1' ||
        upperName == 'TEXTURE2' ||
        upperName == 'PNAMES') {
      return LumpCategory.textures;
    }

    if (_isInMarkerRange(index, lumps, 'S_START', 'S_END') ||
        _isInMarkerRange(index, lumps, 'SS_START', 'SS_END')) {
      return LumpCategory.sprites;
    }

    if (_isInMarkerRange(index, lumps, 'F_START', 'F_END') ||
        _isInMarkerRange(index, lumps, 'FF_START', 'FF_END')) {
      return LumpCategory.flats;
    }

    if (_isInMarkerRange(index, lumps, 'P_START', 'P_END') ||
        _isInMarkerRange(index, lumps, 'PP_START', 'PP_END')) {
      return LumpCategory.graphics;
    }

    if (_isGraphicLump(upperName)) {
      return LumpCategory.graphics;
    }

    return LumpCategory.other;
  }

  static bool _isMarkerLump(String name, int size) {
    if (size != 0) return false;
    return _markerNames.contains(name) || name.contains('_START') || name.contains('_END');
  }

  static const _markerNames = {
    'S_START',
    'S_END',
    'SS_START',
    'SS_END',
    'F_START',
    'F_END',
    'FF_START',
    'FF_END',
    'P_START',
    'P_END',
    'PP_START',
    'PP_END',
    'P1_START',
    'P1_END',
    'P2_START',
    'P2_END',
    'P3_START',
    'P3_END',
  };

  static bool _isMapMarker(String name) {
    if (RegExp(r'^E\dM\d$').hasMatch(name)) return true;
    if (RegExp(r'^MAP\d\d$').hasMatch(name)) return true;
    return false;
  }

  static bool _isGraphicLump(String name) {
    const graphicPrefixes = [
      'STBAR',
      'STGNUM',
      'STTNUM',
      'STYSNUM',
      'STKEYS',
      'STARMS',
      'STDISK',
      'STCDROM',
      'M_',
      'BRDR_',
      'WI',
      'INTER',
      'CREDIT',
      'HELP',
      'TITLEPIC',
      'VICTORY',
      'PFUB',
      'END',
      'BOSSBACK',
    ];

    for (final prefix in graphicPrefixes) {
      if (name.startsWith(prefix)) return true;
    }

    return false;
  }

  static bool _isInMarkerRange(
    int index,
    List<LumpInfo> lumps,
    String startMarker,
    String endMarker,
  ) {
    var startIndex = -1;
    var endIndex = -1;

    for (var i = 0; i < lumps.length; i++) {
      final name = lumps[i].name.toUpperCase();
      if (name == startMarker) startIndex = i;
      if (name == endMarker) endIndex = i;
    }

    if (startIndex == -1 || endIndex == -1) return false;
    return index > startIndex && index < endIndex;
  }

  static String? _getGroupName(String name, LumpCategory category) {
    final upperName = name.toUpperCase();

    if (category == LumpCategory.sprites ||
        category == LumpCategory.graphics ||
        category == LumpCategory.flats) {
      return _extractPrefix(upperName);
    }

    return null;
  }

  static String? _extractPrefix(String name) {
    final underscoreIndex = name.indexOf('_');
    if (underscoreIndex >= _minPrefixLength) {
      return name.substring(0, underscoreIndex);
    }

    final digitMatch = RegExp(r'\d').firstMatch(name);
    if (digitMatch != null && digitMatch.start >= _minPrefixLength) {
      return name.substring(0, digitMatch.start);
    }

    if (name.length >= _minPrefixLength) {
      return name.substring(0, _minPrefixLength);
    }

    return null;
  }

  static const _minPrefixLength = 4;

  static List<CategorizedLump> categorizeAll(WadManager wad) {
    final result = <CategorizedLump>[];
    final lumps = <LumpInfo>[];

    for (var i = 0; i < wad.numLumps; i++) {
      lumps.add(wad.getLumpInfo(i));
    }

    for (var i = 0; i < lumps.length; i++) {
      result.add(categorizeLump(i, lumps[i], lumps));
    }

    return result;
  }
}
