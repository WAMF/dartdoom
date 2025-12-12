import 'package:doom_flutter/src/doom_widget.dart';
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

class DoomScreen extends StatelessWidget {
  const DoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: DoomWidget(),
      ),
    );
  }
}
