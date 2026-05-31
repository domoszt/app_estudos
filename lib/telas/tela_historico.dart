// lib/telas/tela_historico.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/sessao_estudo.dart';
import 'tela_estatisticas.dart';
import '../utilidades/gerador_cores.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

// 1. BLINDAGEM ADICIONADA AQUI (with AutomaticKeepAliveClientMixin)
class _TelaHistoricoState extends State<TelaHistorico> with AutomaticKeepAliveClientMixin {
  
  // 2. BLINDAGEM ADICIONADA AQUI (wantKeepAlive)
  @override
  bool get wantKeepAlive => true;

  bool _carregando = true;
  int _diasOfensiva = 0;
  
  // 0: 7 Dias, 1: Mês Atual, 2: Desde o Início
  int _filtroTempo = 0; 
  
  DateTime _diaSelecionado = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  
  List<SessaoEstudo> _todasSessoes = []; 
  final Map<DateTime, int> _tempoPorDia = {};
  final List<DateTime> _ultimos7Dias = [];
  
  int _maiorTempoNaSemana = 0; 
  int _maiorTempoNoMes = 0;

  final List<String> _tiposDeEstudo = [
    'Teoria',
    'Questões',
    'Teoria e Questões',
    'Prática de Redação',
    'Simulado'
  ];

 @override
  void initState() {
    super.initState();
    _processarDadosDoBanco();
    notificadorVanguard.addListener(_processarDadosDoBanco); // Liga o rádio
  }

  @override
  void dispose() {
    notificadorVanguard.removeListener(_processarDadosDoBanco); // Desliga o rádio
    super.dispose();
  }

