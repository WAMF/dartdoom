import 'package:flutter/material.dart';
import 'package:wad_explorer/src/pages/explorer_page.dart';

void main() {
  runApp(const WadExplorerApp());
}

class WadExplorerApp extends StatelessWidget {
  const WadExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAD Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ExplorerPage(),
    );
  }
}
