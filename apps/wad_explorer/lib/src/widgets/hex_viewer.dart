
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HexViewer extends StatefulWidget {
  const HexViewer({
    required this.data,
    this.bytesPerRow = 16,
    super.key,
  });

  final Uint8List data;
  final int bytesPerRow;

  @override
  State<HexViewer> createState() => _HexViewerState();
}

class _HexViewerState extends State<HexViewer> {
  final _scrollController = ScrollController();
  int? _selectedOffset;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = (widget.data.length / widget.bytesPerRow).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const Divider(height: 1),
        _buildColumnHeaders(theme),
        const Divider(height: 1),
        Expanded(
          child: SelectionArea(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: rows,
              itemBuilder: (context, index) => _buildRow(index, theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text(
            '${widget.data.length} bytes',
            style: theme.textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Copy as hex string',
            onPressed: _copyAsHex,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(ThemeData theme) {
    final headers = <Widget>[
      SizedBox(
        width: _HexViewerLayout.offsetWidth,
        child: Text(
          'Offset',
          style: _HexViewerStyle.headerStyle(theme),
        ),
      ),
      const SizedBox(width: _HexViewerLayout.gapWidth),
    ];

    for (var i = 0; i < widget.bytesPerRow; i++) {
      headers.add(
        SizedBox(
          width: _HexViewerLayout.byteWidth,
          child: Text(
            i.toRadixString(16).toUpperCase().padLeft(2, '0'),
            style: _HexViewerStyle.headerStyle(theme),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    headers
      ..add(const SizedBox(width: _HexViewerLayout.gapWidth * 2))
      ..add(
        Text(
          'ASCII',
          style: _HexViewerStyle.headerStyle(theme),
        ),
      );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: headers),
    );
  }

  Widget _buildRow(int rowIndex, ThemeData theme) {
    final offset = rowIndex * widget.bytesPerRow;
    final end = (offset + widget.bytesPerRow).clamp(0, widget.data.length);
    final rowBytes = widget.data.sublist(offset, end);
    final isSelected = _selectedOffset != null &&
        _selectedOffset! >= offset &&
        _selectedOffset! < end;

    return InkWell(
      onTap: () => setState(() {
        _selectedOffset = _selectedOffset == offset ? null : offset;
      }),
      child: Container(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : (rowIndex.isEven ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: _HexViewerLayout.offsetWidth,
              child: Text(
                offset.toRadixString(16).toUpperCase().padLeft(8, '0'),
                style: _HexViewerStyle.offsetStyle(theme),
              ),
            ),
            const SizedBox(width: _HexViewerLayout.gapWidth),
            ...List.generate(widget.bytesPerRow, (i) {
              if (i < rowBytes.length) {
                final byte = rowBytes[i];
                return SizedBox(
                  width: _HexViewerLayout.byteWidth,
                  child: Text(
                    byte.toRadixString(16).toUpperCase().padLeft(2, '0'),
                    style: _HexViewerStyle.byteStyle(theme, byte),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox(width: _HexViewerLayout.byteWidth);
            }),
            const SizedBox(width: _HexViewerLayout.gapWidth * 2),
            Text(
              _toAscii(rowBytes),
              style: _HexViewerStyle.asciiStyle(theme),
            ),
          ],
        ),
      ),
    );
  }

  String _toAscii(Uint8List bytes) {
    return bytes.map((b) {
      if (b >= _HexViewerLayout.printableMin &&
          b < _HexViewerLayout.printableMax) {
        return String.fromCharCode(b);
      }
      return '.';
    }).join();
  }

  Future<void> _copyAsHex() async {
    final hex = widget.data
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
    await Clipboard.setData(ClipboardData(text: hex));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

abstract final class _HexViewerLayout {
  static const double offsetWidth = 80;
  static const double byteWidth = 24;
  static const double gapWidth = 8;
  static const int printableMin = 32;
  static const int printableMax = 127;
}

abstract final class _HexViewerStyle {
  static TextStyle headerStyle(ThemeData theme) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant,
      );

  static TextStyle offsetStyle(ThemeData theme) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: theme.colorScheme.primary,
      );

  static TextStyle byteStyle(ThemeData theme, int byte) {
    Color color;
    if (byte == 0) {
      color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    } else if (byte >= _HexViewerLayout.printableMin &&
        byte < _HexViewerLayout.printableMax) {
      color = theme.colorScheme.onSurface;
    } else {
      color = theme.colorScheme.tertiary;
    }
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: color,
    );
  }

  static TextStyle asciiStyle(ThemeData theme) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: theme.colorScheme.onSurfaceVariant,
      );
}
