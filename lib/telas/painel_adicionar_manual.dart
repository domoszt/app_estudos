// lib/telas/painel_adicionar_manual.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/sessao_estudo.dart';

class PainelAdicionarManual extends StatefulWidget {
  final List<String> listaMaterias;
  final List<String> listaAssuntos;
  final VoidCallback aoSalvar;

  const PainelAdicionarManual({
    super.key,
    required this.listaMaterias,
    required this.listaAssuntos,
    required this.aoSalvar,
  });

  @override
  State<PainelAdicionarManual> createState() => _PainelAdicionarManualState();
}

class _PainelAdicionarManualState extends State<PainelAdicionarManual> {
  final _formKey = GlobalKey<FormState>();
  
  final _materiaController = TextEditingController();
  final _materiaFocus = FocusNode();
  final _assuntoController = TextEditingController();
  final _assuntoFocus = FocusNode();
  
  final _obsController = TextEditingController();
  final _totalQuestoesController = TextEditingController();
  final _acertosController = TextEditingController();
  final _horasController = TextEditingController();
  final _minutosController = TextEditingController();
  
  String? _tipoSelecionado;
  String _modoTempo = 'Duração Total'; 
  DateTime _dataEscolhida = DateTime.now();
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;

  final List<String> _tiposDeEstudo = [
    'Teoria',
    'Questões',
    'Teoria e Questões',
    'Prática de Redação',
    'Simulado'
  ];

