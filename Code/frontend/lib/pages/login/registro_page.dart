import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  // Controladores para capturar todos os campos
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cepController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false;

  void _fazerCadastro() async {
    // Validação básica para não enviar campos vazios
    if (_nomeController.text.isEmpty ||
        _idadeController.text.isEmpty ||
        _cpfController.text.isEmpty ||
        _cepController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = ApiService();
    bool sucesso = await apiService.registrar(
      nome: _nomeController.text.trim(),
      // Converte o texto da idade para número
      idade: int.tryParse(_idadeController.text.trim()) ?? 0, 
      cpf: _cpfController.text.trim(),
      cep: _cepController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (sucesso) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Faça seu login.'),
            backgroundColor: Colors.green,
          ),
        );
        // Volta para a tela de Login
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar conta. Verifique os dados.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.blueAccent),
                const SizedBox(height: 20),
                const Text(
                  "Junte-se ao Pingu Wallet",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Nome
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // Idade
                TextField(
                  controller: _idadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Idade', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // CPF
                TextField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CPF (somente números ou com pontuação)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // CEP
                TextField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CEP', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // E-mail
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // Senha
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 30),

                // Botão Cadastrar
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fazerCadastro,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Finalizar Cadastro", style: TextStyle(fontSize: 18)),
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