// lib/telas/tela_revisoes.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/sessao_estudo.dart';
import '../utilidades/gerador_cores.dart';

// Estrutura tática para organizar cada missão pendente
class ItemRevisao {
  final SessaoEstudo sessao;
  final int tipo; // 1 = 24h, 2 = 7d, 3 = 30d
  final String titulo;
  final int diasAtraso;

  ItemRevisao(this.sessao, this.tipo, this.titulo, this.diasAtraso);
}

class TelaRevisoes extends StatefulWidget {
  const TelaRevisoes({super.key});

  @override
  State<TelaRevisoes> createState() => _TelaRevisoesState();
}

class _TelaRevisoesState extends State<TelaRevisoes> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // O escudo que evita o engasgo

  bool _carregando = true;
  List<SessaoEstudo> _todasSessoes = [];
  List<ItemRevisao> _missoesPendentes = [];
 
  @override
  void initState() {
    super.initState();
    _varrerRadarDeRevisoes();
    notificadorVanguard.addListener(_varrerRadarDeRevisoes); // Liga o rádio
  }

  @override
  void dispose() {
    notificadorVanguard.removeListener(_varrerRadarDeRevisoes); // Desliga o rádio
    super.dispose();
  }

  Future<void> _varrerRadarDeRevisoes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dadosSalvos = prefs.getStringList('sessoes_estudo') ?? [];
    
    _todasSessoes = dadosSalvos.map((jsonStr) => SessaoEstudo.fromJson(jsonDecode(jsonStr))).toList();
    _missoesPendentes.clear();

    DateTime agora = DateTime.now();

    for (var sessao in _todasSessoes) {
      Duration diferenca = agora.difference(sessao.data);

      // Verifica 24 Horas
      if (!sessao.rev24h && diferenca.inHours >= 24) {
        _missoesPendentes.add(ItemRevisao(sessao, 1, 'Revisão de 24 Horas', diferenca.inDays));
      }
      // Verifica 7 Dias
      if (!sessao.rev7d && diferenca.inDays >= 7) {
        _missoesPendentes.add(ItemRevisao(sessao, 2, 'Revisão de 7 Dias', diferenca.inDays - 7));
      }
      // Verifica 30 Dias
      if (!sessao.rev30d && diferenca.inDays >= 30) {
        _missoesPendentes.add(ItemRevisao(sessao, 3, 'Revisão de 30 Dias', diferenca.inDays - 30));
      }
    }

    // Organiza para mostrar as mais atrasadas/urgentes primeiro
    _missoesPendentes.sort((a, b) => b.diasAtraso.compareTo(a.diasAtraso));

    if (!mounted) return;
    setState(() {
      _carregando = false;
    });
  }

  Future<void> _marcarMissaoCumprida(ItemRevisao item) async {
    int index = _todasSessoes.indexWhere((s) => s.data == item.sessao.data);
    
    if (index != -1) {
      SessaoEstudo original = _todasSessoes[index];
      
      _todasSessoes[index] = SessaoEstudo(
        materia: original.materia,
        assunto: original.assunto,
        tipoEstudo: original.tipoEstudo,
        observacoes: original.observacoes,
        duracaoSegundos: original.duracaoSegundos,
        data: original.data,
        totalQuestoes: original.totalQuestoes,
        acertos: original.acertos,
        rev24h: item.tipo == 1 ? true : original.rev24h,
        rev7d: item.tipo == 2 ? true : original.rev7d,
        rev30d: item.tipo == 3 ? true : original.rev30d,
      );

      final prefs = await SharedPreferences.getInstance();
      List<String> sessoesSalvas = _todasSessoes.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('sessoes_estudo', sessoesSalvas);

      setState(() {
        _missoesPendentes.remove(item);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('${item.titulo} concluída! Excelente.', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF81C784),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

 @override
  Widget build(BuildContext context) {
    super.build(context); // TEM DE TER ESTA LINHA AQUI!

    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4DA6FF)));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _missoesPendentes.isEmpty ? const Color(0xFF81C784).withValues(alpha: 0.3) : const Color(0xFFE57373).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _missoesPendentes.isEmpty ? Icons.radar_rounded : Icons.warning_amber_rounded,
                    color: _missoesPendentes.isEmpty ? const Color(0xFF81C784) : const Color(0xFFE57373),
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _missoesPendentes.isEmpty ? 'Radar Limpo' : '${_missoesPendentes.length} Revisões Pendentes',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _missoesPendentes.isEmpty ? 'Nenhum alvo de revisão detetado no momento.' : 'As suas matérias passadas precisam de reforço.',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Alvos de Hoje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _missoesPendentes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, size: 64, color: Colors.grey.shade800),
                          const SizedBox(height: 16),
                          Text('Todas as revisões em dia!', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _missoesPendentes.length,
                      itemBuilder: (context, index) {
                        final item = _missoesPendentes[index];
                        Color corMateria = GeradorCores.obterCor(item.sessao.materia);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade800, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 50,
                                  decoration: BoxDecoration(color: corMateria, borderRadius: BorderRadius.circular(4)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.titulo,
                                        style: const TextStyle(color: Color(0xFFE57373), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.sessao.materia,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      if (item.sessao.assunto.trim().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.sessao.assunto,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        "Estudado em: ${item.sessao.data.day.toString().padLeft(2, '0')}/${item.sessao.data.month.toString().padLeft(2, '0')}/${item.sessao.data.year}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _marcarMissaoCumprida(item),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF81C784).withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  icon: const Icon(Icons.check_rounded, color: Color(0xFF81C784)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}