  @override
  void dispose() {
    _materiaController.dispose();
    _materiaFocus.dispose();
    _assuntoController.dispose();
    _assuntoFocus.dispose();
    _obsController.dispose();
    _totalQuestoesController.dispose();
    _acertosController.dispose();
    _horasController.dispose();
    _minutosController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_modoTempo == 'Início e Fim') {
      if (_horaInicio == null || _horaFim == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, defina a hora de Início e de Fim.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Color(0xFFE57373),
          ),
        );
        return; 
      }
    }

    if (_formKey.currentState!.validate()) {
      int duracaoSegundosFinal = 0;
      
      if (_modoTempo == 'Duração Total') {
        int h = int.tryParse(_horasController.text) ?? 0;
        int m = int.tryParse(_minutosController.text) ?? 0;
        duracaoSegundosFinal = (h * 3600) + (m * 60);
      } else if (_modoTempo == 'Início e Fim') {
        if (_horaInicio != null && _horaFim != null) {
          int startMin = _horaInicio!.hour * 60 + _horaInicio!.minute;
          int endMin = _horaFim!.hour * 60 + _horaFim!.minute;
          if (endMin < startMin) endMin += 24 * 60; 
          duracaoSegundosFinal = (endMin - startMin) * 60;
        }
      } else if (_modoTempo == 'Sem tempo (Só questões)') {
        duracaoSegundosFinal = 0;
      }

      if (_modoTempo != 'Sem tempo (Só questões)' && duracaoSegundosFinal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A duração do estudo tem de ser maior que zero.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Color(0xFFE57373),
          ),
        );
        return; 
      }

      final novaSessao = SessaoEstudo(
        materia: _materiaController.text, 
        assunto: _assuntoController.text, 
        tipoEstudo: _tipoSelecionado!,
        observacoes: _obsController.text,
        duracaoSegundos: duracaoSegundosFinal,
        data: _dataEscolhida, 
        totalQuestoes: int.tryParse(_totalQuestoesController.text),
        acertos: int.tryParse(_acertosController.text),
      );

      final prefs = await SharedPreferences.getInstance();
      List<String> sessoesSalvas = prefs.getStringList('sessoes_estudo') ?? [];
      sessoesSalvas.add(jsonEncode(novaSessao.toJson()));
      await prefs.setStringList('sessoes_estudo', sessoesSalvas);

      if (mounted) {
        Navigator.pop(context);
        widget.aoSalvar(); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão adicionada com sucesso!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Color(0xFF4DA6FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool mostrarCamposDeQuestao = _tipoSelecionado == 'Questões' || _tipoSelecionado == 'Teoria e Questões' || _tipoSelecionado == 'Simulado';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Adicionar Sessão Manual',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4DA6FF)),
                title: const Text('Data do Estudo', style: TextStyle(color: Colors.grey, fontSize: 14)),
                subtitle: Text(
                  "${_dataEscolhida.day.toString().padLeft(2, '0')}/${_dataEscolhida.month.toString().padLeft(2, '0')}/${_dataEscolhida.year}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final DateTime? escolhida = await showDatePicker(
                      context: context,
                      initialDate: _dataEscolhida,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF4DA6FF),
                              surface: Color(0xFF2D2D2D),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (escolhida != null) {
                      setState(() => _dataEscolhida = escolhida);
                    }
                  },
                  child: const Text('Alterar', style: TextStyle(color: Color(0xFF4DA6FF))),
                ),
              ),
              Divider(color: Colors.grey.shade800),
              const SizedBox(height: 16),

              const Text('Método de Tempo', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _modoTempo,
                dropdownColor: const Color(0xFF2D2D2D),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F0F0F),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: ['Duração Total', 'Início e Fim', 'Sem tempo (Só questões)'].map((String modo) {
                  return DropdownMenuItem<String>(
                    value: modo,
                    child: Text(modo, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (String? novoValor) {
                  setState(() {
                    _modoTempo = novoValor!;
                    if (_modoTempo == 'Sem tempo (Só questões)') {
                      _tipoSelecionado = 'Questões';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_modoTempo == 'Duração Total')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _horasController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          int h = int.tryParse(_horasController.text) ?? 0;
                          int m = int.tryParse(_minutosController.text) ?? 0;
                          if (h <= 0 && m <= 0) return 'Campo obrigatório';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Horas *', 
                          filled: true, 
                          fillColor: const Color(0xFF0F0F0F), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                          errorStyle: const TextStyle(fontSize: 10),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minutosController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          int h = int.tryParse(_horasController.text) ?? 0;
                          int m = int.tryParse(_minutosController.text) ?? 0;
                          if (h <= 0 && m <= 0) return 'Campo obrigatório';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Minutos *', 
                          filled: true, 
                          fillColor: const Color(0xFF0F0F0F), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                          errorStyle: const TextStyle(fontSize: 10),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              else if (_modoTempo == 'Início e Fim')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) setState(() => _horaInicio = time);
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_horaInicio == null ? 'Início *' : _horaInicio!.format(context)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F0F0F), 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: _horaInicio == null ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (time != null) setState(() => _horaFim = time);
                        },
                        icon: const Icon(Icons.access_time_filled),
                        label: Text(_horaFim == null ? 'Fim *' : _horaFim!.format(context)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F0F0F), 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: _horaFim == null ? const BorderSide(color: Colors.redAccent) : BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade800),
              const SizedBox(height: 16),

              RawAutocomplete<String>(
                textEditingController: _materiaController, 
                focusNode: _materiaFocus, 
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return widget.listaMaterias.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Obrigatório';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Matéria *',
                      hintText: 'Ex: Matemática',
                      hintStyle: TextStyle(color: Colors.grey.shade700),
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

              RawAutocomplete<String>(
                textEditingController: _assuntoController, 
                focusNode: _assuntoFocus, 
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                  return widget.listaAssuntos.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
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

              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                dropdownColor: const Color(0xFF2D2D2D),
                validator: (value) => (value == null || value.isEmpty) ? 'Selecione um tipo' : null,
                decoration: InputDecoration(
                  labelText: 'Tipo de estudo *', 
                  filled: true, 
                  fillColor: const Color(0xFF0F0F0F), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1))
                ),
                items: _tiposDeEstudo.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo, 
                    child: Text(tipo, style: const TextStyle(color: Colors.white))
                  );
                }).toList(),
                onChanged: _modoTempo == 'Sem tempo (Só questões)' ? null : (String? novoValor) {
                  setState(() {
                    _tipoSelecionado = novoValor;
                    bool mostraQ = novoValor == 'Questões' || novoValor == 'Teoria e Questões' || novoValor == 'Simulado';
                    if (!mostraQ) {
                      _totalQuestoesController.clear();
                      _acertosController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (mostrarCamposDeQuestao) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalQuestoesController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Obrigatório';
                          int? val = int.tryParse(value);
                          if (val == null || val <= 0) return 'Deve ser > 0';
                          return null;
                        },
                        decoration: InputDecoration(labelText: 'Total Questões *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)), errorStyle: const TextStyle(fontSize: 10)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _acertosController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Obrigatório';
                          int? acertos = int.tryParse(value);
                          int? total = int.tryParse(_totalQuestoesController.text);
                          if (acertos == null || acertos < 0) return 'Inválido';
                          if (total != null && acertos > total) return 'Acertos > Total';
                          return null;
                        },
                        decoration: InputDecoration(labelText: 'Acertos *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)), errorStyle: const TextStyle(fontSize: 10)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _obsController,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Observações (Opcional)', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFF4DA6FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar Registo Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}