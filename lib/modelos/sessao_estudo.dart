// lib/modelos/sessao_estudo.dart
class SessaoEstudo {
  final String materia;
  final String assunto;
  final String tipoEstudo;
  final String observacoes;
  final int duracaoSegundos;
  final DateTime data;
  
  final int? totalQuestoes;
  final int? acertos;

  SessaoEstudo({
    required this.materia,
    required this.assunto,
    required this.tipoEstudo,
    required this.observacoes,
    required this.duracaoSegundos,
    required this.data,
    this.totalQuestoes,
    this.acertos,
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
      };

  // REFATORAÇÃO: Proteção contra valores nulos (Fallbacks)
  factory SessaoEstudo.fromJson(Map<String, dynamic> json) => SessaoEstudo(
        materia: json['materia'] ?? '',
        assunto: json['assunto'] ?? '',
        tipoEstudo: json['tipoEstudo'] ?? 'Indefinido',
        observacoes: json['observacoes'] ?? '',
        duracaoSegundos: json['duracaoSegundos'] ?? 0,
        data: json['data'] != null ? DateTime.parse(json['data']) : DateTime.now(),
        totalQuestoes: json['totalQuestoes'],
        acertos: json['acertos'],
      );
}