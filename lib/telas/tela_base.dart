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
      Future.delayed(const Duration(milliseconds: 300), () {
        codigoController.dispose();
      });
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
  // ADICIONAR MANUALMENTE (ABERTURA DO PAINEL)
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return _PainelAdicionarManual(
          listaMaterias: listaMaterias,
          listaAssuntos: listaAssuntos,
          aoSalvar: _atualizarDados,
        );
      },
    );
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

// =============================================================================
// O WIDGET ISOLADO PARA ADICIONAR SESSÃO MANUAL
// =============================================================================
class _PainelAdicionarManual extends StatefulWidget {
  final List<String> listaMaterias;
  final List<String> listaAssuntos;
  final VoidCallback aoSalvar;

  const _PainelAdicionarManual({
    required this.listaMaterias,
    required this.listaAssuntos,
    required this.aoSalvar,
  });

  @override
  State<_PainelAdicionarManual> createState() => _PainelAdicionarManualState();
}

class _PainelAdicionarManualState extends State<_PainelAdicionarManual> {
  final _formKey = GlobalKey<FormState>();
  
  String _materiaCapturada = '';
  String _assuntoCapturado = '';
  
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
        materia: _materiaCapturada, 
        assunto: _assuntoCapturado, 
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
                    // REGRA DE UX: Se for sem tempo, tranca o tipo em Questões
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
                textEditingController: TextEditingController(),
                focusNode: FocusNode(),
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
                      _materiaCapturada = value; 
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
                textEditingController: TextEditingController(),
                focusNode: FocusNode(),
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
                    validator: (value) {
                      _assuntoCapturado = value ?? ''; 
                      return null;
                    },
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
                    // Se o dropdown for bloqueado, ele fica acinzentado automaticamente pelo Flutter, mas garantimos o estilo
                    child: Text(tipo, style: const TextStyle(color: Colors.white))
                  );
                }).toList(),
                // REGRA DE UX: Desativa (bloqueia) a alteração do Dropdown passando null para o onChanged
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