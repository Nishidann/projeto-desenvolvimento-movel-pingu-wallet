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
  List<dynamic> _listaTransacoes = [];
  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'pinguim@wallet.com';

  @override
  void initState() {
    super.initState();
    _carregarDadosRelatorio();
  }

  // MAPEAMENTO INTELIGENTE DE ÍCONES (Mais opções como Roupa e Assinaturas)
  IconData _obterIcone(String nomeCategoria, String tipo) {
    final n = nomeCategoria.toLowerCase();
    if (tipo == 'receita') {
      if (n.contains('salário') ||
          n.contains('salario') ||
          n.contains('trabalho')) return Icons.work;
      if (n.contains('investimento') || n.contains('renda'))
        return Icons.trending_up;
      return Icons.attach_money;
    } else {
      if (n.contains('alimento') ||
          n.contains('comida') ||
          n.contains('restaurante')) return Icons.restaurant;
      if (n.contains('transporte') || n.contains('carro') || n.contains('uber'))
        return Icons.directions_car;
      if (n.contains('saúde') || n.contains('saude') || n.contains('farmácia'))
        return Icons.local_hospital;
      if (n.contains('casa') || n.contains('moradia') || n.contains('aluguel'))
        return Icons.home;
      if (n.contains('lazer') || n.contains('pinguim') || n.contains('festa'))
        return Icons.celebration;
      if (n.contains('educação') ||
          n.contains('escola') ||
          n.contains('faculdade')) return Icons.school;
      if (n.contains('compras') || n.contains('shopping'))
        return Icons.shopping_cart;
      // ADICIONADOS: ROUPAS E ASSINATURAS
      if (n.contains('roupa') ||
          n.contains('vestuário') ||
          n.contains('calçado')) return Icons.checkroom;
      if (n.contains('assinatura') ||
          n.contains('streaming') ||
          n.contains('internet')) return Icons.subscriptions;

      return Icons.label_outline; // Default Despesa
    }
  }

  Future<void> _carregarDadosRelatorio() async {
    setState(() => _isLoading = true);
    try {
      final int? idLogado = await _apiService.getUsuarioId();
      if (idLogado == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final transacoes = await _apiService.obterTransacoes(idLogado);
      final categorias = await _apiService.obterGastosPorCategoria(idLogado);
      final prefs = await SharedPreferences.getInstance();

      double receitas = 0.0;
      double despesas = 0.0;

      for (var t in transacoes) {
        final valor = double.tryParse(t['valor'].toString()) ?? 0.0;
        if (t['tipo'] == 'receita')
          receitas += valor;
        else if (t['tipo'] == 'despesa') despesas += valor;
      }

      setState(() {
        _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
        _emailUsuario =
            prefs.getString('email_usuario') ?? 'pinguim@wallet.com';
        _totalReceitas = receitas;
        _totalDespesas = despesas;
        _gastosCategoria = categorias;
        _listaTransacoes = transacoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double saldo = _totalReceitas - _totalDespesas;
    double percentualGasto =
        _totalReceitas > 0 ? (_totalDespesas / _totalReceitas) : 0.0;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Relatório Ártico",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Text('🐧', style: TextStyle(fontSize: 32)),
              ),
              accountName: Text(_nomeUsuario),
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
              selected: true,
              selectedTileColor: const Color(0xFF1E3A8A).withOpacity(0.08),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF1E3A8A)),
              title: const Text('Histórico',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/historico'),
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
              leading: const Icon(Icons.settings, color: Color(0xFF1E3A8A)),
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumoCard(saldo, percentualGasto, currencyFormat),
                  const SizedBox(height: 28),
                  const Text("Despesas por Categoria",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 6),
                  const Text("Toque em uma categoria para ver os detalhes",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildListaCategorias(currencyFormat),
                  const SizedBox(height: 28),
                  const Text("Detalhamento de Receitas",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 6),
                  const Text("Toque em uma categoria para ver os detalhes",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _buildListaReceitas(currencyFormat),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildResumoCard(
      double saldo, double percentual, NumberFormat format) {
    Color barColor =
        percentual > 0.8 ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Text("Balanço Mensal",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(format.format(saldo),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Comprometimento da Renda",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${(percentual * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: barColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentual.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: barColor,
                  minHeight: 8,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoMiniCard(String label, double valor, IconData icon, Color cor) {
    return Row(
      children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: cor, size: 18)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(
                NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$')
                    .format(valor),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildListaCategorias(NumberFormat format) {
    if (_gastosCategoria.isEmpty)
      return const Text('Nenhuma despesa lançada.',
          style: TextStyle(color: Colors.grey));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _gastosCategoria.length,
      itemBuilder: (context, index) {
        final item = _gastosCategoria[index];
        final nome = item['categoria'] ?? 'Geral';
        final total = double.tryParse(item['total'].toString()) ?? 0.0;

        final transacoesDestaCategoria = _listaTransacoes
            .where((t) => t['categoria'] == nome && t['tipo'] == 'despesa')
            .toList();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.red.shade100, width: 1.5)),
          margin: const EdgeInsets.only(bottom: 10),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                  child: Icon(_obterIcone(nome, 'despesa'),
                      color: const Color(0xFFEF4444))),
              title: Text(nome,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
              subtitle: Text('Total: ${format.format(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
              childrenPadding: const EdgeInsets.only(bottom: 10),
              children: transacoesDestaCategoria.map((t) {
                final double valorUnico =
                    double.tryParse(t['valor'].toString()) ?? 0.0;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.subdirectory_arrow_right,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(t['descricao'] ?? 'Sem descrição',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(format.format(valorUnico),
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // MUDADO: Agrupamento manual e ExpansionTile para o Raio-X de Receitas
  Widget _buildListaReceitas(NumberFormat format) {
    final receitas =
        _listaTransacoes.where((t) => t['tipo'] == 'receita').toList();

    if (receitas.isEmpty)
      return const Text('Nenhuma receita cadastrada neste mês.',
          style: TextStyle(color: Colors.grey));

    // Agrupar receitas em um Map em tempo real
    Map<String, double> receitasAgrupadas = {};
    for (var r in receitas) {
      final cat = r['categoria'] ?? 'Geral';
      final valor = double.tryParse(r['valor'].toString()) ?? 0.0;
      receitasAgrupadas[cat] = (receitasAgrupadas[cat] ?? 0.0) + valor;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: receitasAgrupadas.length,
      itemBuilder: (context, index) {
        final nomeCategoria = receitasAgrupadas.keys.elementAt(index);
        final totalCategoria = receitasAgrupadas[nomeCategoria]!;

        // Filtra as transações dessa categoria para mostrar expandido
        final transacoesDestaCategoria = receitas
            .where((t) => (t['categoria'] ?? 'Geral') == nomeCategoria)
            .toList();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.green.shade200, width: 1.5)),
          margin: const EdgeInsets.only(bottom: 10),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                  child: Icon(_obterIcone(nomeCategoria, 'receita'),
                      color: const Color(0xFF10B981))),
              title: Text(nomeCategoria,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
              subtitle: Text('Total: + ${format.format(totalCategoria)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              childrenPadding: const EdgeInsets.only(bottom: 10),
              children: transacoesDestaCategoria.map((t) {
                final double valorUnico =
                    double.tryParse(t['valor'].toString()) ?? 0.0;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.subdirectory_arrow_right,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(t['descricao'] ?? 'Entrada',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('+ ${format.format(valorUnico)}',
                          style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
