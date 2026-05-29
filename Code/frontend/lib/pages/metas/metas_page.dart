// ignore_for_file: deprecated_member_use, avoid_print
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _metas = [];
  bool _isLoading = true;
  int _usuarioId = 1;
  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'usuario@email.com';

  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;

  // Mapa de ícones disponíveis para as metas financeiras
  static const Map<String, IconData> goalIcons = {
    'savings': Icons.savings,
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'home': Icons.home,
    'laptop': Icons.laptop,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
    'celebration': Icons.celebration,
  };

  @override
  void initState() {
    super.initState();
    _carregarDadosReal();
  }

  Future<void> _carregarDadosReal() async {
    setState(() => _isLoading = true);
    final id = await _apiService.getUsuarioId();
    if (id != null) _usuarioId = id;

    final prefs = await SharedPreferences.getInstance();
    final dados = await _apiService.obterMetas(_usuarioId);

    setState(() {
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
      _emailUsuario = prefs.getString('email_usuario') ?? 'usuario@email.com';
      _metas = dados;
      _isLoading = false;
    });
  }

  // =========================================================================
  // DIÁLOGO PREMIUM: CRIAR OU EDITAR META (UNIFICADO NO PADRÃO DE CATEGORIAS)
  // =========================================================================
  void _mostrarDialogMeta({Map<String, dynamic>? meta}) {
    final isEdicao = meta != null;
    final tituloController =
        TextEditingController(text: isEdicao ? meta['titulo'] : '');
    final alvoController =
        TextEditingController(text: isEdicao ? meta['alvo'].toString() : '');
    final atualController =
        TextEditingController(text: isEdicao ? meta['atual'].toString() : '');
    String iconeSelecionado =
        isEdicao ? (meta['icone'] ?? 'savings') : 'savings';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)), // Token de 28px
          backgroundColor: _surface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho Premium idêntico ao estilo criado pelo seu colega
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isEdicao ? Icons.edit_outlined : Icons.star,
                          color: _accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdicao ? 'Editar Objetivo' : 'Novo Objetivo',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _primary),
                        ),
                        Text(
                          isEdicao
                              ? 'Atualize seus alvos árticos'
                              : 'Guarde dinheiro com foco',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Inputs Customizados e Validados
                TextField(
                  controller: tituloController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Objetivo',
                    prefixIcon:
                        const Icon(Icons.flag_outlined, color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: alvoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valor Alvo (R\$)',
                    prefixIcon: const Icon(Icons.attach_money, color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: atualController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valor Inicial Guardado (R\$)',
                    prefixIcon: const Icon(Icons.ads_click, color: _primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Escolha um ícone temático',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        fontSize: 14)),
                const SizedBox(height: 12),

                // Grade Seletora de Ícones dinâmica
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: goalIcons.entries.map((entry) {
                    final isSelected = iconeSelecionado == entry.key;
                    return GestureDetector(
                      onTap: () =>
                          setStateDialog(() => iconeSelecionado = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? _accent : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  isSelected ? _accent : Colors.grey.shade200,
                              width: isSelected ? 2 : 1),
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Botões Ação Alinhados
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (tituloController.text.trim().isEmpty ||
                              alvoController.text.trim().isEmpty) return;
                          Navigator.pop(context);

                          if (!isEdicao) {
                            // Operação de Inserção Real
                            await _apiService.cadastrarMeta(
                              usuarioId: _usuarioId,
                              titulo: tituloController.text.trim(),
                              alvo: double.tryParse(alvoController.text) ?? 0.0,
                              atual:
                                  double.tryParse(atualController.text) ?? 0.0,
                              icone: iconeSelecionado,
                            );
                          } else {
                            // Operação de Edição Real Baseada no ID
                            await _apiService.editarMeta(
                              meta['id'],
                              tituloController.text.trim(),
                              double.tryParse(alvoController.text) ?? 0.0,
                              double.tryParse(atualController.text) ?? 0.0,
                              iconeSelecionado,
                            );
                          }
                          _carregarDadosReal();
                        },
                        child: Text(isEdicao ? 'Salvar' : 'Criar Meta',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DIÁLOGO: CONFIRMAÇÃO DE EXCLUSÃO DE META
  // =========================================================================
  void _confirmarDeletarMeta(int id, String titulo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Remover Objetivo',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tem certeza que deseja apagar "$titulo"?\nEsse processo não poderá ser revertido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _apiService.deletarMeta(
                            id); // Chamada real ao Banco via Express
                        _carregarDadosReal();
                      },
                      child: const Text('Deletar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Metas e Objetivos',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _carregarDadosReal),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: _primary),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: _primary, size: 36),
              ),
              accountName: Text(_nomeUsuario),
              accountEmail: Text(_emailUsuario),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: _primary),
              title: const Text('Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: _primary),
              title: const Text('Relatório Mensal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/relatorio'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: _primary),
              title: const Text('Histórico',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/historico'),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: _primary),
              title: const Text('Categorias',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/categorias'),
            ),
            ListTile(
              leading: const Icon(Icons.ads_click, color: _primary),
              title: const Text('Metas e Objetivos',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedTileColor: _primary.withOpacity(0.08),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sair da Conta',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _metas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ads_click,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Nenhum objetivo traçado ainda.',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: _metas.length,
                  itemBuilder: (context, index) {
                    final m = _metas[index];
                    final alvo = double.tryParse(m['alvo'].toString()) ?? 1.0;
                    final atual = double.tryParse(m['atual'].toString()) ?? 0.0;
                    double percent = atual / alvo;
                    if (percent > 1.0) percent = 1.0;

                    final iconData = goalIcons[m['icone']] ?? Icons.savings;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(28),
                        border: const Border(
                            left: BorderSide(color: _accent, width: 4.5)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: _accent.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Icon(iconData,
                                          color: _accent, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(m['titulo'] ?? 'Objetivo',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: _primary)),
                                  ],
                                ),
                                // Container de ações integradas (Porcentagem + Lápis + Lixeira)
                                Row(
                                  children: [
                                    Text(
                                        '${(percent * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: _accent,
                                            fontSize: 14)),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.blue, size: 18),
                                      onPressed: () => _mostrarDialogMeta(
                                          meta:
                                              m), // Passa a meta para virar EDIÇÃO
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                      onPressed: () => _confirmarDeletarMeta(
                                          m['id'], m['titulo']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                                value: percent,
                                color: _primary,
                                backgroundColor: Colors.grey.shade100,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(4)),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Acumulado: ${currencyFormat.format(atual)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500)),
                                Text('Meta: ${currencyFormat.format(alvo)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _primary)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        onPressed: () => _mostrarDialogMeta(), // Abre limpo para CRIAÇÃO
        icon: const Icon(Icons.add),
        label: const Text('Novo Objetivo',
            style: TextStyle(fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
