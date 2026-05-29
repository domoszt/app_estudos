import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Biblioteca que permite controlar a tela
import 'telas/tela_base.dart';

void main() {
  // Garante que o motor do Flutter está pronto antes de dar ordens ao sistema
  WidgetsFlutterBinding.ensureInitialized();
  
  // Trava o aplicativo EXCLUSIVAMENTE na vertical (Retrato)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MeuApp());
  });
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Estudos',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const TelaBase(),
      debugShowCheckedModeBanner: false,
    );
  }
}