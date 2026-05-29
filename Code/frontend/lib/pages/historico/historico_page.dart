// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transaction_model.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  int _usuarioId = 1;

  List<dynamic> _transacoes = [];
  List<dynamic> _transacoesFiltradas = [];
  List<dynamic> _todasCategorias = [];

  String? _categoriaSelecionada;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final List<String> _categoriasFiltro = [];

  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'usuario@email.com';

  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _success = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    final idLogado = await _apiService.getUsuarioId();
    if (idLogado != null) _usuarioId = idLogado;

    // Carrega a tabela de categorias dinâmicas para alimentar os dropdowns
    try {
      final cats = await _apiService.listarCategorias(_usuarioId);
      _todasCategorias = cats;
    } catch (e) {
      print("Erro ao buscar tabela de categorias: $e");
    }

    await _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    try {
      final transacoes = await _apiService.obterTransacoes(_usuarioId);

      _categoriasFiltro.clear();
      for (var t in transacoes) {
        final categoria = t['categoria'];
        if (categoria != null &&
            !_categoriasFiltro.contains(categoria.toString())) {
          _categoriasFiltro.add(categoria.toString());
        }
      }

      final prefs = await SharedPreferences.getInstance();
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
      _emailUsuario = prefs.getString('email_usuario') ?? 'usuario@email.com';

      setState(() {
        _transacoes = transacoes;
        _transacoesFiltradas = transacoes;
        _isLoading = false;
      });
      _aplicarFiltros();
    } catch (e) {
      debugPrint("Erro ao carregar histórico: $e");
      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    List<dynamic> filtradas = _transacoes;

    // FILTRO CATEGORIA
    if (_categoriaSelecionada != null && _categoriaSelecionada!.isNotEmpty) {
      filtradas = filtradas.where((t) {
        return t['categoria'].toString().toLowerCase() ==
            _categoriaSelecionada!.toLowerCase();
      }).toList();
    }

    // FILTRO DATA INICIAL
    if (_dataInicio != null) {
      filtradas = filtradas.where((t) {
        final data = DateTime.parse(t['data_transacao']);
        return data.isAfter(_dataInicio!.subtract(const Duration(days: 1))) ||
            data.isAtSameMomentAs(_dataInicio!);
      }).toList();
    }

    // FILTRO DATA FINAL
    if (_dataFim != null) {
      filtradas = filtradas.where((t) {
        final data = DateTime.parse(t['data_transacao']);
        return data.isBefore(_dataFim!.add(const Duration(days: 1))) ||
            data.isAtSameMomentAs(_dataFim!);
      }).toList();
    }

    setState(() {
      _transacoesFiltradas = filtradas;
    });
  }

  Future<void> _selecionarDataInicial() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        _dataInicio = data;
      });
      _aplicarFiltros();
    }
  }

  Future<void> _selecionarDataFinal() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        _dataFim = data;
      });
      _aplicarFiltros();
    }
  }

  void _limparFiltros() {
    setState(() {
      _categoriaSelecionada = null;
      _dataInicio = null;
      _dataFim = null;
      _transacoesFiltradas = _transacoes;
    });
  }

  // =========================================================================
  // MODAL DE EDIÇÃO PREMIUM PARA O HISTÓRICO (FULL-STACK)
  // =========================================================================
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
            backgroundColor: Colors.white,
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
                            color: _accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_note,
                            color: _accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Editar Registro',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _primary)),
                          Text('Modifique os detalhes da transação',
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
                          color: _primary),
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
                      prefixIcon:
                          const Icon(Icons.calculate_outlined, color: _primary),
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
                                        color: _success,
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
                            backgroundColor: _primary,
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

                            final novaTransacao = TransactionModel(
                              descricao: descCtrl.text.trim(),
                              valor: double.tryParse(valorCtrl.text) ?? 0.0,
                              tipo: tipoSelecionado,
                              categoria: categoriaSelecionada,
                              dataTransacao: dataTratada,
                            );

                            await _apiService.editarTransacao(
                                t['id'], novaTransacao);
                            _carregarHistorico(); // Recarrega mantendo os filtros aplicados
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

  // =========================================================================
  // GESTÃO DE EXCLUSÃO DE LANÇAMENTOS NO HISTÓRICO
  // =========================================================================
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
              const Text('Excluir do Histórico?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Deseja apagar definitivamente "$descricao"?',
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
                        _carregarHistorico();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Histórico de Transações",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
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
              selected: true,
              selectedTileColor: _primary.withOpacity(0.08),
              onTap: () => Navigator.pop(context),
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
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // FILTROS SUPERIORES
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: "Filtrar por Categoria",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("Todas")),
                          ..._categoriasFiltro.map((categoria) {
                            return DropdownMenuItem(
                                value: categoria, child: Text(categoria));
                          })
                        ],
                        onChanged: (value) {
                          setState(() {
                            _categoriaSelecionada = value;
                          });
                          _aplicarFiltros();
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selecionarDataInicial,
                              icon: const Icon(Icons.date_range),
                              label: Text(_dataInicio == null
                                  ? "Data Inicial"
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_dataInicio!)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selecionarDataFinal,
                              icon: const Icon(Icons.date_range),
                              label: Text(_dataFim == null
                                  ? "Data Final"
                                  : DateFormat('dd/MM/yyyy').format(_dataFim!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _limparFiltros,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text("Limpar filtros",
                              style: TextStyle(fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                ),

                // LISTAGEM DO HISTÓRICO COMPLETO
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregarHistorico,
                    color: _primary,
                    child: _transacoesFiltradas.isEmpty
                        ? ListView(
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Center(
                                    child: Text(
                                        "Nenhuma transação corresponde aos filtros.",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold))),
                              )
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _transacoesFiltradas.length,
                            itemBuilder: (context, index) {
                              final t = _transacoesFiltradas[index];
                              final valor =
                                  double.tryParse(t['valor'].toString()) ?? 0.0;
                              final tipo = t['tipo']?.toString() ?? '';
                              final bool receita =
                                  tipo.toLowerCase() == 'receita';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onLongPress: () => _mostrarOpcoesTransacao(
                                      t), // <--- SEGUIDO E TRAZ OPÇÕES NO HISTÓRICO
                                  borderRadius: BorderRadius.circular(28),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          28), // Unificado Design tokens de 28px
                                      border: Border.all(
                                          color: Colors.grey.shade100,
                                          width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: receita
                                              ? _success.withOpacity(0.12)
                                              : Colors.red.withOpacity(0.12),
                                          child: Icon(
                                            receita
                                                ? Icons.arrow_upward
                                                : Icons
                                                    .arrow_downward, // Ajustado fluxo visual intuitivo
                                            color:
                                                receita ? _success : Colors.red,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  t['descricao']?.toString() ??
                                                      'Sem descrição',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color:
                                                          Color(0xFF0F172A))),
                                              const SizedBox(height: 4),
                                              Text(
                                                  t['categoria']?.toString() ??
                                                      'Geral',
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(
                                                    DateTime.tryParse(
                                                            t['data_transacao']
                                                                    ?.toString() ??
                                                                '') ??
                                                        DateTime.now()),
                                                style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${receita ? '+' : '-'} ${currencyFormat.format(valor)}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: receita
                                                  ? _success
                                                  : Colors.red,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                )
              ],
            ),
    );
  }
}
