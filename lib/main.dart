import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CharacterRecognitionApp());
}

class CharacterRecognitionApp extends StatelessWidget {
  const CharacterRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Character Recognition',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'RobotoBlack', // Set global font
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
