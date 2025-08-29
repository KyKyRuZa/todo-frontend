import 'package:flutter/material.dart';
import 'widgets/title.dart'; // Показываем splash сначала

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Сначала splash
    );
  }
}
