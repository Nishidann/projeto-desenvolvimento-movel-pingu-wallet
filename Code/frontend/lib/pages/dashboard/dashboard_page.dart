// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../transaction/transaction_page.dart';
import '../../services/api_service.dart';
import '../../models/transaction_model.dart';

class AppColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1E3A8A); // Azul Ártico
  static const Color secondary = Color(0xFF3B82F6); // Azul Brilhante
  static const Color accent = Color(0xFFFF7A00); // Laranja Pinguim
  static const Color success = Color(0xFF10B981);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFFFFFFFF);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  int _usuarioId = 1;

  List<dynamic> _transacoes = [];
  List<dynamic> _gastosPorCategoria = [];
  List<dynamic> _todasCategorias = [];
  bool _isLoading = true;
  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'usuario@email.com';

  static const List<Color> _categoryColors = [
    Color(0xFF1E3A8A),
    Color(0xFFFF7A00),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    await _carregarUsuario();
    await _carregarCategorias();
    await _carregarTransacoes();
    await _carregarGastosPorCategoria();
    _calcularResumoMensal();
  }

  Future<void> _carregarUsuario() async {
    final id = await _apiService.getUsuarioId();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (id != null) _usuarioId = id;
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
      _emailUsuario = prefs.getString('email_usuario') ?? 'usuario@email.com';
    });
  }

  Future<void> _carregarCategorias() async {
    try {
      final dados = await _apiService.listarCategorias(_usuarioId);
      setState(() {
        _todasCategorias = dados;
      });
    } catch (e) {
      print('Erro ao carregar categorias: $e');
    }
  }

  Future<void> _carregarTransacoes() async {
    try {
      final dados = await _apiService.obterTransacoes(_usuarioId);
      setState(() {
        _transacoes = dados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erro ao carregar transações: $e');
    }
  }

  Future<void> _carregarGastosPorCategoria() async {
    try {
      final dados = await _apiService.obterGastosPorCategoria(_usuarioId);
      setState(() {
        _gastosPorCategoria = dados;
      });
    } catch (e) {
      print('Erro ao carregar gastos por categoria: $e');
    }
  }

  void _calcularResumoMensal() {
    double income = 0.0;
    double expenses = 0.0;

    for (var t in _transacoes) {
      final valor = double.tryParse(t['valor'].toString()) ?? 0.0;
      if (t['tipo'] == 'receita') {
        income += valor;
      } else if (t['tipo'] == 'despesa') {
        expenses += valor;
      }
    }

    setState(() {
      _monthlyIncome = income;
      _monthlyExpenses = expenses;
      _totalBalance = income - expenses;
    });
  }

  List<FlSpot> _gerarSpotsDoGrafico() {
    if (_transacoes.isEmpty) {
      return [const FlSpot(0, 0.0), const FlSpot(1, 0.0)];
    }

    List<FlSpot> spots = [];
    double saldoAcumulado = 0.0;
    final transacoesInvertidas = _transacoes.reversed.toList();

    for (int i = 0; i < transacoesInvertidas.length && i < 7; i++) {
      final t = transacoesInvertidas[i];
      final double valor = double.tryParse(t['valor'].toString()) ?? 0.0;

      if (t['tipo'] == 'despesa') {
        saldoAcumulado -= valor;
      } else {
        saldoAcumulado += valor;
      }
      spots.add(FlSpot(i.toDouble(), saldoAcumulado));
    }
    return spots;
  }

  // Janela de Edição corrigida e alinhada com o design premium
  void _mostrarDialogEditarTransacao(Map<String, dynamic> t) {
    final descCtrl = TextEditingController(text: t['descricao']);
    final valorCtrl = TextEditingController(text: t['valor'].toString());
    String tipoSelecionado = t['tipo'] ?? 'despesa';

    List<dynamic> categoriasFiltradas =
        _todasCategorias.where((c) => c['tipo'] == tipoSelecionado).toList();
    String categoriaSelecionada =
        categoriasFiltradas.any((c) => c['nome'] == t['categoria'])
            ? t['categoria']
            : (categoriasFiltradas.isNotEmpty
                ? categoriasFiltradas.first['nome']
                : 'Outros');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          List<dynamic> listaDisponivel = _todasCategorias
              .where((c) => c['tipo'] == tipoSelecionado)
              .toList();
          if (!listaDisponivel.any((c) => c['nome'] == categoriaSelecionada)) {
            categoriaSelecionada = listaDisponivel.isNotEmpty
                ? listaDisponivel.first['nome']
                : 'Outros';
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_note,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Editar Registro',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          Text('Ajuste os valores do lançamento',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      prefixIcon: const Icon(Icons.description_outlined,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Valor (R\$)',
                      prefixIcon: const Icon(Icons.calculate_outlined,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: tipoSelecionado,
                          decoration: InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(
                                value: 'receita',
                                child: Text('Receita',
                                    style: TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold))),
                            DropdownMenuItem(
                                value: 'despesa',
                                child: Text('Despesa',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            setStateDialog(() {
                              tipoSelecionado = val!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: categoriaSelecionada,
                          decoration: InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          items: listaDisponivel
                              .map<DropdownMenuItem<String>>((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['nome'],
                              child: Text(cat['nome'],
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setStateDialog(() => categoriaSelecionada = val!),
                        ),
                      ),
                    ],
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
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text('Cancelar',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (descCtrl.text.isEmpty || valorCtrl.text.isEmpty)
                              return;
                            Navigator.pop(context);

                            DateTime dataTratada;
                            if (t['data_transacao'] != null) {
                              dataTratada =
                                  DateTime.parse(t['data_transacao'].toString())
                                      .toLocal();
                            } else {
                              dataTratada = DateTime.now();
                            }

                            // CORREÇÃO: Removido o parâmetro inexistente 'type:'
                            final novaTransacao = TransactionModel(
                              descricao: descCtrl.text.trim(),
                              valor: double.tryParse(valorCtrl.text) ?? 0.0,
                              tipo: tipoSelecionado,
                              categoria: categoriaSelecionada,
                              dataTransacao: dataTratada,
                            );

                            await _apiService.editarTransacao(
                                t['id'], novaTransacao);
                            _carregarDadosIniciais();
                          },
                          child: const Text('Confirmar',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmarDeletarTransacao(int id, String descricao) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Excluir Lançamento?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Deseja mesmo apagar "$descricao"?',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Voltar'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _apiService.deletarTransacao(id);
                        _carregarDadosIniciais();
                      },
                      child: const Text('Excluir'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcoesTransacao(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(t['descricao'] ?? 'Opções da Transação',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Editar Registro'),
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogEditarTransacao(t);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir Registro'),
              onTap: () {
                Navigator.pop(context);
                _confirmarDeletarTransacao(
                    t['id'], t['descricao'] ?? 'Transação');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final spots = _gerarSpotsDoGrafico();

    double maxSpotY = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)
        : 1000.0;
    if (maxSpotY <= 0) maxSpotY = 1000.0;
    final maxYScale = maxSpotY * 1.2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.waves, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Pingu Wallet',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.textLight)),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primary, size: 36),
              ),
              accountName: Text(_nomeUsuario),
              accountEmail: Text(_emailUsuario),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppColors.primary),
              title: const Text('Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedTileColor: AppColors.primary.withOpacity(0.08),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.primary),
              title: const Text('Relatório Mensal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/relatorio'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: const Text('Histórico',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/historico'),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: AppColors.primary),
              title: const Text('Categorias',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/categorias'),
            ),
            ListTile(
              leading: const Icon(Icons.ads_click, color: AppColors.primary),
              title: const Text('Metas e Objetivos',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushReplacementNamed(context, '/metas'),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('Configurações',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/configuracoes'),
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
      body: RefreshIndicator(
        onRefresh: _carregarDadosIniciais,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá, $_nomeUsuario! 👋',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Seu ecossistema financeiro está atualizado.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.85))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.icecream,
                          color: AppColors.accent, size: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _buildMetricCard(
                          'Saldo Total', _totalBalance, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildMetricCard(
                          'Receitas', _monthlyIncome, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildMetricCard(
                          'Despesas', _monthlyExpenses, Colors.red)),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.grey.shade100, width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Evolução Patrimonial',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.primary)),
                          Icon(Icons.trending_up,
                              color: Colors.grey.shade400, size: 20),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: spots.isNotEmpty
                                ? (spots.length - 1).toDouble()
                                : 7,
                            minY: spots.isNotEmpty
                                ? spots
                                        .map((s) => s.y)
                                        .reduce((a, b) => a < b ? a : b) *
                                    0.9
                                : 0.0,
                            maxY: maxYScale,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: AppColors.primary,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                              radius: 5,
                                              color: Colors.white,
                                              strokeWidth: 3.5,
                                              strokeColor: AppColors.primary),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary.withOpacity(0.2),
                                        AppColors.primary.withOpacity(0.0)
                                      ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_gastosPorCategoria.isNotEmpty) ..._buildPieChartSection(),
              const SizedBox(height: 24),
              const Text('Transações Recentes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text(
                  'Pressione e segure um item para Editá-lo ou Excluí-lo',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transacoes.isEmpty
                      ? const Center(
                          child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Nenhum registro encontrado.')))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount:
                              _transacoes.length > 5 ? 5 : _transacoes.length,
                          itemBuilder: (context, index) {
                            final t = _transacoes[index];
                            final isDespesa = t['tipo'] == 'despesa';
                            final valor =
                                double.tryParse(t['valor'].toString()) ?? 0.0;

                            return InkWell(
                              onLongPress: () => _mostrarOpcoesTransacao(t),
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                      color: Colors.grey.shade100, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isDespesa
                                              ? Colors.red.shade50
                                              : AppColors.success
                                                  .withOpacity(0.1),
                                          child: Icon(
                                              isDespesa
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color: isDespesa
                                                  ? Colors.red.shade400
                                                  : AppColors.success,
                                              size: 16),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                t['descricao'] ??
                                                    'Sem Descrição',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: AppColors.textDark)),
                                            Text(t['categoria'] ?? 'Geral',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${isDespesa ? '-' : '+'} ${currencyFormat.format(valor)}',
                                      // CORREÇÃO: Removido caractere inválido colado no style
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: isDespesa
                                              ? Colors.red.shade400
                                              : AppColors.success),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TransactionPage(usuarioId: _usuarioId)))
              .then((_) => _carregarDadosIniciais());
        },
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  Widget _buildMetricCard(String title, double value, Color indicatorColor) {
    final format = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: indicatorColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(format.format(value),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }

  List<Widget> _buildPieChartSection() {
    final total = _gastosPorCategoria.fold<double>(
        0.0,
        (sum, item) =>
            sum + (double.tryParse(item['total'].toString()) ?? 0.0));
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < _gastosPorCategoria.length; i++) {
      final item = _gastosPorCategoria[i];
      final valor = double.tryParse(item['total'].toString()) ?? 0.0;
      final percent = total > 0 ? (valor / total * 100) : 0.0;
      sections.add(
        PieChartSectionData(
          value: valor,
          title: '${percent.toStringAsFixed(1)}%',
          color: _categoryColors[i % _categoryColors.length],
          radius: 45,
          titleStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return [
      const Text('Distribuição de Gastos',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary)),
      const SizedBox(height: 14),
      Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.grey.shade100, width: 1.5)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                  height: 110,
                  width: 110,
                  child: PieChart(PieChartData(
                      sections: sections,
                      centerSpaceRadius: 24,
                      sectionsSpace: 2))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: List.generate(_gastosPorCategoria.length, (i) {
                    final item = _gastosPorCategoria[i];
                    final valor =
                        double.tryParse(item['total'].toString()) ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: _categoryColors[
                                      i % _categoryColors.length],
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          // CORREÇÃO: overflow limpo e corrigido sem erros de cópia
                          Expanded(
                              child: Text(item['categoria'] ?? 'Outros',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis)),
                          Text(
                              NumberFormat.compactCurrency(
                                      locale: 'pt_BR', symbol: 'R\$')
                                  .format(valor),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      )
    ];
  }
}
