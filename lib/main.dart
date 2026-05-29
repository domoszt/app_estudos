// lib/main.dart
import 'package:flutter/material.dart';
import 'telas/tela_base.dart';

void main() {
  runApp(const MeuAppEstudos());
}

class MeuAppEstudos extends StatelessWidget {
  const MeuAppEstudos({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Estudos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFF4DA6FF),
      ),
      home: const TelaBase(),
    );
  }
}