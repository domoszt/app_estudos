// lib/telas/tela_estatisticas.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../modelos/sessao_estudo.dart';
import '../utilidades/gerador_cores.dart'; 

class TelaEstatisticas extends StatefulWidget {
  final List<SessaoEstudo> todasSessoes;

  const TelaEstatisticas({super.key, required this.todasSessoes});

  @override
  State<TelaEstatisticas> createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  bool _modoQuestoes = false; 
  bool _ordemMaiorAcerto = true; 

  // CODE REVIEW: Variáveis pré-calculadas guardadas no estado da tela
  int _tempoTotalSegundos = 0;
  int _totalQuestoesGeral = 0;
  int _totalAcertosGeral = 0;
  List<MapEntry<String, int>> _materiasOrdenadasTempo = [];
  List<Map<String, dynamic>> _listaDesempenhoQuestoes = [];

  @override
  void initState() {
    super.initState();
    _processarEstatisticas(); // Chama a matemática pesada APENAS UMA VEZ
  }

  // CODE REVIEW: Toda a lógica retirada do 'build' e isolada aqui
  void _processarEstatisticas() {
    Map<String, int> tempoPorMateria = {};
    Map<String, Map<String, int>> statsMateria = {};

    for (var sessao in widget.todasSessoes) {
      tempoPorMateria[sessao.materia] = (tempoPorMateria[sessao.materia] ?? 0) + sessao.duracaoSegundos;
      _tempoTotalSegundos += sessao.duracaoSegundos;

      if (sessao.totalQuestoes != null && sessao.acertos != null && sessao.totalQuestoes! > 0) {
        _totalQuestoesGeral += sessao.totalQuestoes!;
        _totalAcertosGeral += sessao.acertos!;

        if (!statsMateria.containsKey(sessao.materia)) {
          statsMateria[sessao.materia] = {'questoes': 0, 'acertos': 0};
        }
        statsMateria[sessao.materia]!['questoes'] = statsMateria[sessao.materia]!['questoes']! + sessao.totalQuestoes!;
        statsMateria[sessao.materia]!['acertos'] = statsMateria[sessao.materia]!['acertos']! + sessao.acertos!;
      }
    }

    _materiasOrdenadasTempo = tempoPorMateria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    statsMateria.forEach((materia, dados) {
      double percentual = (dados['acertos']! / dados['questoes']!) * 100;
      _listaDesempenhoQuestoes.add({
        'materia': materia,
        'questoes': dados['questoes'],
        'acertos': dados['acertos'],
        'percentual': percentual,
      });
    });

    _ordenarListaQuestoes();
  }

