// lib/telas/tela_cronometro.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/sessao_estudo.dart';

class TelaCronometro extends StatefulWidget {
  const TelaCronometro({super.key});

  @override
  State<TelaCronometro> createState() => _TelaCronometroState();
}

class _TelaCronometroState extends State<TelaCronometro> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  Timer? _timer;
  
  int _segundosAcumulados = 0; 
  int _segundosExibicao = 0;   
  DateTime? _horaUltimoPlay;   
  
  bool _estaRodando = false;

  // --- VARIÁVEIS DA META DIÁRIA ---
  int _tempoEstudadoHoje = 0;
  int _metaDiariaSegundos = 0;

  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _assuntoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _totalQuestoesController = TextEditingController();
  final TextEditingController _acertosController = TextEditingController();

  String? _tipoSelecionado; 

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
    _carregarRadarDiario();
    notificadorVanguard.addListener(_carregarRadarDiario); 
  }

  @override
  void dispose() {
    _timer?.cancel();
    notificadorVanguard.removeListener(_carregarRadarDiario);
    _materiaController.dispose();
    _assuntoController.dispose();
    _observacoesController.dispose();
    _totalQuestoesController.dispose();
    _acertosController.dispose();
    super.dispose();
  }

  Future<void> _carregarRadarDiario() async {
    final prefs = await SharedPreferences.getInstance();
    
    _metaDiariaSegundos = prefs.getInt('meta_diaria_segundos') ?? 0;

    List<String> dadosSalvos = prefs.getStringList('sessoes_estudo') ?? [];
    int tempoHoje = 0;
    DateTime agora = DateTime.now();
    
    for (var jsonStr in dadosSalvos) {
      var map = jsonDecode(jsonStr);
      if (map['data'] != null) {
        DateTime dataSessao = DateTime.parse(map['data']);
        if (dataSessao.year == agora.year && dataSessao.month == agora.month && dataSessao.day == agora.day) {
          tempoHoje += (map['duracaoSegundos'] as int? ?? 0);
        }
      }
    }

    if (mounted) {
      setState(() {
        _tempoEstudadoHoje = tempoHoje;
      });
    }
  }

  String _formatarTempo(int segundosTotais) {
    int horas = segundosTotais ~/ 3600;
    int minutos = (segundosTotais % 3600) ~/ 60;
    int segundos = segundosTotais % 60;

    String horasStr = horas.toString().padLeft(2, '0');
    String minutosStr = minutos.toString().padLeft(2, '0');
    String segundosStr = segundos.toString().padLeft(2, '0');

    return '$horasStr:$minutosStr:$segundosStr';
  }

  void _alternarCronometro() {
    if (_estaRodando) {
      _timer?.cancel();
      if (_horaUltimoPlay != null) {
        _segundosAcumulados += DateTime.now().difference(_horaUltimoPlay!).inSeconds;
      }
      setState(() {
        _estaRodando = false;
        _horaUltimoPlay = null; 
      });
    } else {
      setState(() {
        _estaRodando = true;
        _horaUltimoPlay = DateTime.now(); 
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_horaUltimoPlay != null) {
          setState(() {
            int segundosDesdeOPlay = DateTime.now().difference(_horaUltimoPlay!).inSeconds;
            _segundosExibicao = _segundosAcumulados + segundosDesdeOPlay;
          });
        }
      });
    }
  }

  void _finalizarSessao() {
    _timer?.cancel();
    setState(() {
      _estaRodando = false;
      _segundosAcumulados = 0;
      _segundosExibicao = 0;
      _horaUltimoPlay = null;
      _tipoSelecionado = null; 
    });
    _materiaController.clear();
    _assuntoController.clear();
    _observacoesController.clear();
    _totalQuestoesController.clear();
    _acertosController.clear();
  }

  Future<void> _salvarSessaoNoBanco(SessaoEstudo sessao) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessoesSalvas = prefs.getStringList('sessoes_estudo') ?? [];
    sessoesSalvas.add(jsonEncode(sessao.toJson()));
    await prefs.setStringList('sessoes_estudo', sessoesSalvas);
    
    notificadorVanguard.value++; 
  }

  void _mostrarConfirmacaoDescarte({bool veioDoPainel = false}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Descartar sessão?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Tem certeza que deseja finalizar sem salvar? O tempo registrado será perdido.', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar', style: TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (veioDoPainel) Navigator.pop(context);
                _finalizarSessao();
              },
              child: const Text('Sim, finalizar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _abrirPainelSalvar() async {
    if (_estaRodando) _alternarCronometro();

    final prefs = await SharedPreferences.getInstance();
    List<String> dados = prefs.getStringList('sessoes_estudo') ?? [];
    Set<String> materiasUnicas = {}; 
    Set<String> assuntosUnicos = {}; 
    
    for (var jsonStr in dados) {
      var map = jsonDecode(jsonStr);
      if (map['materia'] != null && map['materia'].toString().trim().isNotEmpty) materiasUnicas.add(map['materia'].toString().trim());
      if (map['assunto'] != null && map['assunto'].toString().trim().isNotEmpty) assuntosUnicos.add(map['assunto'].toString().trim());
    }
    
    List<String> listaMaterias = materiasUnicas.toList()..sort();
    List<String> listaAssuntos = assuntosUnicos.toList()..sort(); 
    
    if (!mounted) return; 

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool mostrarCamposDeQuestao = _tipoSelecionado == 'Questões' || _tipoSelecionado == 'Teoria e Questões' || _tipoSelecionado == 'Simulado';

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Registrar Sessão', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 24),

                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: _materiaController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return listaMaterias.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) => _materiaController.text = selection,
                        fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                          fieldController.addListener(() => _materiaController.text = fieldController.text);
                          return TextFormField(
                            controller: fieldController, focusNode: fieldFocusNode, validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                            decoration: InputDecoration(labelText: 'Matéria *', hintText: 'Ex: Matemática', hintStyle: TextStyle(color: Colors.grey.shade700), labelStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1))),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                          return Align(alignment: Alignment.topLeft, child: Material(color: Colors.transparent, child: Container(width: MediaQuery.of(context).size.width - 48, margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)), child: ListView.builder(padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length, itemBuilder: (BuildContext context, int index) { final String option = options.elementAt(index); return InkWell(onTap: () => onSelected(option), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 15))));}))));
                        },
                      ),
                      const SizedBox(height: 16),

                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: _assuntoController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return listaAssuntos.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) => _assuntoController.text = selection,
                        fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                          fieldController.addListener(() => _assuntoController.text = fieldController.text);
                          return TextFormField(
                            controller: fieldController, focusNode: fieldFocusNode,
                            decoration: InputDecoration(labelText: 'Assunto (Opcional)', hintText: 'Ex: Geometria Analítica', hintStyle: TextStyle(color: Colors.grey.shade700), labelStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                          return Align(alignment: Alignment.topLeft, child: Material(color: Colors.transparent, child: Container(width: MediaQuery.of(context).size.width - 48, margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade800)), child: ListView.builder(padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length, itemBuilder: (BuildContext context, int index) { final String option = options.elementAt(index); return InkWell(onTap: () => onSelected(option), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 15))));}))));
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _tipoSelecionado, dropdownColor: const Color(0xFF2D2D2D), validator: (value) => (value == null || value.isEmpty) ? 'Obrigatório.' : null,
                        decoration: InputDecoration(labelText: 'Tipo de estudo *', labelStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1))),
                        items: _tiposDeEstudo.map((String tipo) => DropdownMenuItem<String>(value: tipo, child: Text(tipo, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (String? novoValor) {
                          setModalState(() {
                            _tipoSelecionado = novoValor;
                            if (!mostrarCamposDeQuestao) { _totalQuestoesController.clear(); _acertosController.clear(); }
                          });
                        },
                      ),
                      
                      if (mostrarCamposDeQuestao) ...[
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalQuestoesController, keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Obrigatório';
                                  int? val = int.tryParse(value);
                                  if (val == null || val <= 0) return 'Deve ser > 0'; 
                                  return null;
                                },
                                decoration: InputDecoration(labelText: 'Total de Questões', labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13), filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)), errorStyle: const TextStyle(fontSize: 10)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _acertosController, keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Obrigatório';
                                  int? acertos = int.tryParse(value);
                                  int? total = int.tryParse(_totalQuestoesController.text);
                                  if (acertos == null || acertos < 0) return 'Inválido'; 
                                  if (total != null && acertos > total) return 'Acertos > Total';
                                  return null;
                                },
                                decoration: InputDecoration(labelText: 'Acertos', labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13), filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)), errorStyle: const TextStyle(fontSize: 10)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _observacoesController, maxLines: 3,
                        decoration: InputDecoration(labelText: 'Observações (Opcional)', labelStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final novaSessao = SessaoEstudo(
                              materia: _materiaController.text, assunto: _assuntoController.text, tipoEstudo: _tipoSelecionado!, observacoes: _observacoesController.text, duracaoSegundos: _segundosExibicao, data: DateTime.now(), totalQuestoes: int.tryParse(_totalQuestoesController.text), acertos: int.tryParse(_acertosController.text),
                            );
                            await _salvarSessaoNoBanco(novaSessao);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _finalizarSessao();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessão registrada com sucesso!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Color(0xFF4DA6FF), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 3)));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: const Color(0xFF2D2D2D), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Salvar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () => _mostrarConfirmacaoDescarte(veioDoPainel: true),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.redAccent),
                        child: const Text('Finalizar sem salvar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
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

  // ===========================================================================
  // CONSTRUTOR DA BARRA TÁTICA (HUD TOP)
  // ===========================================================================
  Widget _construirBarraProgresso() {
    if (_metaDiariaSegundos <= 0) return const SizedBox.shrink();

    int tempoTotalHoje = _tempoEstudadoHoje + _segundosExibicao;
    double progresso = tempoTotalHoje / _metaDiariaSegundos;

    // A barra principal enche apenas até aos 100% (1.0)
    double progressoBase = progresso > 1.0 ? 1.0 : progresso;
    
    // O excedente calcula quanto passou dos 100%
    double progressoExtra = progresso > 1.0 ? progresso - 1.0 : 0.0;
    
    // Limitamos o excedente a 1.0 (200% do total) para o layout nunca quebrar
    if (progressoExtra > 1.0) progressoExtra = 1.0; 

    bool metaAtingida = progresso >= 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hoje: ${_formatarTempo(tempoTotalHoje)}',
                style: TextStyle(
                  color: metaAtingida ? const Color(0xFF81C784) : const Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Meta: ${_formatarTempo(_metaDiariaSegundos)}',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // 1. O trilho escuro (vazio)
                  Container(
                    height: 6,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // 2. A barra principal (Azul a encher, Verde quando chega a 100%)
                  Container(
                    height: 6,
                    width: constraints.maxWidth * progressoBase,
                    decoration: BoxDecoration(
                      color: metaAtingida ? const Color(0xFF81C784) : const Color(0xFF9E9E9E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // 3. A barra excedente (Inicia por cima com menor opacidade)
                  if (progressoExtra > 0)
                    Container(
                      height: 6,
                      width: constraints.maxWidth * progressoExtra,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 51, 153, 56).withValues(alpha: 0.8), 
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A NOSSA NOVA BARRA DE PROGRESSO COLOCADA NO TOPO
            _construirBarraProgresso(),
            
            const Spacer(),
            
            // O CRONÓMETRO CENTRALIZADO COMO SEMPRE
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _alternarCronometro,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    _formatarTempo(_segundosExibicao), 
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (_segundosExibicao > 0 || _estaRodando) ...[
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _abrirPainelSalvar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: const Color(0xFFFFFFFF),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Finalizar e Salvar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _mostrarConfirmacaoDescarte(veioDoPainel: false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Finalizar sem salvar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}