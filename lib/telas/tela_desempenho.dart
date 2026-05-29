// lib/telas/tela_desempenho.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/sessao_estudo.dart';

class TelaDesempenho extends StatefulWidget {
  const TelaDesempenho({super.key});

  @override
  State<TelaDesempenho> createState() => _TelaDesempenhoState();
}

class _TelaDesempenhoState extends State<TelaDesempenho> {
  bool _carregando = true;
  
  // Controle da visualização do Gráfico
  bool _mostrarGraficoBarras = true;
  
  // Controle do Diagnóstico (Raio-X)
  bool _verAssuntos = false; // false = Matérias, true = Assuntos
  bool _pioresPrimeiro = true; // true = Piores no topo
  
  final Map<DateTime, Map<String, int>> _questoesPorDia = {};
  final List<DateTime> _ultimos7Dias = [];
  
  int _maiorTotalNaSemana = 0;
  int _totalSemana = 0;
  int _acertosSemana = 0;

  // Listas de Raio-X
  List<Map<String, dynamic>> _listaRaioXMaterias = [];
  List<Map<String, dynamic>> _listaRaioXAssuntos = [];

  @override
  void initState() {
    super.initState();
    _processarDadosDeQuestoes();
  }

  DateTime _zerarHorario(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  Future<void> _processarDadosDeQuestoes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dadosSalvos = prefs.getStringList('sessoes_estudo') ?? [];
    
    List<SessaoEstudo> todasSessoes = dadosSalvos.map((jsonStr) {
      return SessaoEstudo.fromJson(jsonDecode(jsonStr));
    }).toList();

    _questoesPorDia.clear();
    DateTime hoje = _zerarHorario(DateTime.now());
    
    // Mapas para o Raio-X
    Map<String, Map<String, int>> mapMaterias = {};
    Map<String, Map<String, int>> mapAssuntos = {};
    
    for (var sessao in todasSessoes) {
      if (sessao.totalQuestoes != null && sessao.acertos != null && sessao.totalQuestoes! > 0) {
        DateTime diaLimpo = _zerarHorario(sessao.data);
        
        // --- 1. PREPARAR DADOS PARA O GRÁFICO DIÁRIO ---
        if (!_questoesPorDia.containsKey(diaLimpo)) {
          _questoesPorDia[diaLimpo] = {'total': 0, 'acertos': 0};
        }
        _questoesPorDia[diaLimpo]!['total'] = _questoesPorDia[diaLimpo]!['total']! + sessao.totalQuestoes!;
        _questoesPorDia[diaLimpo]!['acertos'] = _questoesPorDia[diaLimpo]!['acertos']! + sessao.acertos!;

        // --- 2. PREPARAR DADOS PARA O RAIO-X (Somente últimos 7 dias) ---
        int diferencaDias = hoje.difference(diaLimpo).inDays;
        if (diferencaDias >= 0 && diferencaDias <= 6) {
          // Agrupar por Matéria
          if (!mapMaterias.containsKey(sessao.materia)) {
            mapMaterias[sessao.materia] = {'total': 0, 'acertos': 0};
          }
          mapMaterias[sessao.materia]!['total'] = mapMaterias[sessao.materia]!['total']! + sessao.totalQuestoes!;
          mapMaterias[sessao.materia]!['acertos'] = mapMaterias[sessao.materia]!['acertos']! + sessao.acertos!;

          // Agrupar por Assunto (Formato: "Matéria: Assunto")
          String nomeAssunto = sessao.assunto.trim().isEmpty ? 'Geral' : sessao.assunto.trim();
          String chaveAssunto = '${sessao.materia}: $nomeAssunto';
          
          if (!mapAssuntos.containsKey(chaveAssunto)) {
            mapAssuntos[chaveAssunto] = {'total': 0, 'acertos': 0};
          }
          mapAssuntos[chaveAssunto]!['total'] = mapAssuntos[chaveAssunto]!['total']! + sessao.totalQuestoes!;
          mapAssuntos[chaveAssunto]!['acertos'] = mapAssuntos[chaveAssunto]!['acertos']! + sessao.acertos!;
        }
      }
    }

    // --- 3. TRANSFORMAR MAPAS EM LISTAS E CALCULAR PERCENTAGEM ---
    _listaRaioXMaterias = mapMaterias.entries.map((e) {
      return {
        'nome': e.key,
        'total': e.value['total'],
        'acertos': e.value['acertos'],
        'percentual': (e.value['acertos']! / e.value['total']!) * 100,
      };
    }).toList();

    _listaRaioXAssuntos = mapAssuntos.entries.map((e) {
      return {
        'nome': e.key,
        'total': e.value['total'],
        'acertos': e.value['acertos'],
        'percentual': (e.value['acertos']! / e.value['total']!) * 100,
      };
    }).toList();

    _ordenarListasRaioX();

    // --- 4. PREPARAR DADOS DE RESUMO DA SEMANA ---
    _ultimos7Dias.clear();
    _maiorTotalNaSemana = 0;
    _totalSemana = 0;
    _acertosSemana = 0;

    for (int i = 6; i >= 0; i--) {
      DateTime diaAnterior = hoje.subtract(Duration(days: i));
      _ultimos7Dias.add(diaAnterior);
      
      int totalDoDia = _questoesPorDia[diaAnterior]?['total'] ?? 0;
      int acertosDoDia = _questoesPorDia[diaAnterior]?['acertos'] ?? 0;

      _totalSemana += totalDoDia;
      _acertosSemana += acertosDoDia;

      if (totalDoDia > _maiorTotalNaSemana) {
        _maiorTotalNaSemana = totalDoDia;
      }
    }

    setState(() {
      _carregando = false;
    });
  }

