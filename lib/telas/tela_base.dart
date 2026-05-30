// lib/telas/tela_base.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/sessao_estudo.dart';
import 'tela_cronometro.dart';
import 'tela_historico.dart';
import 'tela_desempenho.dart';
import 'tela_modo_prova.dart';

class TelaBase extends StatefulWidget {
  const TelaBase({super.key});

  @override
  State<TelaBase> createState() => _TelaBaseState();
}

class _TelaBaseState extends State<TelaBase> {
  int _indiceAtual = 0;
  
  Key _chaveAbas = UniqueKey();

  final List<String> _tiposDeEstudo = [
    'Teoria',
    'Questões',
    'Teoria e Questões',
    'Prática de Redação',
    'Simulado'
  ];

  void _atualizarDados() {
    setState(() {
      _chaveAbas = UniqueKey();
    });
  }

  // ===========================================================================
  // SISTEMA DE SEGURANÇA: EXPORTAR BACKUP
  // ===========================================================================
  void _exportarBackup() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessoes = prefs.getStringList('sessoes_estudo') ?? [];

    if (sessoes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar.', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFFE57373)),
      );
      return;
    }

    String jsonString = jsonEncode(sessoes);
    String codigoSeguranca = base64Encode(utf8.encode(jsonString));

    await Clipboard.setData(ClipboardData(text: codigoSeguranca));

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF81C784)),
              SizedBox(width: 8),
              Text('Backup Copiado!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'O seu Código de Segurança foi copiado para a área de transferência do telemóvel.\n\n'
            'Cole-o agora mesmo num Bloco de Notas, E-mail ou envie para si mesmo no WhatsApp para não o perder.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  // ===========================================================================
  // SISTEMA DE SEGURANÇA: IMPORTAR BACKUP
  // ===========================================================================
  void _abrirPainelImportarBackup() {
    final TextEditingController codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Color(0xFF4DA6FF)),
            SizedBox(width: 8),
            Text('Restaurar Dados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cole abaixo o Código de Segurança gerado anteriormente. Atenção: isto substituirá os dados atuais desta aplicação.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codigoController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Cole o código gigante aqui...',
                hintStyle: TextStyle(color: Colors.grey.shade700),
                filled: true,
                fillColor: const Color(0xFF0F0F0F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              String codigoColado = codigoController.text.trim();
              if (codigoColado.isEmpty) return;

              try {
                String jsonString = utf8.decode(base64Decode(codigoColado));
                List<dynamic> dadosDecodificados = jsonDecode(jsonString);
                List<String> sessoesParaSalvar = dadosDecodificados.map((e) => e.toString()).toList();

                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('sessoes_estudo', sessoesParaSalvar);

                if (mounted) {
                  Navigator.pop(context);
                  _atualizarDados(); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados restaurados com sucesso! 🚀', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      backgroundColor: Color(0xFF81C784), 
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código inválido ou corrompido.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: Color(0xFFE57373), 
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Restaurar Backup', style: TextStyle(color: Color(0xFF4DA6FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).whenComplete(() {
      // CODE REVIEW: Limpeza de memória garantida ao fechar o pop-up
      codigoController.dispose();
    });
  }

  // ===========================================================================
  // APAGAR TUDO
  // ===========================================================================
  void _confirmarExclusaoTotal() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Apagar tudo?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Tem a certeza de que deseja apagar TODOS os registos da aplicação? Esta ação é irreversível e irá zerar a sua Ofensiva e o seu Histórico.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('sessoes_estudo'); 
                
                if (mounted) {
                  Navigator.pop(dialogContext);
                  _atualizarDados(); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todos os dados foram apagados.', style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Sim, Apagar Tudo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // ADICIONAR MANUALMENTE
  // ===========================================================================
  void _abrirPainelAdicionarManual() async {
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

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    
    final materiaController = TextEditingController();
    final assuntoController = TextEditingController();
    final obsController = TextEditingController();
    final totalQuestoesController = TextEditingController();
    final acertosController = TextEditingController();
    final horasController = TextEditingController();
    final minutosController = TextEditingController();
    
    String? tipoSelecionado;
    String modoTempo = 'Duração Total'; 
    DateTime dataEscolhida = DateTime.now();
    TimeOfDay? horaInicio;
    TimeOfDay? horaFim;

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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                          "${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final DateTime? escolhida = await showDatePicker(
                              context: context,
                              initialDate: dataEscolhida,
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
                              setModalState(() => dataEscolhida = escolhida);
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
                        value: modoTempo,
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
                          setModalState(() {
                            modoTempo = novoValor!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      if (modoTempo == 'Duração Total')
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: horasController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Horas', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: minutosController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Minutos', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      else if (modoTempo == 'Início e Fim')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (time != null) setModalState(() => horaInicio = time);
                                },
                                icon: const Icon(Icons.access_time),
                                label: Text(horaInicio == null ? 'Início' : horaInicio!.format(context)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F0F0F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (time != null) setModalState(() => horaFim = time);
                                },
                                icon: const Icon(Icons.access_time_filled),
                                label: Text(horaFim == null ? 'Fim' : horaFim!.format(context)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F0F0F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.shade800),
                      const SizedBox(height: 16),

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

                      DropdownButtonFormField<String>(
                        value: tipoSelecionado,
                        dropdownColor: const Color(0xFF2D2D2D),
                        validator: (value) => (value == null || value.isEmpty) ? 'Selecione um tipo' : null,
                        decoration: InputDecoration(labelText: 'Tipo de estudo *', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: _tiposDeEstudo.map((String tipo) {
                          return DropdownMenuItem<String>(value: tipo, child: Text(tipo, style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (String? novoValor) {
                          setModalState(() {
                            tipoSelecionado = novoValor;
                            if (!mostrarCamposDeQuestao) {
                              totalQuestoesController.clear();
                              acertosController.clear();
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
                                controller: totalQuestoesController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: 'Total Questões', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: acertosController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && totalQuestoesController.text.isNotEmpty) {
                                    int? acertos = int.tryParse(value);
                                    int? total = int.tryParse(totalQuestoesController.text);
                                    if (acertos != null && total != null && acertos > total) return 'Acertos > Total';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(labelText: 'Acertos', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: obsController,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: 'Observações (Opcional)', filled: true, fillColor: const Color(0xFF0F0F0F), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            
                            int duracaoSegundosFinal = 0;
                            
                            if (modoTempo == 'Duração Total') {
                              int h = int.tryParse(horasController.text) ?? 0;
                              int m = int.tryParse(minutosController.text) ?? 0;
                              duracaoSegundosFinal = (h * 3600) + (m * 60);
                            } else if (modoTempo == 'Início e Fim') {
                              if (horaInicio != null && horaFim != null) {
                                int startMin = horaInicio!.hour * 60 + horaInicio!.minute;
                                int endMin = horaFim!.hour * 60 + horaFim!.minute;
                                if (endMin < startMin) endMin += 24 * 60; 
                                duracaoSegundosFinal = (endMin - startMin) * 60;
                              }
                            } else if (modoTempo == 'Sem tempo (Só questões)') {
                              duracaoSegundosFinal = 0;
                            }

                            // CODE REVIEW: Bloqueio contra sessões inválidas (0 segundos)
                            if (modoTempo != 'Sem tempo (Só questões)' && duracaoSegundosFinal <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Insira um tempo válido ou escolha "Sem tempo".', style: TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: Color(0xFFE57373),
                                ),
                              );
                              return; // Interrompe o processo de salvar
                            }

                            final novaSessao = SessaoEstudo(
                              materia: materiaController.text,
                              assunto: assuntoController.text, 
                              tipoEstudo: tipoSelecionado!,
                              observacoes: obsController.text,
                              duracaoSegundos: duracaoSegundosFinal,
                              data: dataEscolhida, 
                              totalQuestoes: int.tryParse(totalQuestoesController.text),
                              acertos: int.tryParse(acertosController.text),
                            );

                            final prefs = await SharedPreferences.getInstance();
                            List<String> sessoesSalvas = prefs.getStringList('sessoes_estudo') ?? [];
                            sessoesSalvas.add(jsonEncode(novaSessao.toJson()));
                            await prefs.setStringList('sessoes_estudo', sessoesSalvas);

                            if (context.mounted) {
                              Navigator.pop(context);
                              _atualizarDados(); 
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sessão adicionada com sucesso!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  backgroundColor: Color(0xFF4DA6FF),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
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
          },
        );
      },
    ).whenComplete(() {
      // CODE REVIEW: Limpeza de memória garantida ao fechar o modal
      materiaController.dispose();
      assuntoController.dispose();
      obsController.dispose();
      totalQuestoesController.dispose();
      acertosController.dispose();
      horasController.dispose();
      minutosController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    String tituloAppBar;
    if (_indiceAtual == 0) {
      tituloAppBar = 'Foco';
    } else if (_indiceAtual == 1) {
      tituloAppBar = 'Meu Histórico';
    } else {
      tituloAppBar = 'Desempenho'; 
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF1C1C1C),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DA6FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF4DA6FF), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Menu Tático',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.add_task_rounded, color: Colors.white),
              title: const Text('Adicionar registo manual', style: TextStyle(color: Colors.white, fontSize: 16)),
              subtitle: const Text('Inserir sessão passada', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context); 
                _abrirPainelAdicionarManual();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.flag_rounded, color: Color(0xFFE57373)), 
              title: const Text('Modo Prova', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: const Text('Simulador sem pausas', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaModoProva()),
                ).then((_) => _atualizarDados()); 
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(color: Color(0xFF2D2D2D)),
            ),
            
            ListTile(
              leading: const Icon(Icons.file_upload_outlined, color: Colors.white),
              title: const Text('Exportar Backup', style: TextStyle(color: Colors.white, fontSize: 16)),
              subtitle: const Text('Guardar dados noutro local', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _exportarBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined, color: Colors.white),
              title: const Text('Importar Backup', style: TextStyle(color: Colors.white, fontSize: 16)),
              subtitle: const Text('Restaurar código guardado', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _abrirPainelImportarBackup();
              },
            ),

            const Spacer(),
            const Divider(color: Color(0xFF2D2D2D)),
            
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              title: const Text('Apagar todos os dados', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _confirmarExclusaoTotal();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
        title: Text(
          tituloAppBar,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Offstage(
            offstage: _indiceAtual != 0,
            child: const TelaCronometro(),
          ),
          if (_indiceAtual == 1) 
            TelaHistorico(key: _chaveAbas), 
          if (_indiceAtual == 2)
            TelaDesempenho(key: _chaveAbas), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1C),
        currentIndex: _indiceAtual,
        selectedItemColor: const Color(0xFF4DA6FF),
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() {
            _indiceAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_rounded),
            label: 'Cronómetro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats_rounded),
            label: 'Desempenho',
          ),
        ],
      ),
    );
  }
}