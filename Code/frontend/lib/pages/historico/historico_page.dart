import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;

  List<dynamic> _transacoes = [];
  List<dynamic> _transacoesFiltradas = [];

  String? _categoriaSelecionada;

  DateTime? _dataInicio;
  DateTime? _dataFim;

  final List<String> _categorias = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);

    try {
      final int? idLogado = await _apiService.getUsuarioId();

      if (idLogado == null) {
        setState(() => _isLoading = false);
        return;
      }

      final transacoes =
          await _apiService.obterTransacoes(idLogado);

      _categorias.clear();

      for (var t in transacoes) {
        final categoria = t['categoria'];

        if (categoria != null &&
            !_categorias.contains(categoria.toString())) {
          _categorias.add(categoria.toString());
        }
      }

      setState(() {
        _transacoes = transacoes;
        _transacoesFiltradas = transacoes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar histórico: $e");

      setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros() {
    List<dynamic> filtradas = _transacoes;

    // FILTRO CATEGORIA
    if (_categoriaSelecionada != null &&
        _categoriaSelecionada!.isNotEmpty) {
      filtradas = filtradas.where((t) {
        return t['categoria']
                .toString()
                .toLowerCase() ==
            _categoriaSelecionada!
                .toLowerCase();
      }).toList();
    }

    // FILTRO DATA INICIAL
    if (_dataInicio != null) {
      filtradas = filtradas.where((t) {
        final data =
            DateTime.parse(t['data']);

        return data.isAfter(
                _dataInicio!
                    .subtract(const Duration(days: 1))) ||
            data.isAtSameMomentAs(_dataInicio!);
      }).toList();
    }

    // FILTRO DATA FINAL
    if (_dataFim != null) {
      filtradas = filtradas.where((t) {
        final data =
            DateTime.parse(t['data']);

        return data.isBefore(
                _dataFim!
                    .add(const Duration(days: 1))) ||
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
      initialDate: DateTime.now(),
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
      initialDate: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          "Histórico de Transações",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme:
            const IconThemeData(color: Colors.white),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [

                // FILTROS
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [

                      DropdownButtonFormField<String>(
                        value: _categoriaSelecionada,
                        decoration: InputDecoration(
                          labelText: "Categoria",
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Todas"),
                          ),

                          ..._categorias.map((categoria) {
                            return DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria),
                            );
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
                              onPressed:
                                  _selecionarDataInicial,
                              icon: const Icon(
                                  Icons.date_range),
                              label: Text(
                                _dataInicio == null
                                    ? "Data Inicial"
                                    : DateFormat(
                                            'dd/MM/yyyy')
                                        .format(
                                            _dataInicio!),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _selecionarDataFinal,
                              icon: const Icon(
                                  Icons.date_range),
                              label: Text(
                                _dataFim == null
                                    ? "Data Final"
                                    : DateFormat(
                                            'dd/MM/yyyy')
                                        .format(
                                            _dataFim!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _limparFiltros,
                          icon: const Icon(Icons.clear),
                          label:
                              const Text("Limpar filtros"),
                        ),
                      )
                    ],
                  ),
                ),

                // LISTA
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregarHistorico,
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount:
                          _transacoesFiltradas.length,
                      itemBuilder: (context, index) {

                        final t =
                            _transacoesFiltradas[index];

                        final valor =
                            double.tryParse(
                                  t['valor']
                                      .toString(),
                                ) ??
                                0.0;

                        final bool receita =
                            t['tipo'] == 'receita';

                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),

                          padding:
                              const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                                    20),
                            border: Border.all(
                              color:
                                  Colors.grey.shade200,
                            ),
                          ),

                          child: Row(
                            children: [

                              CircleAvatar(
                                backgroundColor:
                                    receita
                                        ? Colors.green
                                            .withValues(
                                                alpha:
                                                    0.12)
                                        : Colors.red
                                            .withValues(
                                                alpha:
                                                    0.12),

                                child: Icon(
                                  receita
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: receita
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    Text(
                                      t['descricao'] ??
                                          'Sem descrição',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      t['categoria'] ??
                                          'Geral',
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .grey[600],
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      DateFormat(
                                              'dd/MM/yyyy')
                                          .format(
                                        DateTime.parse(
                                            t['data']),
                                      ),
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                currencyFormat
                                    .format(valor),

                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color: receita
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
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