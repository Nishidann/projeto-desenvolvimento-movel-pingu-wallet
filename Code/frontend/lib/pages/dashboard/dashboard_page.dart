// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../transaction/transaction_page.dart';
import '../../services/api_service.dart';

// O Enum fica fora da classe para ser acessível globalmente
enum ChartPeriod { week, month, threeMonths, year }

class AppColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFFFF7A00);
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
  int? usuarioId;

  List<dynamic> _transacoes = [];
  bool _isLoading = true;
  bool _mostrarTodasAsTransacoes = false;
  String _nomeUsuario = 'Usuário';

  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;

  ChartPeriod _selectedPeriod = ChartPeriod.month;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    final idDoToken = await _apiService.getUsuarioId();

    if (idDoToken != null) {
      setState(() => usuarioId = idDoToken);
      await _carregarUsuario();
      await _carregarTransacoes();
      _calcularResumoGeral();
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Daniel';
    });
  }

  Future<void> _carregarTransacoes() async {
    if (usuarioId == null) return;
    try {
      final dados = await _apiService.obterTransacoes(usuarioId!);
      setState(() {
        _transacoes = List<dynamic>.from(dados);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erro ao carregar transações: $e');
    }
  }

  void _calcularResumoGeral() {
    double inc = 0.0;
    double exp = 0.0;
    for (var t in _transacoes) {
      final valor = double.tryParse(t['valor']?.toString() ?? '0') ?? 0.0;
      final tipo = t['tipo']?.toString().toLowerCase() ?? '';
      if (tipo == 'receita') inc += valor;
      else if (tipo == 'despesa') exp += valor;
    }
    setState(() {
      _monthlyIncome = inc;
      _monthlyExpenses = exp;
      _totalBalance = inc - exp;
    });
  }

  List<FlSpot> _gerarSpotsDoGrafico() {
    if (_transacoes.isEmpty) return [const FlSpot(0, 0)];

    // 1. Ordenar transações cronologicamente
    final ordenadas = List.from(_transacoes);
    ordenadas.sort((a, b) {
      final dA = DateTime.tryParse(a['dataTransacao']?.toString() ?? '') ?? DateTime.now();
      final dB = DateTime.tryParse(b['dataTransacao']?.toString() ?? '') ?? DateTime.now();
      return dA.compareTo(dB);
    });

    DateTime now = DateTime.now();
    DateTime inicio;
    switch (_selectedPeriod) {
      case ChartPeriod.week: inicio = now.subtract(const Duration(days: 7)); break;
      case ChartPeriod.month: inicio = now.subtract(const Duration(days: 30)); break;
      case ChartPeriod.threeMonths: inicio = now.subtract(const Duration(days: 90)); break;
      case ChartPeriod.year: inicio = DateTime(now.year - 1, now.month, now.day); break;
    }

    double saldoAcumulado = 0;
    Map<String, double> saldoPorDia = {};

    // 2. Lógica de Agrupamento por Dia
    for (var t in ordenadas) {
      final dataFull = DateTime.tryParse(t['dataTransacao']?.toString() ?? '') ?? DateTime.now();
      final valor = double.tryParse(t['valor']?.toString() ?? '0') ?? 0.0;
      final tipo = t['tipo']?.toString().toLowerCase() ?? '';
      
      // Atualiza saldo histórico independente do filtro
      if (tipo == 'receita') saldoAcumulado += valor;
      else saldoAcumulado -= valor;

      // Se a transação estiver dentro do filtro, salva no mapa
      if (dataFull.isAfter(inicio) || dataFull.isAtSameMomentAs(inicio)) {
        final diaChave = DateFormat('yyyy-MM-dd').format(dataFull);
        saldoPorDia[diaChave] = saldoAcumulado; // Salva o saldo final daquele dia
      }
    }

    List<FlSpot> spots = [];
    
    // Se não houver dados no período, inicia com saldo 0 no dia "inicio"
    if (saldoPorDia.isEmpty) {
      spots.add(FlSpot(inicio.millisecondsSinceEpoch.toDouble(), 0));
    } else {
      // Converte o mapa em spots
      saldoPorDia.forEach((dataStr, saldo) {
        final dataObj = DateTime.parse(dataStr);
        spots.add(FlSpot(dataObj.millisecondsSinceEpoch.toDouble(), saldo));
      });
    }

    // 3. Garante que o gráfico termina no dia de hoje
    if (spots.isNotEmpty) {
      spots.add(FlSpot(now.millisecondsSinceEpoch.toDouble(), saldoAcumulado));
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final spots = _gerarSpotsDoGrafico();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pingu Wallet', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _carregarDadosIniciais,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                _buildMetricsGrid(currencyFormat),
                const SizedBox(height: 24),
                _buildChartContainer(spots),
                const SizedBox(height: 24),
                _buildTransactionsList(currencyFormat),
              ],
            ),
          ),
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () {
          if (usuarioId != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionPage(usuarioId: usuarioId!))).then((_) => _carregarDadosIniciais());
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Olá, $_nomeUsuario! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const Text('Seus gastos estão sob controle.', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildMetricsGrid(NumberFormat fmt) {
    return Row(
      children: [
        _miniCard('Saldo', fmt.format(_totalBalance), AppColors.primary),
        const SizedBox(width: 10),
        _miniCard('Entradas', fmt.format(_monthlyIncome), AppColors.success),
        const SizedBox(width: 10),
        _miniCard('Saídas', fmt.format(_monthlyExpenses), Colors.redAccent),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color))),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(List<FlSpot> spots) {
    double diffX = spots.last.x - spots.first.x;
    double intervalX = diffX > 0 ? diffX / 3 : 86400000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          SegmentedButton<ChartPeriod>(
            segments: const [
              ButtonSegment(value: ChartPeriod.week, label: Text('7D')),
              ButtonSegment(value: ChartPeriod.month, label: Text('30D')),
              ButtonSegment(value: ChartPeriod.threeMonths, label: Text('3M')),
              ButtonSegment(value: ChartPeriod.year, label: Text('1A')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (val) => setState(() => _selectedPeriod = val.first),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: intervalX,
                      getTitlesWidget: (v, m) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('dd/MM').format(DateTime.fromMillisecondsSinceEpoch(v.toInt())), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(NumberFormat fmt) {
    // Aqui aplicamos o limite de 5 itens que você pediu
    final lista = _mostrarTodasAsTransacoes ? _transacoes : _transacoes.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transações Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_transacoes.isEmpty)
          const Center(child: Text('Nenhuma transação registrada.'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = lista[i];
              final isDesp = t['tipo']?.toString().toLowerCase() == 'despesa';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['descricao']?.toString() ?? 'Sem descrição', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(t['categoria']?.toString() ?? 'Geral', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      '${isDesp ? '-' : '+'} ${fmt.format(double.tryParse(t['valor']?.toString() ?? '0') ?? 0.0)}',
                      style: TextStyle(color: isDesp ? Colors.redAccent : AppColors.success, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              );
            },
          ),
        if (_transacoes.length > 5)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _mostrarTodasAsTransacoes = !_mostrarTodasAsTransacoes),
              child: Text(_mostrarTodasAsTransacoes ? "Ver menos" : "Ver tudo (${_transacoes.length})"),
            ),
          ),
      ],
    );
  }
}