import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();

  bool _carregando = true;
  double? _saldoTotal;
  double? _totalReceitas;
  double? _totalDespesas;
  int? _totalTransacoes;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final dados = await _apiService.buscarResumo();

    if (mounted) {
      setState(() {
        _carregando = false;
        if (dados != null) {
          _saldoTotal = (dados['saldo_total'] as num).toDouble();
          _totalReceitas = (dados['total_receitas'] as num).toDouble();
          _totalDespesas = (dados['total_despesas'] as num).toDouble();
          _totalTransacoes = dados['total_transacoes'] as int;
        } else {
          _erro = 'Não foi possível conectar ao servidor.';
        }
      });
    }
  }

  void _fazerLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _formatarMoeda(double? valor) {
    if (valor == null) return 'R\$ --';
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Pingu Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarResumo,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _fazerLogout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarResumo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================
              // CARD PRINCIPAL - SALDO TOTAL
              // ============================================
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saldo Total',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_carregando)
                      const SizedBox(
                        height: 40,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_erro != null)
                      Text(
                        _erro!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      )
                    else
                      Text(
                        _formatarMoeda(_saldoTotal),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!_carregando && _totalTransacoes != null)
                      Text(
                        '$_totalTransacoes transação(ões) registrada(s)',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ============================================
              // CARDS DE RECEITAS E DESPESAS
              // ============================================
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      titulo: 'Receitas',
                      valor: _formatarMoeda(_carregando ? null : _totalReceitas),
                      icone: Icons.arrow_upward_rounded,
                      cor: const Color(0xFF2E7D32),
                      corFundo: const Color(0xFFE8F5E9),
                      carregando: _carregando,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      titulo: 'Despesas',
                      valor: _formatarMoeda(_carregando ? null : _totalDespesas),
                      icone: Icons.arrow_downward_rounded,
                      cor: const Color(0xFFC62828),
                      corFundo: const Color(0xFFFFEBEE),
                      carregando: _carregando,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================
              // MENSAGEM DE BOAS VINDAS / ERRO
              // ============================================
              if (_erro != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFC62828)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: const TextStyle(color: Color(0xFFC62828)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!_carregando)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Color(0xFF1565C0)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bem-vindo ao Pingu Wallet! 🐧\nSeu painel financeiro está pronto.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF37474F)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    required Color corFundo,
    required bool carregando,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: TextStyle(
                  color: cor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (carregando)
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: cor, strokeWidth: 2),
            )
          else
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}