import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const SweepApp());
}

class SweepApp extends StatelessWidget {
  const SweepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
