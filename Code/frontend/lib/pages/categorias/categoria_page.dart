import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

// ignore_for_file: deprecated_member_use

class CategoriaPage extends StatefulWidget {
  const CategoriaPage({super.key});

  @override
  State<CategoriaPage> createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<dynamic> _categoriasDespesa = [];
  List<dynamic> _categoriasReceita = [];
  bool _isLoading = true;

  int? _usuarioId;
  String _nomeUsuario = 'Usuário';
  String _emailUsuario = 'usuario@email.com';

  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _secondary = Color(0xFF3B82F6);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _background = Color(0xFFF8FAFC);

  static const Map<String, IconData> iconMap = {
    // Alimentação
    'restaurant': Icons.restaurant,
    'fastfood': Icons.fastfood,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'bakery_dining': Icons.bakery_dining,
    'set_meal': Icons.set_meal,
    // Transporte
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'directions_bike': Icons.directions_bike,
    'local_taxi': Icons.local_taxi,
    'train': Icons.train,
    'flight': Icons.flight,
    'local_gas_station': Icons.local_gas_station,
    'local_parking': Icons.local_parking,
    // Casa
    'home': Icons.home,
    'home_repair_service': Icons.home_repair_service,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'electrical_services': Icons.electrical_services,
    // Saúde
    'favorite': Icons.favorite,
    'local_hospital': Icons.local_hospital,
    'local_pharmacy': Icons.local_pharmacy,
    'fitness_center': Icons.fitness_center,
    'self_improvement': Icons.self_improvement,
    'spa': Icons.spa,
    // Educação
    'school': Icons.school,
    'book': Icons.book,
    'science': Icons.science,
    'laptop': Icons.laptop,
    'computer': Icons.computer,
    // Entretenimento
    'sports_esports': Icons.sports_esports,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'theater_comedy': Icons.theater_comedy,
    'palette': Icons.palette,
    'camera_alt': Icons.camera_alt,
    // Compras
    'shopping_cart': Icons.shopping_cart,
    'checkroom': Icons.checkroom,
    'storefront': Icons.storefront,
    // Finanças
    'attach_money': Icons.attach_money,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'payments': Icons.payments,
    'trending_up': Icons.trending_up,
    'percent': Icons.percent,
    // Trabalho & Renda
    'work': Icons.work,
    'business_center': Icons.business_center,
    'card_giftcard': Icons.card_giftcard,
    // Esportes & Lazer
    'sports_soccer': Icons.sports_soccer,
    'sports_basketball': Icons.sports_basketball,
    'sports_tennis': Icons.sports_tennis,
    'directions_run': Icons.directions_run,
    'beach_access': Icons.beach_access,
    'hiking': Icons.hiking,
    // Tecnologia
    'smartphone': Icons.smartphone,
    'headphones': Icons.headphones,
    'gamepad': Icons.gamepad,
    'subscriptions': Icons.subscriptions,
    // Outros
    'pets': Icons.pets,
    'celebration': Icons.celebration,
    'volunteer_activism': Icons.volunteer_activism,
    'star': Icons.star,
    'label': Icons.label,
    'more_horiz': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    final id = await _apiService.getUsuarioId();
    if (id == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final categorias = await _apiService.listarCategorias(id);

    setState(() {
      _usuarioId = id;
      _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
      _emailUsuario = prefs.getString('email_usuario') ?? 'usuario@email.com';
      _categoriasDespesa =
          categorias.where((c) => c['tipo'] == 'despesa').toList();
      _categoriasReceita =
          categorias.where((c) => c['tipo'] == 'receita').toList();
      _isLoading = false;
    });
  }

  void _mostrarDialogCategoria(
      {Map<String, dynamic>? categoria, required String tipo}) {
    final nomeController =
        TextEditingController(text: categoria?['nome'] ?? '');
    String iconeSelecionado = categoria?['icone'] ?? 'label';
    final isEdicao = categoria != null;
    final corTipo = tipo == 'despesa' ? _danger : _success;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                        color: corTipo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdicao ? Icons.edit_outlined : Icons.add,
                        color: corTipo,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdicao ? 'Editar Categoria' : 'Nova Categoria',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        Text(
                          tipo == 'despesa' ? 'Despesa' : 'Receita',
                          style: TextStyle(
                            fontSize: 12,
                            color: corTipo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Categoria',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: corTipo, width: 2),
                    ),
                    prefixIcon: Icon(Icons.label_outline, color: corTipo),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Escolha um ícone',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconMap.entries.map((entry) {
                    final isSelected = iconeSelecionado == entry.key;
                    return GestureDetector(
                      onTap: () =>
                          setStateDialog(() => iconeSelecionado = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected ? corTipo : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? corTipo : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: corTipo.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
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
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corTipo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (nomeController.text.trim().isEmpty) return;
                          Navigator.pop(context);
                          if (!isEdicao) {
                            await _apiService.adicionarCategoria(
                              usuarioId: _usuarioId!,
                              nome: nomeController.text.trim(),
                              tipo: tipo,
                              icone: iconeSelecionado,
                            );
                          } else {
                            await _apiService.editarCategoria(
                              id: categoria['id'],
                              nome: nomeController.text.trim(),
                              icone: iconeSelecionado,
                            );
                          }
                          _carregarDados();
                        },
                        child: Text(
                          isEdicao ? 'Salvar' : 'Adicionar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarDeletar(int id, String nome) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.delete_outline, color: _danger, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deletar Categoria',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tem certeza que deseja deletar "$nome"?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _apiService.deletarCategoria(id);
                        _carregarDados();
                      },
                      child: const Text('Deletar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int count, String tipo) {
    final cor = tipo == 'despesa' ? _danger : _success;
    final icon = tipo == 'despesa' ? Icons.arrow_downward : Icons.arrow_upward;
    final label = tipo == 'despesa' ? 'despesas' : 'receitas';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count categorias de $label',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Toque em + para adicionar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaCategorias(List<dynamic> categorias, String tipo) {
    final cor = tipo == 'despesa' ? _danger : _success;
    return Column(
      children: [
        _buildHeaderCard(categorias.length, tipo),
        if (categorias.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category_outlined,
                        size: 48, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma categoria ainda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toque no botão + para criar a primeira',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final cat = categorias[index];
                final iconData = iconMap[cat['icone']] ?? Icons.label;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(color: cor, width: 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: cor, size: 22),
                    ),
                    title: Text(
                      cat['nome'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _primary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _mostrarDialogCategoria(
                              categoria: cat, tipo: tipo),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _secondary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_outlined,
                                color: _secondary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              _confirmarDeletar(cat['id'], cat['nome']),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: _danger, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Categorias',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarDados,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: _accent,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.arrow_downward, size: 18), text: 'Despesas'),
            Tab(icon: Icon(Icons.arrow_upward, size: 18), text: 'Receitas'),
          ],
        ),
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
              title: const Text('Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Color(0xFF1E3A8A)),
              title: const Text('Relatório Mensal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/relatorio'),
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
              selected: true,
              selectedTileColor:
                  const Color(0xFF1E3A8A).withValues(alpha: 0.08),
              onTap: () => Navigator.pop(context),
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaCategorias(_categoriasDespesa, 'despesa'),
                _buildListaCategorias(_categoriasReceita, 'receita'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          final tipo = _tabController.index == 0 ? 'despesa' : 'receita';
          _mostrarDialogCategoria(tipo: tipo);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
