import 'dart:typed_data';

import 'package:doom_flutter/src/doom_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  String? _wadFileName;
  String? _errorMessage;

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
          setState(() {
            _wadBytes = file.bytes;
            _wadFileName = file.name;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load WAD: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: DoomWidget(wadBytes: _wadBytes),
            ),
          ),
          if (_errorMessage != null) _buildErrorBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          const Text(
            'DartDoom',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: _loadWad,
            icon: const Icon(Icons.folder_open),
            label: const Text('Load WAD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
            ),
          ),
          if (_wadFileName != null) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _wadFileName!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
          const Spacer(),
          const Text(
            'Press F1 to toggle debug overlay',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
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