  // Função para ordenar a lista de acordo com o botão clicado
  void _ordenarListasRaioX() {
    int sortFunc(Map<String, dynamic> a, Map<String, dynamic> b) {
      if (_pioresPrimeiro) {
        return a['percentual'].compareTo(b['percentual']); // Crescente (Piores primeiro)
      } else {
        return b['percentual'].compareTo(a['percentual']); // Decrescente (Melhores primeiro)
      }
    }
    _listaRaioXMaterias.sort(sortFunc);
    _listaRaioXAssuntos.sort(sortFunc);
  }

  String _obterInicialDoDia(int weekday) {
    switch (weekday) {
      case 1: return 'S'; 
      case 2: return 'T'; 
      case 3: return 'Q'; 
      case 4: return 'Q'; 
      case 5: return 'S'; 
      case 6: return 'S'; 
      case 7: return 'D'; 
      default: return '';
    }
  }

  // ===========================================================================
  // GRÁFICOS (Barras e Linhas)
  // ===========================================================================
  Widget _construirGraficoBarrasDuplas() {
    return Container(
      key: const ValueKey('barras'),
      height: 260, 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.square, color: Color(0xFF4DA6FF), size: 12),
              SizedBox(width: 6),
              Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(width: 16),
              Icon(Icons.square, color: Color(0xFF81C784), size: 12),
              SizedBox(width: 6),
              Text('Acertos', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _ultimos7Dias.map((dia) {
                int totalDesteDia = _questoesPorDia[dia]?['total'] ?? 0;
                int acertosDesteDia = _questoesPorDia[dia]?['acertos'] ?? 0;
                
                double alturaTotal = 4.0; 
                double alturaAcertos = 4.0;
                
                if (_maiorTotalNaSemana > 0 && totalDesteDia > 0) {
                  alturaTotal = (totalDesteDia / _maiorTotalNaSemana) * 120; 
                  alturaAcertos = (acertosDesteDia / _maiorTotalNaSemana) * 120; 
                  
                  if (alturaTotal < 4.0) alturaTotal = 4.0; 
                  if (alturaAcertos < 4.0 && acertosDesteDia > 0) alturaAcertos = 4.0;
                }
                
                bool isHoje = dia.isAtSameMomentAs(_zerarHorario(DateTime.now()));

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 10, 
                          height: alturaTotal,
                          decoration: BoxDecoration(
                            color: totalDesteDia > 0 ? const Color(0xFF4DA6FF) : const Color(0xFF2D2D2D),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 10, 
                          height: acertosDesteDia > 0 ? alturaAcertos : 4.0, 
                          decoration: BoxDecoration(
                            color: acertosDesteDia > 0 ? const Color(0xFF81C784) : const Color(0xFF2D2D2D),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _obterInicialDoDia(dia.weekday),
                      style: TextStyle(
                        color: isHoje ? const Color(0xFF4DA6FF) : Colors.grey, 
                        fontSize: 12,
                        fontWeight: isHoje ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirGraficoLinhas() {
    return Container(
      key: const ValueKey('linhas'),
      height: 260, 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Color(0xFF4DA6FF), size: 10),
              SizedBox(width: 6),
              Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(width: 16),
              Icon(Icons.circle, color: Color(0xFF81C784), size: 10),
              SizedBox(width: 6),
              Text('Acertos', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _GraficoLinhasPainter(
                      questoesPorDia: _questoesPorDia,
                      dias: _ultimos7Dias,
                      maiorValor: _maiorTotalNaSemana,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _ultimos7Dias.map((dia) {
              bool isHoje = dia.isAtSameMomentAs(_zerarHorario(DateTime.now()));
              return SizedBox(
                width: 20, 
                child: Text(
                  _obterInicialDoDia(dia.weekday),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isHoje ? const Color(0xFF4DA6FF) : Colors.grey, 
                    fontSize: 12,
                    fontWeight: isHoje ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NOVO: LISTA DE RAIO-X (DIAGNÓSTICO)
  // ===========================================================================
  Widget _construirRaioX() {
    // Escolhe qual lista mostrar baseado no botão de alternância
    List<Map<String, dynamic>> listaAtual = _verAssuntos ? _listaRaioXAssuntos : _listaRaioXMaterias;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho do Raio-X
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Diagnóstico de Precisão',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            // Botão de Inverter Ordem
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _pioresPrimeiro = !_pioresPrimeiro;
                  _ordenarListasRaioX();
                });
              },
              icon: Icon(
                _pioresPrimeiro ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                size: 16, 
                color: const Color(0xFF4DA6FF)
              ),
              label: Text(
                _pioresPrimeiro ? 'Piores 1º' : 'Melhores 1º',
                style: const TextStyle(color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Controle Deslizante (Matérias <--> Assuntos)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() { _verAssuntos = false; });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_verAssuntos ? const Color(0xFF4DA6FF).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text('Matérias', style: TextStyle(color: !_verAssuntos ? const Color(0xFF4DA6FF) : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() { _verAssuntos = true; });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _verAssuntos ? const Color(0xFF4DA6FF).withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text('Assuntos', style: TextStyle(color: _verAssuntos ? const Color(0xFF4DA6FF) : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // A Lista do Semáforo
        if (listaAtual.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                'Sem dados suficientes nesta semana.\nResolva questões para ativar o Raio-X!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Evita scroll duplo com a página
            itemCount: listaAtual.length,
            itemBuilder: (context, index) {
              final item = listaAtual[index];
              double perc = item['percentual'];
              
              // Lógica Semáforo
              Color corBarra = perc >= 70 ? const Color(0xFF81C784) : (perc >= 50 ? const Color(0xFFFF9900) : const Color(0xFFE57373));

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade900),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['nome'], 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                        Text(
                          '${perc.toStringAsFixed(1)}%', 
                          style: TextStyle(color: corBarra, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item['acertos']} acertos em ${item['total']} questões', 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)
                    ),
                    const SizedBox(height: 12),
                    // Barra de Progresso visual super refinada
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
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4DA6FF)));
    }

    double aproveitamentoSemana = _totalSemana > 0 ? (_acertosSemana / _totalSemana) * 100 : 0;
    Color corAproveitamento = aproveitamentoSemana >= 70 ? const Color(0xFF81C784) : (aproveitamentoSemana >= 50 ? const Color(0xFFFF9900) : const Color(0xFFE57373));

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CARD DE RESUMO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade900),
                ),
                child: Column(
                  children: [
                    const Text('Aproveitamento nos últimos 7 dias', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('$_totalSemana', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text('Questões', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade800),
                        Column(
                          children: [
                            Text('${aproveitamentoSemana.toStringAsFixed(1)}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: corAproveitamento)),
                            const Text('Acertos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // CABEÇALHO DO GRÁFICO DIÁRIO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Volume e Precisão',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _mostrarGraficoBarras = !_mostrarGraficoBarras;
                      });
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF4DA6FF), size: 20),
                    label: const Text('Mudar', style: TextStyle(color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFF4DA6FF).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _mostrarGraficoBarras ? _construirGraficoBarrasDuplas() : _construirGraficoLinhas(),
              ),
              
              const SizedBox(height: 40),
              
              // --- A NOVA MÁGICA: O RAIO-X ---
              _construirRaioX(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// PINTOR DO GRÁFICO DE LINHAS
class _GraficoLinhasPainter extends CustomPainter {
  final Map<DateTime, Map<String, int>> questoesPorDia;
  final List<DateTime> dias;
  final int maiorValor;

  _GraficoLinhasPainter({
    required this.questoesPorDia,
    required this.dias,
    required this.maiorValor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dias.isEmpty || maiorValor == 0) return;

    final double stepX = size.width / (dias.length > 1 ? dias.length - 1 : 1);
    
    final Paint linhaTotalPaint = Paint()
      ..color = const Color(0xFF4DA6FF).withValues(alpha: 0.5) 
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
      
    final Paint linhaAcertosPaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.5) 
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final Paint pontoTotalPaint = Paint()..color = const Color(0xFF4DA6FF)..style = PaintingStyle.fill;
    final Paint pontoAcertosPaint = Paint()..color = const Color(0xFF81C784)..style = PaintingStyle.fill;
    final Paint mioloPontoPaint = Paint()..color = const Color(0xFF1C1C1C)..style = PaintingStyle.fill;

    Path pathTotal = Path();
    Path pathAcertos = Path();

    List<Offset> pontosTotal = [];
    List<Offset> pontosAcertos = [];

    for (int i = 0; i < dias.length; i++) {
      int total = questoesPorDia[dias[i]]?['total'] ?? 0;
      int acertos = questoesPorDia[dias[i]]?['acertos'] ?? 0;

      double x = i * stepX;
      double yTotal = size.height - ((total / maiorValor) * size.height);
      double yAcertos = size.height - ((acertos / maiorValor) * size.height);

      pontosTotal.add(Offset(x, yTotal));
      pontosAcertos.add(Offset(x, yAcertos));

      if (i == 0) {
        pathTotal.moveTo(x, yTotal);
        pathAcertos.moveTo(x, yAcertos);
      } else {
        pathTotal.lineTo(x, yTotal);
        pathAcertos.lineTo(x, yAcertos);
      }
    }

    canvas.drawPath(pathTotal, linhaTotalPaint);
    canvas.drawPath(pathAcertos, linhaAcertosPaint);

    for (var p in pontosTotal) {
      canvas.drawCircle(p, 6, pontoTotalPaint); 
      canvas.drawCircle(p, 3, mioloPontoPaint); 
    }
    for (var p in pontosAcertos) {
      canvas.drawCircle(p, 6, pontoAcertosPaint); 
      canvas.drawCircle(p, 3, mioloPontoPaint); 
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}