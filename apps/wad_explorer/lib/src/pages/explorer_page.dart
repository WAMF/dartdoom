import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wad_explorer/src/models/lump_category.dart';
import 'package:wad_explorer/src/widgets/lump_detail_viewer.dart';
import 'package:wad_explorer/src/widgets/lump_tree_view.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  WadManager? _wadManager;
  String? _fileName;
  DoomPalette? _palette;
  bool _isDragging = false;

  LumpInfo? _selectedInfo;
  LumpCategory? _selectedCategory;
  Uint8List? _selectedData;

  Future<void> _openFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wad', 'WAD'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;
        _loadWad(bytes, name);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _loadFromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    _loadWad(bytes, file.name);
  }

  void _loadWad(Uint8List bytes, String name) {
    setState(() {
      _wadManager = WadManager()..addWad(bytes);
      _fileName = name;
      _selectedInfo = null;
      _selectedCategory = null;
      _selectedData = null;
      _palette = _loadPalette();
    });
  }

  DoomPalette? _loadPalette() {
    if (_wadManager == null) return null;

    final index = _wadManager!.checkNumForName('PLAYPAL');
    if (index == -1) return null;

    try {
      final data = _wadManager!.readLump(index);
      final playpal = PlayPal.parse(data);
      return playpal.palettes.first;
    } catch (e) {
      return null;
    }
  }

  void _onLumpSelected(int index, LumpInfo info, LumpCategory category) {
    setState(() {
      _selectedInfo = info;
      _selectedCategory = category;
      _selectedData = _wadManager?.readLump(index);
    });
  }

  void _onDragEntered(DropEventDetails details) {
    setState(() => _isDragging = true);
  }

  void _onDragExited(DropEventDetails details) {
    setState(() => _isDragging = false);
  }

  Future<void> _onDragDone(DropDoneDetails details) async {
    setState(() => _isDragging = false);

    if (details.files.isEmpty) return;

    final file = details.files.first;
    final name = file.name.toLowerCase();
    if (name.endsWith('.wad')) {
      await _loadFromXFile(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName ?? 'WAD Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open WAD file',
            onPressed: _openFile,
          ),
        ],
      ),
      body: DropTarget(
        onDragEntered: _onDragEntered,
        onDragExited: _onDragExited,
        onDragDone: _onDragDone,
        child: Stack(
          children: [
            if (_wadManager == null) _buildEmptyState() else _buildExplorer(),
            if (_isDragging) _buildDropOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.file_download,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Drop WAD file here',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No WAD file loaded'),
          const SizedBox(height: 8),
          Text(
            'Drop a WAD file here or click to open',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.file_open),
            label: const Text('Open WAD File'),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorer() {
    return Row(
      children: [
        SizedBox(
          width: 300,
          child: LumpTreeView(
            wadManager: _wadManager!,
            onLumpSelected: _onLumpSelected,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedData != null &&
                  _selectedInfo != null &&
                  _selectedCategory != null &&
                  _palette != null
              ? LumpDetailViewer(
                  lumpData: _selectedData!,
                  lumpInfo: _selectedInfo!,
                  category: _selectedCategory!,
                  palette: _palette!,
                )
              : _buildNoSelection(),
        ),
      ],
    );
  }

  Widget _buildNoSelection() {
    if (_palette == null) {
      return const Center(
        child: Text('No PLAYPAL found in WAD'),
      );
    }
    return const Center(
      child: Text('Select a lump to view its contents'),
    );
  }
}
