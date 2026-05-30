// lib/telas/tela_modo_prova.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart'; // Mantém o motor de vibração nativo
import '../modelos/sessao_estudo.dart';

class TelaModoProva extends StatefulWidget {
  const TelaModoProva({super.key});

  @override
  State<TelaModoProva> createState() => _TelaModoProvaState();
}

class _TelaModoProvaState extends State<TelaModoProva> {
  // Configuração
  int _horasSelecionadas = 4;
  int _minutosSelecionados = 30;
  
  // Execução
  bool _emProva = false;
  DateTime? _horaFimAlvo;
  int _tempoTotalSegundos = 0;
  int _tempoRestanteSegundos = 0;
  Timer? _timer;

  void _iniciarProva() {
    setState(() {
      _tempoTotalSegundos = (_horasSelecionadas * 3600) + (_minutosSelecionados * 60);
      _tempoRestanteSegundos = _tempoTotalSegundos;
      _horaFimAlvo = DateTime.now().add(Duration(seconds: _tempoTotalSegundos));
      _emProva = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_horaFimAlvo != null) {
        final agora = DateTime.now();
        final diferenca = _horaFimAlvo!.difference(agora).inSeconds;

        if (diferenca <= 0) {
          _finalizarTempo(tempoEsgotado: true);
        } else {
          setState(() {
            _tempoRestanteSegundos = diferenca;
          });
        }
      }
    });
  }

  void _finalizarTempo({required bool tempoEsgotado}) async {
    _timer?.cancel();
    
    if (tempoEsgotado) {
      setState(() { _tempoRestanteSegundos = 0; });
      
      bool? temVibrador = await Vibration.hasVibrator();
      if (temVibrador == true) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000]); 
      }
    }

    // --- CARREGAR HISTÓRICO ANTES DE ABRIR O PAINEL AUTOMÁTICO ---
    final prefs = await SharedPreferences.getInstance();
    List<String> dados = prefs.getStringList('sessoes_estudo') ?? [];
    
    Set<String> materiasUnicas = {}; 
    Set<String> assuntosUnicos = {}; 
    
    for (var jsonStr in dados) {
      var map = jsonDecode(jsonStr);
      if (map['materia'] != null && map['materia'].toString().trim().isNotEmpty) {
        materiasUnicas.add(map['materia'].toString().trim());
      }
      if (map['assunto'] != null && map['assunto'].toString().trim().isNotEmpty) {
        assuntosUnicos.add(map['assunto'].toString().trim());
      }
    }
    
    List<String> listaMaterias = materiasUnicas.toList()..sort();
    List<String> listaAssuntos = assuntosUnicos.toList()..sort();

    if (mounted) {
      _abrirPainelPosProva(listaMaterias, listaAssuntos);
    }
  }

  void _confirmarEntregaAntecipada() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFF4DA6FF)),
              SizedBox(width: 8),
              Text('Entregar Prova?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Tem a certeza que deseja finalizar o simulado agora? O tempo utilizado será registado.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continuar Prova', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _finalizarTempo(tempoEsgotado: false);
              },
              child: const Text('Sim, Entregar', style: TextStyle(color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _abrirPainelPosProva(List<String> listaMaterias, List<String> listaAssuntos) {
    final formKey = GlobalKey<FormState>();
    final materiaController = TextEditingController();
    final assuntoController = TextEditingController();
    final totalQuestoesController = TextEditingController();
    final acertosController = TextEditingController();
    final obsController = TextEditingController();
    
    int tempoUsado = _tempoTotalSegundos - _tempoRestanteSegundos;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, 
      enableDrag: false, 
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 32, 
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Simulado Concluído! 🏆',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tempo utilizado: ${_formatarTempo(tempoUsado)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  // --- AUTOCOMPLETE: MATÉRIA (NOME DO SIMULADO) ---
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return listaMaterias.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      materiaController.text = selection; 
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      fieldController.addListener(() {
                        materiaController.text = fieldController.text;
                      });

                      return TextFormField(
                        controller: fieldController,
                        focusNode: fieldFocusNode,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                        decoration: InputDecoration(
                          labelText: 'Qual foi o Simulado? (Ex: EsPCEx, ENEM)*',
                          labelStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: const Color(0xFF0F0F0F),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                        ),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48, 
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                    child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // --- AUTOCOMPLETE: ASSUNTO ---
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return listaAssuntos.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      assuntoController.text = selection; 
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                      fieldController.addListener(() {
                        assuntoController.text = fieldController.text;
                      });

                      return TextFormField(
                        controller: fieldController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Assunto (Opcional)',
                          hintText: 'Ex: Geometria Analítica',
                          hintStyle: TextStyle(color: Colors.grey.shade700),
                          labelStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: const Color(0xFF0F0F0F),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48, 
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                    child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: totalQuestoesController,
                          keyboardType: TextInputType.number,
                          validator: (value) => (value == null || value.isEmpty) ? 'Obrigatório' : null,
                          decoration: InputDecoration(labelText: 'Total Questões *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: acertosController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Obrigatório';
                            int? acertos = int.tryParse(value);
                            int? total = int.tryParse(totalQuestoesController.text);
                            if (acertos != null && total != null && acertos > total) return 'Acertos > Total';
                            return null;
                          },
                          decoration: InputDecoration(labelText: 'Acertos *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: obsController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Observações / O que errou mais?', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final novaSessao = SessaoEstudo(
                          materia: materiaController.text,
                          assunto: assuntoController.text,
                          tipoEstudo: 'Simulado', 
                          observacoes: obsController.text,
                          duracaoSegundos: tempoUsado,
                          data: DateTime.now(),
                          totalQuestoes: int.tryParse(totalQuestoesController.text),
                          acertos: int.tryParse(acertosController.text),
                        );

                        final prefs = await SharedPreferences.getInstance();
                        List<String> sessoesSalvas = prefs.getStringList('sessoes_estudo') ?? [];
                        sessoesSalvas.add(jsonEncode(novaSessao.toJson()));
                        await prefs.setStringList('sessoes_estudo', sessoesSalvas);

                        if (context.mounted) {
                          Navigator.pop(context); 
                          Navigator.pop(context); 
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF81C784),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Guardar Resultado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); 
                      Navigator.pop(context); 
                    },
                    child: const Text('Descartar Registo', style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatarTempo(int segundosTotais) {
    int horas = segundosTotais ~/ 3600;
    int minutes = (segundosTotais % 3600) ~/ 60;
    int segundos = segundosTotais % 60;
    
    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Modo Prova', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _emProva ? _construirTelaGuerra() : _construirTelaConfiguracao(),
      ),
    );
  }

  Widget _construirTelaConfiguracao() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.timer_rounded, size: 80, color: Color(0xFF4DA6FF)),
          const SizedBox(height: 24),
          const Text(
            'Preparar Simulado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Defina o tempo limite da prova. Não haverá botão de pausa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _seletorDeTempo(
                'Horas', 
                _horasSelecionadas, 
                12, 
                (val) => setState(() => _horasSelecionadas = val)
              ),
              const SizedBox(width: 24),
              const Text(':', style: TextStyle(fontSize: 40, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 24),
              _seletorDeTempo(
                'Minutos', 
                _minutosSelecionados, 
                59, 
                (val) => setState(() => _minutosSelecionados = val)
              ),
            ],
          ),
          
          const SizedBox(height: 64),
          ElevatedButton(
            onPressed: (_horasSelecionadas == 0 && _minutosSelecionados == 0) ? null : _iniciarProva,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: const Color(0xFF4DA6FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            child: const Text('INICIAR GUERRA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _seletorDeTempo(String label, int valorAtual, int max, Function(int) aoMudar) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: DropdownButton<int>(
            value: valorAtual,
            dropdownColor: const Color(0xFF2D2D2D),
            underline: const SizedBox(), 
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
            items: List.generate(max + 1, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text(index.toString().padLeft(2, '0')),
              );
            }),
            onChanged: (val) {
              if (val != null) aoMudar(val);
            },
          ),
        ),
      ],
    );
  }

  Widget _construirTelaGuerra() {
    double progresso = _tempoTotalSegundos > 0 ? (_tempoRestanteSegundos / _tempoTotalSegundos) : 0;
    
    bool isCritico = _tempoRestanteSegundos <= 900 || progresso < 0.10;
    Color corAnel = isCritico ? const Color(0xFFE57373) : const Color(0xFF4DA6FF);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: progresso,
                  strokeWidth: 16, 
                  backgroundColor: const Color(0xFF1C1C1C),
                  valueColor: AlwaysStoppedAnimation<Color>(corAnel),
                  strokeCap: StrokeCap.round, 
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TEMPO RESTANTE', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(
                    _formatarTempo(_tempoRestanteSegundos),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: isCritico ? const Color(0xFFE57373) : Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
          child: TextButton.icon(
            onPressed: _confirmarEntregaAntecipada,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Entregar Prova', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              foregroundColor: const Color(0xFF81C784), 
              backgroundColor: const Color(0xFF81C784).withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(double.infinity, 0), 
            ),
          ),
        ),
      ],
    );
  }
}