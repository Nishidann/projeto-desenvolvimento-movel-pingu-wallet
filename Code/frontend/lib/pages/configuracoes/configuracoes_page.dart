// ignore_for_file: deprecated_member_use, avoid_print
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final ApiService _apiService = ApiService();

  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _accent = Color(0xFFFF7A00);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _surface = Colors.white;
  static const Color _danger = Color(0xFFEF4444);

  int _usuarioId = 1;
  String _nomeUsuario = '';
  String _emailUsuario = '';
  bool _isLoading = true;

  // Controladores do formulário de perfil
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _idadeController = TextEditingController();
  final _cepController = TextEditingController();

  // Controladores do formulário de senha
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _salvandoPerfil = false;
  bool _salvandoSenha = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _idadeController.dispose();
    _cepController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final id = await _apiService.getUsuarioId();
    if (id != null) _usuarioId = id;

    final prefs = await SharedPreferences.getInstance();
    _nomeUsuario = prefs.getString('nome_usuario') ?? 'Usuário';
    _emailUsuario = prefs.getString('email_usuario') ?? '';

    final perfil = await _apiService.getUsuarioPerfil(_usuarioId);
    if (perfil != null) {
      _nomeController.text = perfil['nome'] ?? '';
      _emailController.text = perfil['email'] ?? '';
      _idadeController.text = perfil['idade']?.toString() ?? '';
      _cepController.text = perfil['cep'] ?? '';
      setState(() {
        _nomeUsuario = perfil['nome'] ?? 'Usuário';
        _emailUsuario = perfil['email'] ?? '';
      });
    } else {
      _nomeController.text = _nomeUsuario;
      _emailController.text = _emailUsuario;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _salvarPerfil() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final idadeStr = _idadeController.text.trim();
    final cep = _cepController.text.trim();

    if (nome.isEmpty || email.isEmpty || idadeStr.isEmpty || cep.isEmpty) {
      _mostrarSnackbar('Preencha todos os campos do perfil.', isErro: true);
      return;
    }
    final idade = int.tryParse(idadeStr);
    if (idade == null || idade <= 0 || idade > 120) {
      _mostrarSnackbar('Idade inválida.', isErro: true);
      return;
    }

    setState(() => _salvandoPerfil = true);
    final resultado = await _apiService.atualizarUsuario(
      id: _usuarioId,
      nome: nome,
      idade: idade,
      cep: cep,
      email: email,
    );
    setState(() => _salvandoPerfil = false);

    if (resultado['success'] == true) {
      // Atualiza o cache local com os novos dados
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nome_usuario', nome);
      await prefs.setString('email_usuario', email);
      setState(() {
        _nomeUsuario = nome;
        _emailUsuario = email;
      });
      _mostrarSnackbar('Perfil atualizado com sucesso!');
    } else {
      _mostrarSnackbar(resultado['message'] ?? 'Erro ao salvar.', isErro: true);
    }
  }

  Future<void> _salvarSenha() async {
    final senhaAtual = _senhaAtualController.text;
    final novaSenha = _novaSenhaController.text;
    final confirmar = _confirmarSenhaController.text;

    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmar.isEmpty) {
      _mostrarSnackbar('Preencha todos os campos de senha.', isErro: true);
      return;
    }
    if (novaSenha.length < 6) {
      _mostrarSnackbar('A nova senha deve ter pelo menos 6 caracteres.', isErro: true);
      return;
    }
    if (novaSenha != confirmar) {
      _mostrarSnackbar('As senhas não coincidem.', isErro: true);
      return;
    }

    setState(() => _salvandoSenha = true);
    // Busca o nome/email/idade/cep atuais para não perder dados
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final idadeStr = _idadeController.text.trim();
    final cep = _cepController.text.trim();
    final idade = int.tryParse(idadeStr) ?? 0;

    final resultado = await _apiService.atualizarUsuario(
      id: _usuarioId,
      nome: nome,
      idade: idade,
      cep: cep,
      email: email,
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
    );
    setState(() => _salvandoSenha = false);

    if (resultado['success'] == true) {
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();
      _mostrarSnackbar('Senha alterada com sucesso!');
    } else {
      _mostrarSnackbar(resultado['message'] ?? 'Erro ao alterar senha.', isErro: true);
    }
  }

  void _mostrarSnackbar(String msg, {bool isErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isErro ? _danger : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: _danger, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Sair da Conta',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
              const SizedBox(height: 8),
              Text('Tem certeza que deseja sair?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
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
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sair',
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

    if (confirmado == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // ============================================================
  // HELPERS DE WIDGET
  // ============================================================

  Widget _buildSectionTitle(String titulo, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: _primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _primary)),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: _primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Configurações',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: _primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarDados,
            tooltip: 'Recarregar',
          ),
        ],
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
              onTap: () =>
                  Navigator.pushReplacementNamed(context, '/historico'),
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
            ListTile(
              leading: const Icon(Icons.settings, color: _primary),
              title: const Text('Configurações',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedTileColor: _primary.withOpacity(0.08),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sair da Conta',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _carregarDados,
              color: _primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar / Header ──────────────────────────────
                    _buildCard(
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_nomeUsuario,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _primary)),
                                const SizedBox(height: 2),
                                Text(_emailUsuario,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Editar Perfil ─────────────────────────────────
                    _buildSectionTitle('Editar Perfil', Icons.edit_outlined),
                    _buildCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nomeController,
                            decoration:
                                _inputDecoration('Nome completo', Icons.person_outline),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emailController,
                            decoration:
                                _inputDecoration('E-mail', Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _idadeController,
                                  decoration: _inputDecoration(
                                      'Idade', Icons.cake_outlined),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _cepController,
                                  decoration: _inputDecoration(
                                      'CEP', Icons.location_on_outlined),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _salvandoPerfil ? null : _salvarPerfil,
                              icon: _salvandoPerfil
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                  _salvandoPerfil ? 'Salvando...' : 'Salvar Perfil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Alterar Senha ─────────────────────────────────
                    _buildSectionTitle('Alterar Senha', Icons.lock_outline),
                    _buildCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _senhaAtualController,
                            obscureText: !_senhaAtualVisivel,
                            decoration: _inputDecoration(
                                    'Senha atual', Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _senhaAtualVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                    () => _senhaAtualVisivel = !_senhaAtualVisivel),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _novaSenhaController,
                            obscureText: !_novaSenhaVisivel,
                            decoration: _inputDecoration(
                                    'Nova senha', Icons.lock_open_outlined)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _novaSenhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                    () => _novaSenhaVisivel = !_novaSenhaVisivel),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirmarSenhaController,
                            obscureText: !_confirmarSenhaVisivel,
                            decoration: _inputDecoration(
                                    'Confirmar nova senha', Icons.check_circle_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmarSenhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(() =>
                                    _confirmarSenhaVisivel =
                                        !_confirmarSenhaVisivel),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _salvandoSenha ? null : _salvarSenha,
                              icon: _salvandoSenha
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.lock_reset_outlined),
                              label: Text(_salvandoSenha
                                  ? 'Alterando...'
                                  : 'Alterar Senha'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Sobre o App ───────────────────────────────────
                    _buildSectionTitle('Sobre o App', Icons.info_outline),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.icecream_outlined, 'Pingu Wallet',
                              'Sua carteira digital inteligente'),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.tag, 'Versão', '1.0.0'),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.security_outlined, 'Segurança',
                              'Dados protegidos com JWT + bcrypt'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Sair ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: _danger),
                        label: const Text('Sair da Conta',
                            style: TextStyle(
                                color: _danger, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: _danger),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icone, String titulo, String subtitulo) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: _primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(subtitulo,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}
