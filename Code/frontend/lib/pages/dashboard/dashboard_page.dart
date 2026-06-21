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
  static const Color secondary = Color(0xFF3B82F6);
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
  int?
      _usuarioId; // Mudado para opcional para evitar vazamento silencioso com ID=1

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
    if (_usuarioId != null) {
      await _carregarCategorias();
      await _carregarTransacoes();
      await _carregarGastosPorCategoria();
      _calcularResumoMensal();
    }
  }

  Future<void> _carregarUsuario() async {
    final id = await _apiService.getUsuarioId();
    if (id == null) {
      // CORREÇÃO: Método correto do Flutter para deslogar e limpar a pilha
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usuarioId = id;
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
      _emailUsuario = prefs.getString('email_usuario') ?? 'usuario@email.com';
    });
  }

  Future<void> _carregarCategorias() async {
    try {
      final dados = await _apiService.listarCategorias(_usuarioId!);
      setState(() => _todasCategorias = dados);
    } catch (e) {
      print('Erro ao carregar categorias: $e');
    }
  }

  Future<void> _carregarTransacoes() async {
    try {
      final dados = await _apiService.obterTransacoes(_usuarioId!);
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
      final dados = await _apiService.obterGastosPorCategoria(_usuarioId!);
      setState(() => _gastosPorCategoria = dados);
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

  // --- MATEMÁTICA CORRIGIDA: SALDO REAL DAS ÚLTIMAS TRANSAÇÕES ---
  List<FlSpot> _gerarSpotsDoGrafico() {
    if (_transacoes.isEmpty) {
      return [const FlSpot(0, 0.0), const FlSpot(1, 0.0)];
    }

    // 1. Coloca na ordem do tempo (A transação mais antiga fica primeiro)
    final transacoesCronologicas = _transacoes.reversed.toList();
    List<double> historicoSaldos = [];
    double saldoAcumulado = 0.0;

    // 2. Simula a conta bancária somando e subtraindo tudo desde a criação da conta
    for (var t in transacoesCronologicas) {
      final double valor = double.tryParse(t['valor'].toString()) ?? 0.0;
      if (t['tipo'] == 'despesa') {
        saldoAcumulado -= valor;
      } else {
        saldoAcumulado += valor;
      }
      historicoSaldos.add(saldoAcumulado);
    }

    // 3. Corta para pegar só os últimos 7 movimentos, assim não esmaga no celular
    int limite = 7;
    int startIndex =
        historicoSaldos.length > limite ? historicoSaldos.length - limite : 0;
    List<double> ultimosSaldos = historicoSaldos.sublist(startIndex);

    List<FlSpot> spots = [];
    for (int i = 0; i < ultimosSaldos.length; i++) {
      spots.add(FlSpot(i.toDouble(), ultimosSaldos[i]));
    }
    return spots;
  }

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
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Editar Registro',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: valorCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Valor', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: tipoSelecionado,
                          items: const [
                            DropdownMenuItem(
                                value: 'receita', child: Text('Receita')),
                            DropdownMenuItem(
                                value: 'despesa', child: Text('Despesa')),
                          ],
                          onChanged: (val) {
                            setStateDialog(() => tipoSelecionado = val!);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: categoriaSelecionada,
                          items: listaDisponivel
                              .map<DropdownMenuItem<String>>((cat) {
                            return DropdownMenuItem<String>(
                                value: cat['nome'],
                                child: Text(cat['nome'],
                                    overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (val) =>
                              setStateDialog(() => categoriaSelecionada = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white),
                        onPressed: () async {
                          final novaTransacao = TransactionModel(
                            descricao: descCtrl.text.trim(),
                            valor: double.tryParse(valorCtrl.text) ?? 0.0,
                            tipo: tipoSelecionado,
                            categoria: categoriaSelecionada,
                            dataTransacao: DateTime.now(),
                          );
                          await _apiService.editarTransacao(
                              t['id'], novaTransacao);
                          Navigator.pop(context);
                          _carregarDadosIniciais();
                        },
                        child: const Text('Confirmar'),
                      )
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final spots = _gerarSpotsDoGrafico();

    // --- LÓGICA DE ESPAÇAMENTO PARA O GRÁFICO CABER NO CELULAR ---
    double maxSpotY = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)
        : 1000.0;
    double minSpotY = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b)
        : 0.0;

    double paddingY = (maxSpotY - minSpotY) * 0.2;
    if (paddingY == 0) paddingY = 100.0;

    final maxYScale = maxSpotY + paddingY;
    final minYScale =
        minSpotY - paddingY < 0 && minSpotY >= 0 ? 0.0 : minSpotY - paddingY;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🐧', style: TextStyle(fontSize: 22)), // Ícone do pinguim
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
                child: Text('🐧', style: TextStyle(fontSize: 32)),
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
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('Configurações',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/configuracoes'),
            ),
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                              Text('Seu ecossistema ártico está atualizado.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.85))),
                            ],
                          ),
                          const Text('🐧', style: TextStyle(fontSize: 40)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _buildMetricCard(
                                'Saldo Atual', _totalBalance, Colors.blue)),
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

                    // O SEU GRÁFICO EXATO, COM AJUSTES DE ESPAÇO Y e TOOLTIPS
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(
                              color: Colors.grey.shade100, width: 1.5)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Evolução Patrimonial',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: AppColors.primary)),
                                Icon(Icons.auto_graph, color: AppColors.accent),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 180,
                              child: LineChart(LineChartData(
                                  // Adicionado Tooltips Fantásticos ao clicar!
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (touchedSpot) =>
                                          AppColors.primary,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots
                                            .map((spot) => LineTooltipItem(
                                                  currencyFormat.format(spot.y),
                                                  const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ))
                                            .toList();
                                      },
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: spots.isNotEmpty
                                      ? (spots.length - 1).toDouble()
                                      : 7,
                                  minY:
                                      minYScale, // Ajuste para não esmagar a linha
                                  maxY:
                                      maxYScale, // Ajuste para não encostar no teto
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData,
                                                index) =>
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
                                              AppColors.primary
                                                  .withOpacity(0.2),
                                              AppColors.primary.withOpacity(0.0)
                                            ]),
                                      ),
                                    )
                                  ])),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SEÇÃO OPCIONAL QUE FICA A SEU CRITÉRIO: Insight Financeiro
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _totalBalance >= 0
                            ? AppColors.success.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: _totalBalance >= 0
                                ? AppColors.success.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _totalBalance >= 0
                                  ? Icons.emoji_events
                                  : Icons.warning_amber_rounded,
                              color: _totalBalance >= 0
                                  ? AppColors.success
                                  : Colors.red,
                              size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Insights Árticos',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: _totalBalance >= 0
                                            ? AppColors.success
                                            : Colors.red)),
                                const SizedBox(height: 4),
                                Text(
                                  _totalBalance >= 0
                                      ? 'Excelente! Suas receitas superam as despesas neste mês. Continue assim! 🐧'
                                      : 'Atenção! Suas despesas estão maiores que suas receitas. Hora de economizar.',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textDark),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_gastosPorCategoria.isNotEmpty)
                      ..._buildPieChartSection(),
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
                          TransactionPage(usuarioId: _usuarioId ?? 1)))
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
      sections.add(PieChartSectionData(
          value: valor,
          title: '${percent.toStringAsFixed(1)}%',
          color: _categoryColors[i % _categoryColors.length],
          radius: 45,
          titleStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)));
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
                    return Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color:
                                    _categoryColors[i % _categoryColors.length],
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(item['categoria'] ?? 'Outros',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis)),
                        Text(
                            NumberFormat.compactCurrency(
                                    locale: 'pt_BR', symbol: 'R\$')
                                .format(valor),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
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
