import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:doom_flutter/src/crt_effect.dart';
import 'package:doom_flutter/src/doom_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DoomApp());
}

class DoomApp extends StatelessWidget {
  const DoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartDoom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const DoomScreen(),
    );
  }
}

class DoomScreen extends StatefulWidget {
  const DoomScreen({super.key});

  @override
  State<DoomScreen> createState() => _DoomScreenState();
}

class _DoomScreenState extends State<DoomScreen> {
  Uint8List? _wadBytes;
  String? _errorMessage;
  bool _isDragging = false;
  int _gameKey = 0;
  CrtEffect _crtEffect = CrtEffect.none;
  ui.FragmentShader? _crtShader;
  ui.FragmentProgram? _crtProgram;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _loadShader() async {
    try {
      _crtProgram = await ui.FragmentProgram.fromAsset('shaders/crt.frag');
      setState(() {
        _crtShader = _crtProgram!.fragmentShader();
      });
    } catch (e) {
      debugPrint('Failed to load CRT shader: $e');
    }
  }

  void _toggleCrtEffect() {
    setState(() {
      _crtEffect = _crtEffect.next();
      if (_crtProgram != null) {
        _crtShader = _crtProgram!.fragmentShader();
      }
    });
  }

  Future<void> _loadWad() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wad', 'WAD'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          _setWadData(file.bytes!);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load WAD: $e';
      });
    }
  }

  Future<void> _handleFileDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    final file = details.files.first;
    final fileName = file.name.toLowerCase();

    if (!fileName.endsWith('.wad')) {
      setState(() {
        _errorMessage = 'Please drop a .WAD file';
      });
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      _setWadData(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load WAD: $e';
      });
    }
  }

  void _setWadData(Uint8List bytes) {
    setState(() {
      _wadBytes = bytes;
      _errorMessage = null;
      _isDragging = false;
      _gameKey++;
    });
  }

  void _resetToStart() {
    setState(() {
      _wadBytes = null;
      _errorMessage = null;
      _gameKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_wadBytes != null) {
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: DoomWidget(
                key: ValueKey(_gameKey),
                wadBytes: _wadBytes,
                onQuit: _resetToStart,
                crtEffect: _crtEffect,
                crtShader: _crtShader,
                fillScreen: _isFullscreen,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToolbarButton(
                    icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    label: _isFullscreen ? 'Exit' : 'Fullscreen',
                    onPressed: _toggleFullscreen,
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.tv,
                    label: 'CRT: ${_crtEffect.label}',
                    onPressed: _toggleCrtEffect,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildErrorBar(),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: _handleFileDrop,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _WadDropZone(
                  isDragging: _isDragging,
                  onLoadPressed: _loadWad,
                ),
              ),
            ),
            if (_errorMessage != null) _buildErrorBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red[900],
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }
}

class _WadDropZone extends StatelessWidget {
  const _WadDropZone({
    required this.isDragging,
    required this.onLoadPressed,
  });

  final bool isDragging;
  final VoidCallback onLoadPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 400,
      height: 300,
      decoration: BoxDecoration(
        color: isDragging ? Colors.red.withValues(alpha: 0.2) : Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDragging ? Colors.red : Colors.grey[700]!,
          width: isDragging ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDragging ? Icons.file_download : Icons.videogame_asset,
            size: 64,
            color: isDragging ? Colors.red : Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            isDragging ? 'Drop WAD file here' : 'No WAD loaded',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDragging ? Colors.red : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag & drop a .WAD file or',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onLoadPressed,
            icon: const Icon(Icons.folder_open),
            label: const Text('Browse Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Supports DOOM, DOOM II, FreeDoom WADs',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
