// lib/utilidades/gerador_cores.dart
import 'package:flutter/material.dart';

class GeradorCores {
  // Paleta de cores vibrantes pensadas para o nosso fundo escuro
  static const List<Color> _paleta = [
    Color(0xFF4DA6FF), // 0: Azul Padrão
    Color(0xFF81C784), // 1: Verde
    Color(0xFFBA68C8), // 2: Roxo
    Color(0xFFFFB74D), // 3: Laranja
    Color(0xFFF06292), // 4: Rosa
    Color(0xFF4DB6AC), // 5: Teal (Verde-azulado)
    Color(0xFFFFD54F), // 6: Amarelo
    Color(0xFF7986CB), // 7: Indigo
    Color(0xFFFF8A65), // 8: Laranja Escuro
    Color(0xFF4DD0E1), // 9: Ciano
    Color(0xFFA1887F), // 10: Marrom Claro
    Color(0xFFE57373), // 11: Vermelho Suave
  ];

  static Color obterCor(String materia) {
    if (materia.trim().isEmpty) return _paleta[0];
    
    // Converte para minúsculas para que "Matemática" e "matemática" tenham a mesma cor
    String chave = materia.trim().toLowerCase();
    
    // Transforma as letras num número fixo (Hash)
    int hash = 0;
    for (int i = 0; i < chave.length; i++) {
      hash = chave.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Escolhe uma cor da paleta baseada no número
    return _paleta[hash.abs() % _paleta.length];
  }
}