  void _ordenarListaQuestoes() {
    _listaDesempenhoQuestoes.sort((a, b) {
      if (_ordemMaiorAcerto) {
        return b['percentual'].compareTo(a['percentual']); 
      } else {
        return a['percentual'].compareTo(b['percentual']); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Estatísticas Globais',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4DA6FF)),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.todasSessoes.isEmpty
                ? const Center(child: Text('Nenhum dado registrado ainda.', style: TextStyle(color: Colors.grey)))
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    // CODE REVIEW: Usando as variáveis que já estão prontas
                    child: _modoQuestoes 
                        ? _construirVisaoQuestoes(_totalQuestoesGeral, _totalAcertosGeral, _listaDesempenhoQuestoes)
                        : _construirVisaoTempo(_materiasOrdenadasTempo, _tempoTotalSegundos),
                  ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              border: Border(top: BorderSide(color: Colors.grey.shade900)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _modoQuestoes = !_modoQuestoes;
                    });
                  },
                  icon: Icon(_modoQuestoes ? Icons.timer_rounded : Icons.fact_check_rounded),
                  label: Text(
                    _modoQuestoes ? 'Ver Volume de Horas' : 'Ver Taxa de Acertos',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: const Color(0xFF4DA6FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVisaoTempo(List<MapEntry<String, int>> materiasOrdenadas, int tempoTotalSegundos) {
    List<double> valoresPizza = [];
    List<Color> coresPizza = [];
    
    for (var item in materiasOrdenadas) {
      valoresPizza.add(item.value.toDouble());
      coresPizza.add(GeradorCores.obterCor(item.key));
    }

    int horasTotais = tempoTotalSegundos ~/ 3600;
    int minutosTotais = (tempoTotalSegundos % 3600) ~/ 60;
    String tempoTotalStr = horasTotais > 0 
        ? "$horasTotais horas e $minutosTotais min" 
        : "$minutosTotais minutos";

    return SingleChildScrollView(
      key: const ValueKey('tempo'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _GraficoPizzaPainter(
                valores: valoresPizza,
                cores: coresPizza,
              ),
            ),
          ),
          const SizedBox(height: 48),

          const Text('TEMPO TOTAL ACUMULADO', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tempoTotalStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255))),
          
          const SizedBox(height: 48),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade900),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Mais Estudadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                ...List.generate(
                  materiasOrdenadas.length,
                  (index) {
                    final item = materiasOrdenadas[index];
                    final cor = GeradorCores.obterCor(item.key);
                    double porcentagem = (item.value / tempoTotalSegundos) * 100;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.key, 
                              style: TextStyle(color: Colors.white, fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal)
                            ),
                          ),
                          Text('${porcentagem.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVisaoQuestoes(int totalQuestoes, int totalAcertos, List<Map<String, dynamic>> listaDesempenho) {
    if (totalQuestoes == 0) {
      return const Center(child: Text('Nenhuma questão resolvida ainda.', style: TextStyle(color: Colors.grey)));
    }

    int erros = totalQuestoes - totalAcertos;
    double percentualGeral = (totalAcertos / totalQuestoes) * 100;

    return SingleChildScrollView(
      key: const ValueKey('questoes'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _GraficoPizzaPainter(
                    valores: [totalAcertos.toDouble(), erros.toDouble()],
                    cores: const [Color(0xFF81C784), Color(0xFFE57373)],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${percentualGeral.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('De Acertos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _blocoDeInfo('Total', totalQuestoes.toString(), Colors.white),
              _blocoDeInfo('Acertos', totalAcertos.toString(), const Color(0xFF81C784)),
              _blocoDeInfo('Erros', erros.toString(), const Color(0xFFE57373)),
            ],
          ),
          
          const SizedBox(height: 48),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade900),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Desempenho por Matéria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _ordemMaiorAcerto = !_ordemMaiorAcerto;
                          _ordenarListaQuestoes(); // CODE REVIEW: Re-ordena apenas quando clica
                        });
                      },
                      icon: Icon(
                        _ordemMaiorAcerto ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                        size: 16, 
                        color: const Color(0xFF4DA6FF)
                      ),
                      label: Text(
                        _ordemMaiorAcerto ? 'Maiores' : 'Menores',
                        style: const TextStyle(color: Color(0xFF4DA6FF), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                ...listaDesempenho.map((item) {
                  double perc = item['percentual'];
                  
                  Color corBarra = perc >= 70 ? const Color(0xFF81C784) : (perc >= 50 ? const Color(0xFFFF9900) : const Color(0xFFE57373));
                  Color corMateria = GeradorCores.obterCor(item['materia']);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['materia'], 
                                style: TextStyle(color: corMateria, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                            ),
                            Text('${perc.toStringAsFixed(1)}%', style: TextStyle(color: corBarra, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${item['acertos']} acertos de ${item['questoes']} questões', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: perc / 100,
                            backgroundColor: const Color(0xFF2D2D2D),
                            valueColor: AlwaysStoppedAnimation<Color>(corBarra),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocoDeInfo(String titulo, String valor, Color cor) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Text(valor, style: TextStyle(color: cor, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _GraficoPizzaPainter extends CustomPainter {
  final List<double> valores;
  final List<Color> cores;

  _GraficoPizzaPainter({
    required this.valores,
    required this.cores,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double total = valores.fold(0, (sum, item) => sum + item);
    if (total == 0) return;

    double startAngle = -pi / 2; 
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (int i = 0; i < valores.length; i++) {
      final sweepAngle = (valores[i] / total) * 2 * pi;
      final paint = Paint()
        ..color = i < cores.length ? cores[i] : Colors.grey
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
    
    final innerPaint = Paint()..color = const Color(0xFF0F0F0F);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.35, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}