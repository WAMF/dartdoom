import 'dart:math' as math;

import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';

abstract final class _MapColors {
  static const Color wall = Color(0xFFFC0000);
  static const Color floorChange = Color(0xFF8B4513);
  static const Color ceilingChange = Color(0xFFCDCD00);
  static const Color twoSided = Color(0xFF606060);
  static const Color player = Color(0xFFFFFFFF);
  static const Color thing = Color(0xFF00B000);
  static const Color background = Color(0xFF000000);
  static const Color grid = Color(0xFF404040);
}

abstract final class _LineFlags {
  static const int twoSided = 0x04;
  static const int dontDraw = 0x80;
}

abstract final class _ThingTypes {
  static const Set<int> playerStarts = {1, 2, 3, 4};
}

class MapViewer extends StatefulWidget {
  const MapViewer({
    required this.wadManager,
    required this.mapName,
    super.key,
  });

  final WadManager wadManager;
  final String mapName;

  @override
  State<MapViewer> createState() => _MapViewerState();
}

class _MapViewerState extends State<MapViewer> {
  MapData? _mapData;
  String? _error;
  bool _showThings = true;
  bool _showGrid = true;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  @override
  void didUpdateWidget(MapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapName != widget.mapName ||
        oldWidget.wadManager != widget.wadManager) {
      _loadMap();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _loadMap() {
    setState(() {
      _mapData = null;
      _error = null;
    });

    try {
      final loader = MapLoader(widget.wadManager);
      final mapData = loader.loadMap(widget.mapName);

      setState(() {
        _mapData = mapData;
      });
      _centerMap();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _centerMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapData == null || !mounted) return;

      final bounds = _calculateBounds(_mapData!);
      final mapWidth = bounds.width;
      final mapHeight = bounds.height;

      if (mapWidth <= 0 || mapHeight <= 0) return;

      final viewSize = context.size;
      if (viewSize == null) return;

      final scaleX = (viewSize.width - 40) / mapWidth;
      final scaleY = (viewSize.height - 80) / mapHeight;
      final scale = math.min(scaleX, scaleY) * 0.9;

      final centerX = bounds.left + mapWidth / 2;
      final centerY = bounds.top + mapHeight / 2;

      final matrix = Matrix4.translationValues(
        viewSize.width / 2,
        viewSize.height / 2,
        0,
      )
        ..multiply(Matrix4.diagonal3Values(scale, -scale, 1))
        ..multiply(Matrix4.translationValues(-centerX, -centerY, 0));

      _transformController.value = matrix;
    });
  }

  Rect _calculateBounds(MapData mapData) {
    if (mapData.vertices.isEmpty) {
      return Rect.zero;
    }

    var minX = mapData.vertices.first.x.fixedToDouble();
    var maxX = minX;
    var minY = mapData.vertices.first.y.fixedToDouble();
    var maxY = minY;

    for (final vertex in mapData.vertices) {
      minX = math.min(minX, vertex.x.fixedToDouble());
      maxX = math.max(maxX, vertex.x.fixedToDouble());
      minY = math.min(minY, vertex.y.fixedToDouble());
      maxY = math.max(maxY, vertex.y.fixedToDouble());
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_mapData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: ColoredBox(
            color: _MapColors.background,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.01,
              maxScale: 50,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _MapPainter(
                    mapData: _mapData!,
                    showThings: _showThings,
                    showGrid: _showGrid,
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildToolbar() {
    final stats = _mapData != null
        ? '${_mapData!.vertices.length} vertices, '
            '${_mapData!.linedefs.length} lines, '
            '${_mapData!.sectors.length} sectors'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            widget.mapName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 16),
          Text(
            stats,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          FilterChip(
            label: const Text('Grid'),
            selected: _showGrid,
            onSelected: (value) => setState(() => _showGrid = value),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Things'),
            selected: _showThings,
            onSelected: (value) => setState(() => _showThings = value),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset view',
            onPressed: _centerMap,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(_MapColors.wall, 'Wall'),
          const SizedBox(width: 16),
          _legendItem(_MapColors.floorChange, 'Floor change'),
          const SizedBox(width: 16),
          _legendItem(_MapColors.ceilingChange, 'Ceiling change'),
          if (_showThings) ...[
            const SizedBox(width: 16),
            _legendItem(_MapColors.player, 'Player'),
            const SizedBox(width: 16),
            _legendItem(_MapColors.thing, 'Thing'),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.mapData,
    required this.showThings,
    required this.showGrid,
  });

  final MapData mapData;
  final bool showThings;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (mapData.vertices.isEmpty || mapData.linedefs.isEmpty) return;

    final bounds = _calculateBounds();
    if (bounds.isEmpty || !bounds.isFinite) return;

    if (showGrid) {
      _drawGrid(canvas, bounds);
    }
    _drawLinedefs(canvas);
    if (showThings) {
      _drawThings(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Rect bounds) {
    final gridPaint = Paint()
      ..color = _MapColors.grid
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 128.0;
    const maxGridLines = 80;

    final path = Path();

    final startX = (bounds.left / gridSize).floor() * gridSize;
    final startY = (bounds.top / gridSize).floor() * gridSize;

    var lineCount = 0;
    for (var x = startX;
        x <= bounds.right && lineCount < maxGridLines;
        x += gridSize) {
      path
        ..moveTo(x, bounds.top)
        ..lineTo(x, bounds.bottom);
      lineCount++;
    }

    lineCount = 0;
    for (var y = startY;
        y <= bounds.bottom && lineCount < maxGridLines;
        y += gridSize) {
      path
        ..moveTo(bounds.left, y)
        ..lineTo(bounds.right, y);
      lineCount++;
    }

    canvas.drawPath(path, gridPaint);
  }

  void _drawLinedefs(Canvas canvas) {
    final wallPath = Path();
    final floorChangePath = Path();
    final ceilingChangePath = Path();
    final twoSidedPath = Path();

    for (final linedef in mapData.linedefs) {
      if (linedef.flags & _LineFlags.dontDraw != 0) continue;
      if (linedef.v1 >= mapData.vertices.length ||
          linedef.v2 >= mapData.vertices.length) {
        continue;
      }

      final v1 = mapData.vertices[linedef.v1];
      final v2 = mapData.vertices[linedef.v2];

      _classifyLine(
        linedef,
        wallPath,
        floorChangePath,
        ceilingChangePath,
        twoSidedPath,
      )
        ..moveTo(v1.x.fixedToDouble(), v1.y.fixedToDouble())
        ..lineTo(v2.x.fixedToDouble(), v2.y.fixedToDouble());
    }

    final basePaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas
      ..drawPath(twoSidedPath, basePaint..color = _MapColors.twoSided)
      ..drawPath(ceilingChangePath, basePaint..color = _MapColors.ceilingChange)
      ..drawPath(floorChangePath, basePaint..color = _MapColors.floorChange)
      ..drawPath(wallPath, basePaint..color = _MapColors.wall);
  }

  Path _classifyLine(
    MapLinedef linedef,
    Path wall,
    Path floorChange,
    Path ceilingChange,
    Path twoSided,
  ) {
    if (linedef.flags & _LineFlags.twoSided == 0) {
      return wall;
    }

    final frontSide = linedef.sidenum0;
    final backSide = linedef.sidenum1;

    if (frontSide < 0 ||
        frontSide >= mapData.sidedefs.length ||
        backSide < 0 ||
        backSide >= mapData.sidedefs.length) {
      return wall;
    }

    final frontSector = mapData.sidedefs[frontSide].sector;
    final backSector = mapData.sidedefs[backSide].sector;

    if (frontSector < 0 ||
        frontSector >= mapData.sectors.length ||
        backSector < 0 ||
        backSector >= mapData.sectors.length) {
      return twoSided;
    }

    final front = mapData.sectors[frontSector];
    final back = mapData.sectors[backSector];

    if (front.floorHeight != back.floorHeight) {
      return floorChange;
    }

    if (front.ceilingHeight != back.ceilingHeight) {
      return ceilingChange;
    }

    return twoSided;
  }

  void _drawThings(Canvas canvas) {
    for (final thing in mapData.things) {
      final isPlayer = _ThingTypes.playerStarts.contains(thing.type);
      final color = isPlayer ? _MapColors.player : _MapColors.thing;

      _drawTriangle(
        canvas,
        thing.x.toDouble(),
        thing.y.toDouble(),
        thing.angle.toDouble(),
        isPlayer ? 20.0 : 12.0,
        color,
      );
    }
  }

  void _drawTriangle(
    Canvas canvas,
    double x,
    double y,
    double angleDeg,
    double size,
    Color color,
  ) {
    final angleRad = angleDeg * math.pi / 180;

    final tipX = x + math.cos(angleRad) * size;
    final tipY = y + math.sin(angleRad) * size;

    const backAngle = 2.5;
    final leftX = x + math.cos(angleRad + backAngle) * size * 0.6;
    final leftY = y + math.sin(angleRad + backAngle) * size * 0.6;
    final rightX = x + math.cos(angleRad - backAngle) * size * 0.6;
    final rightY = y + math.sin(angleRad - backAngle) * size * 0.6;

    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(leftX, leftY)
      ..lineTo(rightX, rightY)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  Rect _calculateBounds() {
    var minX = mapData.vertices.first.x.fixedToDouble();
    var maxX = minX;
    var minY = mapData.vertices.first.y.fixedToDouble();
    var maxY = minY;

    for (final vertex in mapData.vertices) {
      minX = math.min(minX, vertex.x.fixedToDouble());
      maxX = math.max(maxX, vertex.x.fixedToDouble());
      minY = math.min(minY, vertex.y.fixedToDouble());
      maxY = math.max(maxY, vertex.y.fixedToDouble());
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      mapData != oldDelegate.mapData ||
      showThings != oldDelegate.showThings ||
      showGrid != oldDelegate.showGrid;
}
