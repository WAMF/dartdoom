import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';
import 'package:wad_explorer/src/models/lump_category.dart';
import 'package:wad_explorer/src/widgets/data_table_viewer.dart';
import 'package:wad_explorer/src/widgets/hex_viewer.dart';
import 'package:wad_explorer/src/widgets/image_viewer.dart';

class LumpDetailViewer extends StatelessWidget {
  const LumpDetailViewer({
    required this.lumpData,
    required this.lumpInfo,
    required this.category,
    required this.palette,
    super.key,
  });

  final Uint8List lumpData;
  final LumpInfo lumpInfo;
  final LumpCategory category;
  final DoomPalette palette;

  @override
  Widget build(BuildContext context) {
    if (lumpData.isEmpty) {
      return _buildMarkerView(context);
    }

    return switch (category) {
      LumpCategory.graphics ||
      LumpCategory.sprites =>
        ImageViewer(
          lumpData: lumpData,
          palette: palette,
          isFlat: false,
        ),
      LumpCategory.flats => ImageViewer(
          lumpData: lumpData,
          palette: palette,
          isFlat: true,
        ),
      LumpCategory.palettes => _PaletteViewer(data: lumpData),
      LumpCategory.colormaps =>
        _ColormapViewer(data: lumpData, palette: palette),
      LumpCategory.markers => _buildMarkerView(context),
      _ => _buildDataViewer(),
    };
  }

  Widget _buildMarkerView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            lumpInfo.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Marker lump (0 bytes)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            _getMarkerDescription(lumpInfo.name),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMarkerDescription(String name) {
    final upperName = name.toUpperCase();
    if (upperName.contains('S_START') || upperName.contains('S_END')) {
      return 'Marks the start/end of sprite lumps';
    }
    if (upperName.contains('F_START') || upperName.contains('F_END')) {
      return 'Marks the start/end of flat (floor/ceiling) lumps';
    }
    if (upperName.contains('P_START') || upperName.contains('P_END')) {
      return 'Marks the start/end of patch lumps';
    }
    return 'Section marker lump';
  }

  Widget _buildDataViewer() {
    final hasStructuredData = _hasStructuredViewer(lumpInfo.name);

    if (!hasStructuredData) {
      return HexViewer(data: lumpData);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Data'),
              Tab(text: 'Hex'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                DataTableViewer(
                  lumpData: lumpData,
                  lumpName: lumpInfo.name,
                ),
                HexViewer(data: lumpData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _hasStructuredViewer(String name) {
    final upperName = name.toUpperCase();
    return _structuredLumpNames.contains(upperName);
  }

  static const _structuredLumpNames = {
    'THINGS',
    'LINEDEFS',
    'SIDEDEFS',
    'VERTEXES',
    'SECTORS',
    'PNAMES',
    'TEXTURE1',
    'TEXTURE2',
  };
}

class _PaletteViewer extends StatelessWidget {
  const _PaletteViewer({required this.data});

  final Uint8List data;

  static const int _colorsPerPalette = 256;
  static const int _bytesPerColor = 3;
  static const int _colorsPerRow = 16;

  @override
  Widget build(BuildContext context) {
    final paletteCount = data.length ~/ (_colorsPerPalette * _bytesPerColor);

    return DefaultTabController(
      length: paletteCount,
      child: Column(
        children: [
          if (paletteCount > 1)
            TabBar(
              isScrollable: true,
              tabs: List.generate(
                paletteCount,
                (i) => Tab(text: 'Palette $i'),
              ),
            ),
          Expanded(
            child: TabBarView(
              children: List.generate(
                paletteCount,
                _buildPaletteGrid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteGrid(int paletteIndex) {
    final baseOffset = paletteIndex * _colorsPerPalette * _bytesPerColor;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _colorsPerRow,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _colorsPerPalette,
      itemBuilder: (context, index) {
        final offset = baseOffset + index * _bytesPerColor;
        final r = data[offset];
        final g = data[offset + 1];
        final b = data[offset + 2];

        return Tooltip(
          message: '$index: RGB($r, $g, $b)',
          child: ColoredBox(
            color: Color.fromARGB(255, r, g, b),
          ),
        );
      },
    );
  }
}

class _ColormapViewer extends StatelessWidget {
  const _ColormapViewer({
    required this.data,
    required this.palette,
  });

  final Uint8List data;
  final DoomPalette palette;

  static const int _colorsPerMap = 256;
  static const int _colorsPerRow = 16;

  @override
  Widget build(BuildContext context) {
    final mapCount = data.length ~/ _colorsPerMap;

    return DefaultTabController(
      length: mapCount,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: List.generate(
              mapCount,
              (i) => Tab(text: 'Map $i'),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: List.generate(
                mapCount,
                _buildColormapGrid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColormapGrid(int mapIndex) {
    final baseOffset = mapIndex * _colorsPerMap;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _colorsPerRow,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _colorsPerMap,
      itemBuilder: (context, index) {
        final mappedIndex = data[baseOffset + index];
        final r = palette.getRed(mappedIndex);
        final g = palette.getGreen(mappedIndex);
        final b = palette.getBlue(mappedIndex);

        return Tooltip(
          message: '$index → $mappedIndex',
          child: ColoredBox(
            color: Color.fromARGB(255, r, g, b),
          ),
        );
      },
    );
  }
}
