import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  // ESTADOS DOS OLHINHOS
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;

  String? _validarNome(String nome) {
    nome = nome.trim();
    if (nome.isEmpty) return 'Nome é obrigatório';
    if (nome.length < 3) return 'Nome deve ter pelo menos 3 caracteres';
    return null;
  }

  String? _validarIdade(String idade) {
    idade = idade.trim();
    if (idade.isEmpty) return 'Idade é obrigatória';
    final idadeNum = int.tryParse(idade);
    if (idadeNum == null) return 'Idade deve ser um número válido';
    if (idadeNum < 18) return 'Você deve ter no mínimo 18 anos';
    if (idadeNum > 120) return 'Idade deve ser menor que 120 anos';
    return null;
  }

  String? _validarCPF(String cpf) {
    cpf = cpf.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (cpf.isEmpty) return 'CPF é obrigatório';
    if (cpf.length != 11) return 'CPF deve ter 11 dígitos';
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return 'CPF inválido';

    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int resto = soma % 11;
    int dv1 = resto < 2 ? 0 : 11 - resto;

    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    resto = soma % 11;
    int dv2 = resto < 2 ? 0 : 11 - resto;

    if (dv1 != int.parse(cpf[9]) || dv2 != int.parse(cpf[10])) {
      return 'CPF inválido';
    }
    return null;
  }

  String? _validarCEP(String cep) {
    cep = cep.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (cep.isEmpty) return 'CEP é obrigatório';
    if (cep.length != 8) return 'CEP deve ter 8 dígitos';
    return null;
  }

  String? _validarEmail(String email) {
    email = email.trim();
    if (email.isEmpty) return 'E-mail é obrigatório';
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'E-mail inválido';
    return null;
  }

  String? _validarSenha(String senha) {
    if (senha.isEmpty) return 'Senha é obrigatória';
    if (senha.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
    if (!RegExp(r'[a-zA-Z]').hasMatch(senha))
      return 'Senha deve conter pelo menos uma letra';
    if (!RegExp(r'[0-9]').hasMatch(senha))
      return 'Senha deve conter pelo menos um número';
    return null;
  }

  String? _validarConfirmacaoSenha(String senha, String confirmacao) {
    if (confirmacao.isEmpty) return 'Confirmação de senha é obrigatória';
    if (senha != confirmacao) return 'As senhas não coincidem';
    return null;
  }

  void _fazerCadastro() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final erroNome = _validarNome(_nomeController.text);
    if (erroNome != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erroNome), backgroundColor: Colors.red));
      return;
    }

    final erroIdade = _validarIdade(_idadeController.text);
    if (erroIdade != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erroIdade), backgroundColor: Colors.red));
      return;
    }

    final erroCPF = _validarCPF(_cpfController.text);
    if (erroCPF != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erroCPF), backgroundColor: Colors.red));
      return;
    }

    final erroCEP = _validarCEP(_cepController.text);
    if (erroCEP != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erroCEP), backgroundColor: Colors.red));
      return;
    }

    final erroEmail = _validarEmail(_emailController.text);
    if (erroEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erroEmail), backgroundColor: Colors.red));
      return;
    }

    final erroSenha = _validarSenha(_senhaController.text);
    if (erroSenha != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erroSenha), backgroundColor: Colors.red));
      return;
    }

    final erroConfirmacao = _validarConfirmacaoSenha(
        _senhaController.text, _confirmarSenhaController.text);
    if (erroConfirmacao != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(erroConfirmacao), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final apiService = ApiService();
    final cpfLimpo = _cpfController.text.replaceAll(RegExp(r'[^\d]'), '');
    final cepLimpo = _cepController.text.replaceAll(RegExp(r'[^\d]'), '');

    bool sucesso = await apiService.registrar(
      nome: _nomeController.text.trim(),
      idade: int.parse(_idadeController.text.trim()),
      cpf: cpfLimpo,
      cep: cepLimpo,
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    setState(() => _isLoading = false);

    if (sucesso) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Conta criada com sucesso! Faça seu login.'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao criar conta. Verifique os dados.'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Criar Nova Conta'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add,
                    size: 60, color: Colors.blueAccent),
                const SizedBox(height: 20),
                const Text("Junte-se ao Pingu Wallet",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 30),

                TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        hintText: 'Ex: João da Silva',
                        border: OutlineInputBorder())),
                const SizedBox(height: 15),

                TextField(
                  controller: _idadeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Idade',
                      hintText: 'Ex: 25',
                      border: OutlineInputBorder(),
                      helperText: 'Somente números. Mínimo 18 anos.'),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))
                  ],
                  decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: 'Ex: 123.456.789-00 ou 12345678900',
                      border: OutlineInputBorder(),
                      helperText: 'Números e pontuação permitidos'),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'CEP',
                      hintText: 'Ex: 87300000',
                      border: OutlineInputBorder(),
                      helperText: 'Somente números. 8 dígitos.'),
                ),
                const SizedBox(height: 15),

                TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'Ex: seu.email@exemplo.com',
                        border: OutlineInputBorder())),
                const SizedBox(height: 15),

                // SENHA COM OLHINHO
                TextField(
                  controller: _senhaController,
                  obscureText: _obscureSenha,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    helperText: 'Mínimo 6 caracteres, letra e número',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureSenha
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureSenha = !_obscureSenha),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // CONFIRMAR SENHA COM OLHINHO
                TextField(
                  controller: _confirmarSenhaController,
                  obscureText: _obscureConfirmarSenha,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmarSenha
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          _obscureConfirmarSenha = !_obscureConfirmarSenha),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fazerCadastro,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Finalizar Cadastro",
                            style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
