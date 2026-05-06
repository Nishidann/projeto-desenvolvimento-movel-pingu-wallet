import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';

// ignore_for_file: avoid_print, deprecated_member_use

class AppColors {
  static const Color backgroundStart =
      Color(0xFFE0E7FF); // Azul mais suave no topo
  static const Color backgroundEnd = Color(0xFFF8FAFC); // Branco-neve na base
  static const Color surface =
      Color(0xD9FFFFFF); // Efeito de vidro (Transparência de 85%)
  static const Color primary = Color(0xFF3B82F6); // Azul vibrante moderno
  static const Color secondary = Color(0xFF1E3A8A); // Azul Marinho Profundo
  static const Color accent =
      Color(0xFFFF7A00); // Laranja Pinguim de alto contraste
  static const Color success = Color(0xFF10B981); // Verde esmeralda moderno
  static const Color textDark = Color(0xFF0F172A);
  static const Color textLight = Color(0xFFFFFFFF);
}

class TransactionPage extends StatefulWidget {
  final int usuarioId;
  const TransactionPage({super.key, required this.usuarioId});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  String _categoriaSelecionada = '';
  String _tipo = 'despesa';
  bool _isLoading = false;
  DateTime _dataSelecionada = DateTime.now();

  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> get _categorias {
    if (_tipo == 'despesa') {
      return [
        {'nome': 'Alimentação', 'icon': Icons.restaurant},
        {'nome': 'Transporte', 'icon': Icons.directions_car},
        {'nome': 'Moradia', 'icon': Icons.home},
        {'nome': 'Saúde', 'icon': Icons.favorite},
        {'nome': 'Educação', 'icon': Icons.school},
        {'nome': 'Lazer', 'icon': Icons.sports_esports},
        {'nome': 'Roupas', 'icon': Icons.checkroom},
        {'nome': 'Assinaturas', 'icon': Icons.subscriptions},
        {'nome': 'Outros', 'icon': Icons.more_horiz},
      ];
    } else {
      return [
        {'nome': 'Salário', 'icon': Icons.work},
        {'nome': 'Freelance', 'icon': Icons.laptop},
        {'nome': 'Investimento', 'icon': Icons.trending_up},
        {'nome': 'Presente', 'icon': Icons.card_giftcard},
        {'nome': 'Outros', 'icon': Icons.more_horiz},
      ];
    }
  }

  void _salvarTransacao() async {
    setState(() {
      _isLoading = true;
    });

    final nome = _nomeController.text;
    final valor = double.tryParse(_valorController.text) ?? 0.0;

    if (nome.isEmpty || valor <= 0 || _categoriaSelecionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos corretamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final novaTransacao = TransactionModel(
      descricao: nome,
      valor: valor,
      tipo: _tipo,
      categoria: _categoriaSelecionada,
      dataTransacao: _dataSelecionada,
    );

    try {
      await _apiService.cadastrarTransacao(novaTransacao, widget.usuarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação salva com sucesso! 🧊'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar ao servidor: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Botão minimalista de voltar
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.textLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),

              // Conteúdo Central Minimalista
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 60.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone do topo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 38,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Novo Lançamento',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione suas movimentações mensais',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Seletores de Tipo em formato de botões
                        Row(
                          children: [
                            Expanded(
                                child:
                                    _tipoBotao('DESPESA', Colors.red.shade400)),
                            const SizedBox(width: 10),
                            Expanded(
                                child:
                                    _tipoBotao('RECEITA', AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Campos de texto
                        _inputField(
                          controller: _nomeController,
                          label: 'Nome',
                          icon: Icons.label_outline,
                        ),
                        const SizedBox(height: 14),
                        _inputField(
                          controller: _valorController,
                          label: 'Valor (R\$)',
                          icon: Icons.attach_money,
                          isNumber: true,
                        ),
                        const SizedBox(height: 14),
                        _dropdownCategoria(),
                        const SizedBox(height: 14),
                        _datePicker(),
                        const SizedBox(height: 32),

                        // Botão de salvar com loading
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _salvarTransacao,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.textLight,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Salvar Transação',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.ac_unit,
                                        size: 16,
                                        color: AppColors.textLight,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipoBotao(String tipoNome, Color corAtiva) {
    final bool isSelected = _tipo == tipoNome.toLowerCase();
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected ? corAtiva : Colors.grey.shade300,
          width: isSelected ? 2 : 1.2,
        ),
        backgroundColor:
            isSelected ? corAtiva.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () {
        setState(() {
          _tipo = tipoNome.toLowerCase();
          _categoriaSelecionada = '';
        });
      },
      child: Text(
        tipoNome,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? corAtiva : Colors.grey.shade600,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _dropdownCategoria() {
    final corAtiva = _tipo == 'despesa' ? Colors.red.shade400 : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _categoriaSelecionada.isEmpty ? null : _categoriaSelecionada,
          hint: Row(
            children: [
              const Icon(Icons.category, size: 20, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text(
                'Categoria',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
          items: _categorias.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['nome'] as String,
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData, size: 20, color: corAtiva),
                  const SizedBox(width: 12),
                  Text(
                    cat['nome'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _categoriaSelecionada = value ?? '';
            });
          },
        ),
      ),
    );
  }

  Widget _datePicker() {
    final formatter = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dataSelecionada,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _dataSelecionada = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: AppColors.secondary),
            const SizedBox(width: 12),
            Text(
              formatter.format(_dataSelecionada),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, size: 20, color: AppColors.secondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
