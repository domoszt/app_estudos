// lib/telas/tela_base.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'tela_cronometro.dart';
import 'tela_historico.dart';
import 'tela_desempenho.dart';
import 'tela_modo_prova.dart';
import 'painel_adicionar_manual.dart'; // Importação do novo widget!

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
        return PainelAdicionarManual( // Chamada ao widget isolado
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DA6FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/icones/icone.png',
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vanguard',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
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