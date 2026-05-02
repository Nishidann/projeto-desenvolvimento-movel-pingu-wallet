// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../transaction/transaction_page.dart';
import '../../services/api_service.dart';

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
  final int usuarioId = 1;

  List<dynamic> _transacoes = [];
  bool _isLoading = true;
  String _nomeUsuario = 'Usuário';

  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoading = true;
    });
    await _carregarUsuario();
    await _carregarTransacoes();
    _calcularResumoMensal();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Daniel';
    });
  }

  Future<void> _carregarTransacoes() async {
    try {
      final dados = await _apiService.obterTransacoes(usuarioId);
      setState(() {
        _transacoes = dados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erro ao carregar transações: $e');
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

  // Gráfico da esquerda para a direita no sentido do tempo
  List<FlSpot> _gerarSpotsDoGrafico() {
    if (_transacoes.isEmpty) {
      return [
        const FlSpot(0, 0.0),
        const FlSpot(1, 0.0),
      ];
    }

    List<FlSpot> spots = [];
    double saldoAcumulado = 0.0;

    // Inverte a lista para que a transação mais antiga fique no ponto zero
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final spots = _gerarSpotsDoGrafico();

    double maxSpotY = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)
        : 1000.0;
    // Garante que a escala não fique zerada se o saldo for menor ou igual a zero
    if (maxSpotY <= 0) {
      maxSpotY = 1000.0;
    }
    final maxYScale = maxSpotY * 1.2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pingu Wallet - Dashboard',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.textLight),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Boas-vindas
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $_nomeUsuario! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Resumo das suas finanças',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.icecream,
                        color: AppColors.accent, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seção de Cards / Métricas
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _buildCard('Saldo Total', currencyFormat.format(_totalBalance),
                    Colors.blue),
                _buildCard('Receitas', currencyFormat.format(_monthlyIncome),
                    Colors.green),
                _buildCard('Despesas', currencyFormat.format(_monthlyExpenses),
                    Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Gráfico de Evolução Patrimonial
            SizedBox(
              height: 190,
              child: Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: Colors.grey.shade100, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evolução Patrimonial',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: spots.isNotEmpty
                                ? (spots.length - 1).toDouble()
                                : 7,
                            minY: 0,
                            maxY: maxYScale,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: AppColors.primary,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.primary.withValues(alpha: 0.0),
                                    ],
                                  ),
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
            ),
            const SizedBox(height: 24),

            // Título Transações
            const Text(
              'Transações Recentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),

            // Histórico de Lançamentos
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transacoes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Nenhuma transação encontrada.'),
                        ),
                      )
                    : ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _transacoes.length,
                        itemBuilder: (context, index) {
                          final t = _transacoes[index];
                          final isDespesa = t['tipo'] == 'despesa';
                          final valor =
                              double.tryParse(t['valor'].toString()) ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isDespesa
                                          ? Colors.red.shade50
                                          : AppColors.success
                                              .withValues(alpha: 0.1),
                                      child: Icon(
                                        isDespesa
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isDespesa
                                            ? Colors.red.shade400
                                            : AppColors.success,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['descricao'] ?? 'Sem Descrição',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          t['categoria'] ?? 'Geral',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '${isDespesa ? '-' : '+'} ${currencyFormat.format(valor)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDespesa
                                        ? Colors.red.shade400
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textLight,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionPage(usuarioId: usuarioId),
            ),
          ).then((_) => _carregarDadosIniciais());
        },
        tooltip: 'Nova Transação',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCard(String title, String value, Color colorType) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colorType == Colors.blue
                    ? AppColors.primary
                    : colorType == Colors.green
                        ? AppColors.success
                        : Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
