import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/video_editor_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minh Hoàng Video Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/editor': (context) => const VideoEditorScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}