// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../transaction/transaction_page.dart';
import '../../services/api_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
  List<dynamic> _gastosPorCategoria = [];
  bool _isLoading = true;
  bool _mostrarTodasAsTransacoes =
      false; // Controla se a lista está expandida ou minimizada
  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'pinguim@wallet.com';

  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;

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

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);

    // Busca o ID do token salvo no SharedPreferences
    final idDoToken = await _apiService.getUsuarioId();

    if (idDoToken != null) {
      setState(() {
        usuarioId = idDoToken;
      });
      // Agora que temos o ID, carregamos o resto
      await _carregarUsuario();
      await _carregarTransacoes();
      await _carregarGastosPorCategoria();
      _calcularResumoMensal();
    } else {
      // Se não tiver token ou ID, volta para o login
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    String? emailEncontrado = prefs.getString('email_usuario');

    // Se o e-mail guardado veio como "usuario@wallet.com" ou nulo, vamos extrair do JWT!
    if (emailEncontrado == null || emailEncontrado == 'usuario@wallet.com') {
      final token = prefs.getString('jwt_token');
      if (token != null && !JwtDecoder.isExpired(token)) {
        try {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          // O seu payload do JWT do Node.js geralmente injeta o campo "email" ou "emailUsuario"
          if (decodedToken.containsKey('email')) {
            emailEncontrado = decodedToken['email'];
          }
        } catch (e) {
          debugPrint("Erro ao extrair e-mail do JWT: $e");
        }
      }
    }

    setState(() {
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Daniel';
      // Se encontrou o e-mail real usa ele, senão mantém o pinguim genérico por segurança
      _emailUsuario = emailEncontrado ?? 'pinguim@wallet.com';
    });
  }

  Future<void> _carregarTransacoes() async {
    if (usuarioId == null) return;
    try {
      final dados = await _apiService.obterTransacoes(usuarioId!);
      setState(() {
        // Forçamos a conversão limpa para garantir que o Flutter não rejeite o tipo de dado da lista
        _transacoes = List<dynamic>.from(dados);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erro ao carregar transações no Dashboard: $e');
    }
  }

  Future<void> _carregarGastosPorCategoria() async {
    try {
      final dados = await _apiService.obterGastosPorCategoria(usuarioId!);
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
      if (t != null && t['valor'] != null) {
        final valor = double.tryParse(t['valor'].toString()) ?? 0.0;
        final tipoTransacao = t['tipo'].toString().trim().toLowerCase();

        if (tipoTransacao == 'receita') {
          income += valor;
        } else if (tipoTransacao == 'despesa') {
          expenses += valor;
        }
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

    final transacoesInvertidas = _transacoes.reversed.toList();

    for (int i = 0; i < transacoesInvertidas.length && i < 7; i++) {
      final t = transacoesInvertidas[i];
      if (t != null && t['valor'] != null) {
        final double valor = double.tryParse(t['valor'].toString()) ?? 0.0;
        final tipoTransacao = t['tipo'].toString().trim().toLowerCase();

        if (tipoTransacao == 'despesa') {
          saldoAcumulado -= valor;
        } else if (tipoTransacao == 'receita') {
          saldoAcumulado += valor;
        }

        spots.add(FlSpot(i.toDouble(), saldoAcumulado));
      }
    }

    // Garante que o gráfico nunca fica sem dados para desenhar
    if (spots.isEmpty) {
      spots = [const FlSpot(0, 0.0), const FlSpot(1, 0.0)];
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
                  // ENVOLVA A COLUNA DE TEXTOS COM EXPANDED
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $_nomeUsuario! 👋',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Evita quebrar se a janela for mini
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Resumo das suas finanças',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                      width: 12), // Pequeno respiro entre o texto e o ícone
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
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

            // Gráfico de Pizza - Gastos por Categoria
            if (_gastosPorCategoria.isNotEmpty) ..._buildPieChartSection(),
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
                    : Column(
                        // <--- ENVOLVEMOS EM UMA COLUMN PARA POR O BOTÃO DE EXPANDIR
                        children: [
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            // Define a contagem baseada na variável de controle
                            itemCount: _mostrarTodasAsTransacoes
                                ? _transacoes.length
                                : (_transacoes.length > 5
                                    ? 5
                                    : _transacoes.length),
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
                                  border:
                                      Border.all(color: Colors.grey.shade200),
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
                          const SizedBox(height: 8),
                          // BOTÃO DINÂMICO: Expande ou minimiza a própria lista do Dashboard
                          if (_transacoes.length > 5)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _mostrarTodasAsTransacoes =
                                      !_mostrarTodasAsTransacoes;
                                });
                              },
                              icon: Icon(
                                _mostrarTodasAsTransacoes
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                _mostrarTodasAsTransacoes
                                    ? "Mostrar menos"
                                    : "Ver histórico completo",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                  context, '/historico'), // Rota da tela do Beani
              child: const Text("Ver histórico completo →"),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () {
          if (usuarioId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionPage(usuarioId: usuarioId!),
              ),
            ).then((_) => _carregarDadosIniciais());
          } else {
            print("Erro: Usuário não identificado.");
          }
        },
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1E3A8A), size: 36),
              ),
              accountName: Text(_nomeUsuario),
              accountEmail: Text(_emailUsuario),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF1E3A8A)),
              title: const Text("Dashboard",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Color(0xFF1E3A8A)),
              title: const Text("Relatório Mensal",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/relatorio'),
            ),
            ListTile(
              leading: const Icon(Icons.history,
                color: Color(0xFF1E3A8A)),
              title: const Text(
                "Histórico",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () =>
                Navigator.pushReplacementNamed(context, '/historico'),
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Color(0xFF1E3A8A)),
              title: const Text(
                "Categorias",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () =>
                Navigator.pushReplacementNamed(context, '/categorias'),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Sair da Conta",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Limpa tokens e dados salvos
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
    );
  }

  List<Widget> _buildPieChartSection() {
    final total = _gastosPorCategoria.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item['total'].toString()) ?? 0.0),
    );

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < _gastosPorCategoria.length; i++) {
      final item = _gastosPorCategoria[i];
      final valor = double.tryParse(item['total'].toString()) ?? 0.0;
      final percent = total > 0 ? (valor / total * 100) : 0.0;
      final color = _categoryColors[i % _categoryColors.length];
      sections.add(
        PieChartSectionData(
          value: valor,
          title: '${percent.toStringAsFixed(1)}%',
          color: color,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return [
      const Text(
        'Gastos por Categoria',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 14),
      Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 36,
                    sectionsSpace: 3,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // CORRIGIDO: Envolvemos a Column com Expanded para eliminar de vez o estouro de layout!
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_gastosPorCategoria.length, (i) {
                    final item = _gastosPorCategoria[i];
                    final color = _categoryColors[i % _categoryColors.length];
                    final valor =
                        double.tryParse(item['total'].toString()) ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // CORRIGIDO: Envolvemos o nome da categoria com Expanded para restringir o espaço horizontal
                          Expanded(
                            child: Text(
                              item['categoria'] ?? 'Outros',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Corta textos gigantes com '...'
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormat.currency(
                                    locale: 'pt_BR', symbol: 'R\$')
                                .format(valor),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
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
