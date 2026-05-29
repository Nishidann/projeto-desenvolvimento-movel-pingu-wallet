import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RelatorioPage extends StatefulWidget {
  const RelatorioPage({super.key});

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  double _totalReceitas = 0.0;
  double _totalDespesas = 0.0;
  List<dynamic> _gastosCategoria = [];
  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'pinguim@wallet.com';

  @override
  void initState() {
    super.initState();
    _carregarDadosRelatorio();
  }

  Future<void> _carregarDadosRelatorio() async {
    setState(() => _isLoading = true);

    try {
      // 1. Recupera o ID do usuário de forma assíncrona
      final int? idLogado = await _apiService.getUsuarioId();

      // Se não encontrar o usuário logado, interrompe e remove o loading
      if (idLogado == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Busca os dados na API usando o idLogado garantido com o operador '!'
      final List<dynamic> transacoes =
          await _apiService.obterTransacoes(idLogado);
      final List<dynamic> categorias =
          await _apiService.obterGastosPorCategoria(idLogado);

      // Tenta carregar também o nome do usuário para o Drawer
      final prefs = await SharedPreferences.getInstance();
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
      _emailUsuario = prefs.getString('email_usuario') ?? 'pinguim@wallet.com';

      double receitasLocal = 0.0;
      double despesasLocal = 0.0;

      // 3. Processa e soma as transações tratando tipagens dinâmicas com segurança
      for (var t in transacoes) {
        if (t is Map<String, dynamic>) {
          final valor = double.tryParse(t['valor'].toString()) ?? 0.0;
          if (t['tipo'] == 'receita') {
            receitasLocal += valor;
          } else if (t['tipo'] == 'despesa') {
            despesasLocal += valor;
          }
        }
      }

      // 4. Atualiza o estado da tela de uma só vez
      setState(() {
        _totalReceitas = receitasLocal;
        _totalDespesas = despesasLocal;
        _gastosCategoria = categorias;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar relatório: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double saldo = _totalReceitas - _totalDespesas;
    double percentualGasto =
        _totalReceitas > 0 ? (_totalDespesas / _totalReceitas) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Relatório Ártico",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(
            color: Colors.white), // Deixa o ícone do Drawer branco
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarDadosRelatorio,
          )
        ],
      ),
      // ADICIONADO O DRAWER CORRETAMENTE NO ESCOPO DO BUILD
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1E3A8A), size: 36),
              ),
              accountName: Text(
                  _nomeUsuario), // Certifique-se de que a tela possui a variável _nomeUsuario carregada
              accountEmail: Text(_emailUsuario),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF1E3A8A)),
              title: const Text('Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Color(0xFF1E3A8A)),
              title: const Text('Relatório Mensal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: ModalRoute.of(context)?.settings.name == '/relatorio',
              selectedTileColor: const Color(0xFF1E3A8A).withOpacity(0.08),
              onTap: () {
                if (ModalRoute.of(context)?.settings.name == '/relatorio') {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/relatorio');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF1E3A8A)),
              title: const Text('Histórico',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: ModalRoute.of(context)?.settings.name == '/historico',
              selectedTileColor: const Color(0xFF1E3A8A).withOpacity(0.08),
              onTap: () {
                if (ModalRoute.of(context)?.settings.name == '/historico') {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/historico');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Color(0xFF1E3A8A)),
              title: const Text('Categorias',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/categorias'),
            ),
            ListTile(
              leading: const Icon(Icons.ads_click, color: Color(0xFF1E3A8A)),
              title: const Text('Metas e Objetivos',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushReplacementNamed(context, '/metas'),
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumoCard(saldo, percentualGasto),
                  const SizedBox(height: 28),
                  const Text(
                    "Distribuição por Categoria",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildListaCategorias(),
                ],
              ),
            ),
    );
  }

  Widget _buildResumoCard(double saldo, double percentual) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    Color corSaude =
        percentual > 0.8 ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Balanço Mensal",
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(saldo),
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoMiniCard("Receitas", _totalReceitas, Icons.arrow_upward,
                  const Color(0xFF10B981)),
              _infoMiniCard("Despesas", _totalDespesas, Icons.arrow_downward,
                  const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentual.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              color: corSaude,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Comprometimento de renda: ${(percentual * 100).toStringAsFixed(1)}%",
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _infoMiniCard(String label, double valor, IconData icon, Color cor) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: cor, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text(
              currencyFormat.format(valor),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListaCategorias() {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    if (_gastosCategoria.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Nenhum gasto por categoria encontrado.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _gastosCategoria.length,
      itemBuilder: (context, index) {
        final item = _gastosCategoria[index];
        if (item is! Map<String, dynamic>) return const SizedBox.shrink();

        final categoriaNome = item['categoria'] ?? 'Geral';
        final valorCategoria = double.tryParse(item['total'].toString()) ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.pie_chart_outline,
                        color: Color(0xFF1E3A8A), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    categoriaNome.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              Text(
                currencyFormat.format(valorCategoria),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A)),
              ),
            ],
          ),
        );
      },
    );
  }
}
