import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OvceDatabaze());
}

class OvceDatabaze extends StatelessWidget {
  const OvceDatabaze({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ovce Databáze',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(title: 'Databáze Ovcí'),
    );
  }
}
