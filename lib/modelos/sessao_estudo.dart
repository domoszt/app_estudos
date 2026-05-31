// lib/modelos/sessao_estudo.dart

import 'package:flutter/foundation.dart';

final ValueNotifier<int> notificadorVanguard = ValueNotifier(0);

class SessaoEstudo {
  final String materia;
  final String assunto;
  final String tipoEstudo;
  final String observacoes;
  final int duracaoSegundos;
  final DateTime data;
  
  final int? totalQuestoes;
  final int? acertos;

  // Novos sensores de revisão tática
  final bool rev24h;
  final bool rev7d;
  final bool rev30d;

  SessaoEstudo({
    required this.materia,
    required this.assunto,
    required this.tipoEstudo,
    required this.observacoes,
    required this.duracaoSegundos,
    required this.data,
    this.totalQuestoes,
    this.acertos,
    this.rev24h = false, 
    this.rev7d = false,
    this.rev30d = false,
  });

  Map<String, dynamic> toJson() => {
        'materia': materia,
        'assunto': assunto,
        'tipoEstudo': tipoEstudo,
        'observacoes': observacoes,
        'duracaoSegundos': duracaoSegundos,
        'data': data.toIso8601String(),
        'totalQuestoes': totalQuestoes,
        'acertos': acertos,
        'rev24h': rev24h,
        'rev7d': rev7d,
        'rev30d': rev30d,
      };

  factory SessaoEstudo.fromJson(Map<String, dynamic> json) => SessaoEstudo(
        materia: json['materia'] ?? '',
        assunto: json['assunto'] ?? '',
        tipoEstudo: json['tipoEstudo'] ?? 'Indefinido',
        observacoes: json['observacoes'] ?? '',
        duracaoSegundos: json['duracaoSegundos'] ?? 0,
        data: json['data'] != null ? DateTime.parse(json['data']) : DateTime.now(),
        totalQuestoes: json['totalQuestoes'],
        acertos: json['acertos'],
        rev24h: json['rev24h'] ?? false,
        rev7d: json['rev7d'] ?? false,
        rev30d: json['rev30d'] ?? false,
      );
}