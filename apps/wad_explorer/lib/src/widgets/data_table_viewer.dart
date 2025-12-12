import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';

class DataTableViewer extends StatelessWidget {
  const DataTableViewer({
    required this.lumpData,
    required this.lumpName,
    super.key,
  });

  final Uint8List lumpData;
  final String lumpName;

  @override
  Widget build(BuildContext context) {
    final upperName = lumpName.toUpperCase();

    if (_MapLumpNames.things.contains(upperName)) {
      return _ThingsTable(data: lumpData);
    }

    if (_MapLumpNames.linedefs.contains(upperName)) {
      return _LinedefsTable(data: lumpData);
    }

    if (_MapLumpNames.sidedefs.contains(upperName)) {
      return _SidedefsTable(data: lumpData);
    }

    if (_MapLumpNames.vertexes.contains(upperName)) {
      return _VertexesTable(data: lumpData);
    }

    if (_MapLumpNames.sectors.contains(upperName)) {
      return _SectorsTable(data: lumpData);
    }

    return const SizedBox.shrink();
  }
}

class _MapLumpNames {
  static const things = {'THINGS'};
  static const linedefs = {'LINEDEFS'};
  static const sidedefs = {'SIDEDEFS'};
  static const vertexes = {'VERTEXES'};
  static const sectors = {'SECTORS'};
}

class _LumpSizes {
  static const int thing = 10;
  static const int linedef = 14;
  static const int sidedef = 30;
  static const int vertex = 4;
  static const int sector = 26;
}

class _ThingsTable extends StatelessWidget {
  const _ThingsTable({required this.data});

  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    final count = data.length ~/ _LumpSizes.thing;
    final reader = WadReader(ByteData.sublistView(data));
    final things = List.generate(count, (_) => MapThing.parse(reader));

    return _buildTable(
      context,
      columns: const ['#', 'X', 'Y', 'Angle', 'Type', 'Options'],
      rowCount: things.length,
      cellBuilder: (row, col) => switch (col) {
        0 => row.toString(),
        1 => things[row].x.toString(),
        2 => things[row].y.toString(),
        3 => things[row].angle.toString(),
        4 => things[row].type.toString(),
        5 => things[row].options.toRadixString(16),
        _ => '',
      },
    );
  }
}

class _LinedefsTable extends StatelessWidget {
  const _LinedefsTable({required this.data});

  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    final count = data.length ~/ _LumpSizes.linedef;
    final reader = WadReader(ByteData.sublistView(data));
    final linedefs = List.generate(count, (_) => MapLinedef.parse(reader));

    return _buildTable(
      context,
      columns: const [
        '#',
        'V1',
        'V2',
        'Flags',
        'Special',
        'Tag',
        'Side0',
        'Side1',
      ],
      rowCount: linedefs.length,
      cellBuilder: (row, col) => switch (col) {
        0 => row.toString(),
        1 => linedefs[row].v1.toString(),
        2 => linedefs[row].v2.toString(),
        3 => linedefs[row].flags.toRadixString(16),
        4 => linedefs[row].special.toString(),
        5 => linedefs[row].tag.toString(),
        6 => linedefs[row].sidenum0.toString(),
        7 => linedefs[row].sidenum1.toString(),
        _ => '',
      },
    );
  }
}

class _SidedefsTable extends StatelessWidget {
  const _SidedefsTable({required this.data});

  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    final count = data.length ~/ _LumpSizes.sidedef;
    final reader = WadReader(ByteData.sublistView(data));
    final sidedefs = List.generate(count, (_) => MapSidedef.parse(reader));

    return _buildTable(
      context,
      columns: const [
        '#',
        'X Off',
        'Y Off',
        'Top',
        'Bottom',
        'Mid',
        'Sector',
      ],
      rowCount: sidedefs.length,
      cellBuilder: (row, col) => switch (col) {
        0 => row.toString(),
        1 => sidedefs[row].textureOffsetX.toString(),
        2 => sidedefs[row].textureOffsetY.toString(),
        3 => sidedefs[row].topTexture,
        4 => sidedefs[row].bottomTexture,
        5 => sidedefs[row].midTexture,
        6 => sidedefs[row].sector.toString(),
        _ => '',
      },
    );
  }
}

class _VertexesTable extends StatelessWidget {
  const _VertexesTable({required this.data});

  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    final count = data.length ~/ _LumpSizes.vertex;
    final reader = WadReader(ByteData.sublistView(data));
    final vertexes = List.generate(count, (_) => MapVertex.parse(reader));

    return _buildTable(
      context,
      columns: const ['#', 'X', 'Y'],
      rowCount: vertexes.length,
      cellBuilder: (row, col) => switch (col) {
        0 => row.toString(),
        1 => vertexes[row].x.toString(),
        2 => vertexes[row].y.toString(),
        _ => '',
      },
    );
  }
}

class _SectorsTable extends StatelessWidget {
  const _SectorsTable({required this.data});

  final Uint8List data;

  @override
  Widget build(BuildContext context) {
    final count = data.length ~/ _LumpSizes.sector;
    final reader = WadReader(ByteData.sublistView(data));
    final sectors = List.generate(count, (_) => MapSector.parse(reader));

    return _buildTable(
      context,
      columns: const [
        '#',
        'Floor',
        'Ceiling',
        'Floor Pic',
        'Ceil Pic',
        'Light',
        'Special',
        'Tag',
      ],
      rowCount: sectors.length,
      cellBuilder: (row, col) => switch (col) {
        0 => row.toString(),
        1 => sectors[row].floorHeight.toString(),
        2 => sectors[row].ceilingHeight.toString(),
        3 => sectors[row].floorPic,
        4 => sectors[row].ceilingPic,
        5 => sectors[row].lightLevel.toString(),
        6 => sectors[row].special.toString(),
        7 => sectors[row].tag.toString(),
        _ => '',
      },
    );
  }
}

Widget _buildTable(
  BuildContext context, {
  required List<String> columns,
  required int rowCount,
  required String Function(int row, int col) cellBuilder,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          '$rowCount entries',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: columns
              .map(
                (col) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      col,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: rowCount,
          itemBuilder: (context, row) {
            return ColoredBox(
              color: row.isEven
                  ? Colors.transparent
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
              child: Row(
                children: List.generate(
                  columns.length,
                  (col) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        cellBuilder(row, col),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