  Future<void> _salvarTodasSessoesNoBanco() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessoesSalvas = _todasSessoes.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('sessoes_estudo', sessoesSalvas);
    notificadorVanguard.value++; // Avisa a app inteira que algo foi apagado ou editado!
  }

  DateTime _zerarHorario(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  Future<void> _processarDadosDoBanco() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dadosSalvos = prefs.getStringList('sessoes_estudo') ?? [];
    
    _todasSessoes = dadosSalvos.map((jsonStr) {
      return SessaoEstudo.fromJson(jsonDecode(jsonStr));
    }).toList();

    _tempoPorDia.clear();
    for (var sessao in _todasSessoes) {
      DateTime diaLimpo = _zerarHorario(sessao.data);
      if (_tempoPorDia.containsKey(diaLimpo)) {
        _tempoPorDia[diaLimpo] = _tempoPorDia[diaLimpo]! + sessao.duracaoSegundos;
      } else {
        _tempoPorDia[diaLimpo] = sessao.duracaoSegundos;
      }
    }

    DateTime hoje = _zerarHorario(DateTime.now());
    
    _ultimos7Dias.clear();
    _maiorTempoNaSemana = 0;
    for (int i = 6; i >= 0; i--) {
      DateTime diaAnterior = hoje.subtract(Duration(days: i));
      _ultimos7Dias.add(diaAnterior);
      
      int tempoDesteDia = _tempoPorDia[diaAnterior] ?? 0;
      if (tempoDesteDia > _maiorTempoNaSemana) {
        _maiorTempoNaSemana = tempoDesteDia;
      }
    }

    _maiorTempoNoMes = 0;
    int diasNoMes = DateUtils.getDaysInMonth(hoje.year, hoje.month);
    for (int i = 1; i <= diasNoMes; i++) {
      DateTime dia = DateTime(hoje.year, hoje.month, i);
      int tempo = _tempoPorDia[dia] ?? 0;
      if (tempo > _maiorTempoNoMes) {
        _maiorTempoNoMes = tempo;
      }
    }

    int contagem = 0;
    DateTime diaChecagem = hoje;
    
    if (!(_tempoPorDia.containsKey(hoje) && _tempoPorDia[hoje]! > 0)) {
      diaChecagem = hoje.subtract(const Duration(days: 1));
    }

    while (_tempoPorDia.containsKey(diaChecagem) && _tempoPorDia[diaChecagem]! > 0) {
      contagem++;
      diaChecagem = diaChecagem.subtract(const Duration(days: 1));
    }

    if (!mounted) return;

    setState(() {
      _diasOfensiva = contagem;
      _carregando = false;
    });
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

  String _formatarTempo(int duracaoSegundos) {
    int h = duracaoSegundos ~/ 3600;
    int m = (duracaoSegundos % 3600) ~/ 60;
    int s = duracaoSegundos % 60;
    if (h > 0) return "${h}h ${m}m";
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  void _mostrarMenuOpcoes(SessaoEstudo sessao) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Colors.white),
                title: const Text('Detalhes', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _mostrarDetalhes(sessao); },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.white),
                title: const Text('Editar sessão', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); _mostrarEdicao(sessao); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Excluir sessão', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () { Navigator.pop(context); _confirmarExclusao(sessao); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetalhes(SessaoEstudo sessao) {
    Color corMateria = GeradorCores.obterCor(sessao.materia);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(sessao.materia, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tempo: ${_formatarTempo(sessao.duracaoSegundos)}', style: TextStyle(color: corMateria, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text('Tipo: ${sessao.tipoEstudo}', style: const TextStyle(color: Colors.white)),
              if (sessao.totalQuestoes != null && sessao.acertos != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Desempenho: ${sessao.acertos} / ${sessao.totalQuestoes} (${((sessao.acertos! / sessao.totalQuestoes!) * 100).toStringAsFixed(1)}%)', 
                  style: const TextStyle(color: Color(0xFF81C784), fontWeight: FontWeight.bold), 
                ),
              ],
              const SizedBox(height: 8),
              if (sessao.assunto.trim().isNotEmpty) ...[
                Text('Assunto: ${sessao.assunto}', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
              ],
              if (sessao.observacoes.trim().isNotEmpty) ...[
                Divider(color: Colors.grey.shade800, height: 24),
                const Text('Observações:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(sessao.observacoes, style: const TextStyle(color: Colors.white)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar', style: TextStyle(color: Colors.white))),
          ],
        );
      },
    );
  }

  void _confirmarExclusao(SessaoEstudo sessao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Excluir Sessão?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Tem certeza que deseja apagar este registro? Esta ação não pode ser desfeita.', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _todasSessoes.removeWhere((s) => s.data == sessao.data);
                _salvarTodasSessoesNoBanco();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessão apagada.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
              },
              child: const Text('Sim, Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarEdicao(SessaoEstudo sessaoOriginal) {
    Set<String> materiasUnicas = {};
    Set<String> assuntosUnicos = {};
    
    for (var s in _todasSessoes) {
      if (s.materia.trim().isNotEmpty) materiasUnicas.add(s.materia.trim());
      if (s.assunto.trim().isNotEmpty) assuntosUnicos.add(s.assunto.trim());
    }
    
    final formKey = GlobalKey<FormState>();
    final materiaController = TextEditingController(text: sessaoOriginal.materia);
    final assuntoController = TextEditingController(text: sessaoOriginal.assunto);
    final obsController = TextEditingController(text: sessaoOriginal.observacoes);
    final totalQuestoesController = TextEditingController(text: sessaoOriginal.totalQuestoes?.toString() ?? '');
    final acertosController = TextEditingController(text: sessaoOriginal.acertos?.toString() ?? '');
    String? tipoSelecionado = sessaoOriginal.tipoEstudo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool mostrarCamposDeQuestao = tipoSelecionado == 'Questões' || tipoSelecionado == 'Teoria e Questões' || tipoSelecionado == 'Simulado';
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Editar Sessão', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: materiaController,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                        decoration: InputDecoration(labelText: 'Matéria *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: assuntoController,
                        decoration: InputDecoration(labelText: 'Assunto (Opcional)', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: tipoSelecionado,
                        dropdownColor: const Color(0xFF2D2D2D),
                        validator: (value) => (value == null || value.isEmpty) ? 'Obrigatório' : null,
                        decoration: InputDecoration(labelText: 'Tipo de estudo *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: _tiposDeEstudo.map((String tipo) => DropdownMenuItem<String>(value: tipo, child: Text(tipo, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (String? novoValor) {
                          setModalState(() {
                            tipoSelecionado = novoValor;
                            if (novoValor != 'Questões' && novoValor != 'Teoria e Questões' && novoValor != 'Simulado') {
                              totalQuestoesController.clear();
                              acertosController.clear();
                            }
                          });
                        },
                      ),
                      if (mostrarCamposDeQuestao) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: totalQuestoesController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Total Questões', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), style: const TextStyle(color: Colors.white))),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: acertosController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Acertos', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), style: const TextStyle(color: Colors.white))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: obsController,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: 'Observações (Opcional)', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            int index = _todasSessoes.indexWhere((s) => s.data == sessaoOriginal.data);
                            if (index != -1) {
                              _todasSessoes[index] = SessaoEstudo(
                                materia: materiaController.text, assunto: assuntoController.text, tipoEstudo: tipoSelecionado!, observacoes: obsController.text, duracaoSegundos: sessaoOriginal.duracaoSegundos, data: sessaoOriginal.data, totalQuestoes: int.tryParse(totalQuestoesController.text), acertos: int.tryParse(acertosController.text),
                                rev24h: sessaoOriginal.rev24h, rev7d: sessaoOriginal.rev7d, rev30d: sessaoOriginal.rev30d, 
                              );
                              _salvarTodasSessoesNoBanco();
                              Navigator.pop(context);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: const Color(0xFF2D2D2D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Salvar Alterações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirGraficoBarras() {
    return Container(
      key: const ValueKey('barras'), height: 180, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
        children: _ultimos7Dias.map((dia) {
          int tempoDesteDia = _tempoPorDia[dia] ?? 0;
          double alturaBarra = 4.0; 
          if (_maiorTempoNaSemana > 0 && tempoDesteDia > 0) alturaBarra = (tempoDesteDia / _maiorTempoNaSemana) * 110; 
          if (alturaBarra < 4.0) alturaBarra = 4.0; 
          bool isSelecionado = _zerarHorario(dia).isAtSameMomentAs(_diaSelecionado);
          bool isHoje = _zerarHorario(dia).isAtSameMomentAs(_zerarHorario(DateTime.now()));
          Color corTexto = Colors.grey.shade600;
          if (isSelecionado) corTexto = Colors.white;
          else if (isHoje) corTexto = const Color(0xFF4DA6FF);

          return GestureDetector(
            onTap: () => setState(() => _diaSelecionado = _zerarHorario(dia)),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 24, height: alturaBarra, decoration: BoxDecoration(color: tempoDesteDia > 0 ? const Color(0xFF4DA6FF) : const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(6), border: isSelecionado ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5) : null)),
                const SizedBox(height: 12),
                Text(_obterInicialDoDia(dia.weekday), style: TextStyle(color: corTexto, fontSize: 12, fontWeight: (isSelecionado || isHoje) ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirHeatmapMes() {
    DateTime hoje = _zerarHorario(DateTime.now());
    int diasNoMes = DateUtils.getDaysInMonth(hoje.year, hoje.month);
    DateTime primeiroDia = DateTime(hoje.year, hoje.month, 1);
    int espacosVazios = primeiroDia.weekday - 1; 

    return Container(
      key: const ValueKey('heatmap'), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'].map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontSize: 12))).toList()),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: espacosVazios + diasNoMes,
            itemBuilder: (context, index) {
              if (index < espacosVazios) return const SizedBox.shrink(); 
              int diaDoMes = index - espacosVazios + 1;
              DateTime diaAtual = DateTime(hoje.year, hoje.month, diaDoMes);
              int tempoDesteDia = _tempoPorDia[diaAtual] ?? 0;
              bool isSelecionado = diaAtual.isAtSameMomentAs(_diaSelecionado);
              bool isHoje = diaAtual.isAtSameMomentAs(hoje);
              Color corDoQuadrado = const Color(0xFF0F0F0F); 
              if (tempoDesteDia > 0 && _maiorTempoNoMes > 0) {
                double proporcao = tempoDesteDia / _maiorTempoNoMes;
                if (proporcao <= 0.33) corDoQuadrado = const Color(0xFF4DA6FF).withValues(alpha: 0.3);
                else if (proporcao <= 0.66) corDoQuadrado = const Color(0xFF4DA6FF).withValues(alpha: 0.6);
                else corDoQuadrado = const Color(0xFF4DA6FF);
              }
              Border? borda;
              if (isSelecionado) borda = Border.all(color: Colors.white, width: 2.0);
              else if (isHoje) borda = Border.all(color: const Color(0xFF4DA6FF), width: 1.5);
              return GestureDetector(onTap: () => setState(() => _diaSelecionado = diaAtual), child: Container(decoration: BoxDecoration(color: corDoQuadrado, borderRadius: BorderRadius.circular(6), border: borda)));
            },
          ),
        ],
      ),
    );
  }

  Widget _construirResumoTudo() {
    int totalSegundos = 0;
    for (var s in _todasSessoes) totalSegundos += s.duracaoSegundos;
    return Container(
      key: const ValueKey('resumo_tudo'), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.military_tech_rounded, color: Color(0xFF81C784), size: 48),
          const SizedBox(height: 12),
          const Text('Carreira no Vanguard', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tempo Total: ${_formatarTempo(totalSegundos)}', style: const TextStyle(color: Color(0xFF4DA6FF), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Missões (Sessões): ${_todasSessoes.length}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _construirListaSessoes() {
    List<SessaoEstudo> sessoesFiltradas = [];
    String titulo = "";

    if (_filtroTempo == 2) {
      sessoesFiltradas = List.from(_todasSessoes);
      sessoesFiltradas.sort((a, b) => b.data.compareTo(a.data)); // Mais recentes no topo
      titulo = "Todas as Missões";
    } else {
      sessoesFiltradas = _todasSessoes.where((s) => _zerarHorario(s.data).isAtSameMomentAs(_diaSelecionado)).toList();
      sessoesFiltradas.sort((a, b) => a.data.compareTo(b.data)); 
      bool isHoje = _diaSelecionado.isAtSameMomentAs(_zerarHorario(DateTime.now()));
      String dataFormatada = "${_diaSelecionado.day.toString().padLeft(2, '0')}/${_diaSelecionado.month.toString().padLeft(2, '0')}";
      titulo = isHoje ? "Sessões de Hoje" : "Sessões ($dataFormatada)";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        if (sessoesFiltradas.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Center(child: Text('Nenhum registo encontrado.', style: TextStyle(color: Colors.grey, fontSize: 16))))
        else
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: sessoesFiltradas.length,
            itemBuilder: (context, index) {
              final sessao = sessoesFiltradas[index];
              Color corMateria = GeradorCores.obterCor(sessao.materia);

              return GestureDetector(
                onLongPress: () => _mostrarMenuOpcoes(sessao),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Container(width: 4, height: _filtroTempo == 2 ? 50 : 40, decoration: BoxDecoration(color: corMateria, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_filtroTempo == 2) ...[
                              Text("${sessao.data.day.toString().padLeft(2, '0')}/${sessao.data.month.toString().padLeft(2, '0')}/${sessao.data.year}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                            ],
                            Text(sessao.materia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            if (sessao.assunto.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(sessao.assunto, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                            ],
                          ],
                        ),
                      ),
                      Text(_formatarTempo(sessao.duracaoSegundos), style: TextStyle(color: corMateria, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3. BLINDAGEM ADICIONADA AQUI (super.build)
    super.build(context);

    if (_carregando) return const Center(child: CircularProgressIndicator(color: Color(0xFF4DA6FF)));

    String textoFiltro = _filtroTempo == 0 ? 'Últimos 7 dias' : _filtroTempo == 1 ? 'Mês atual' : 'Desde o início';
    Widget graficoAtual = _filtroTempo == 0 ? _construirGraficoBarras() : _filtroTempo == 1 ? _construirHeatmapMes() : _construirResumoTudo();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1C), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4DA6FF).withValues(alpha: 0.3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFF4DA6FF), size: 32),
                    const SizedBox(width: 12),
                    Text('Ofensiva: $_diasOfensiva dias', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(textoFiltro, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton.icon(
                    onPressed: () => setState(() => _filtroTempo = (_filtroTempo + 1) % 3), // CICLO: 0 -> 1 -> 2
                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF4DA6FF), size: 20),
                    label: const Text('Mudar', style: TextStyle(color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), backgroundColor: const Color(0xFF4DA6FF).withValues(alpha: 0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(duration: const Duration(milliseconds: 300), transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: child), child: graficoAtual),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaEstatisticas(todasSessoes: _todasSessoes))),
                  child: const Text('Ver estatísticas completas', style: TextStyle(color: Color(0xFF4DA6FF), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              _construirListaSessoes(),
              const SizedBox(height: 24), 
            ],
          ),
        ),
      ),
    );
  }
}