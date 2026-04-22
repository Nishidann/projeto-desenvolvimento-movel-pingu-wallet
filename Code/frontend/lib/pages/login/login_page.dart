import 'package:flutter/material.dart';
// Lembre-se de importar o arquivo correto do serviço que criamos
import '../../services/api_service.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para capturar o que o usuário digita
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variável para controlar o estado do botão (girando ou não)
  bool _isLoading = false;

  // Função que conversa com o Node.js
  void _fazerLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Inicia a animação de carregamento
    });

    final apiService = ApiService();
    bool sucesso = await apiService.login(
      _emailController.text.trim(), 
      _passwordController.text,
    );

    setState(() {
      _isLoading = false; // Para a animação
    });

    if (sucesso) {
      // Se a API retornar o Token, vamos para a tela principal!
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail ou senha inválidos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Lado Esquerdo: Branding (Mantido intacto!)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.blueAccent,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 80, color: Colors.white),
                  SizedBox(height: 20),
                  Text("PINGU WALLET",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Lado Direito: Formulário de Login da API
          Expanded(
            flex: 1,
            child: Center(
              child: ConstrainedBox(
                // Limita a largura do formulário para não ficar gigante na tela do Firefox
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Bem-vindo!",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Campo de E-mail
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo de Senha
                      TextField(
                        controller: _passwordController,
                        obscureText: true, // Esconde a senha
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Botão de Login
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _fazerLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Entrar", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Link para cadastro (Para a próxima etapa do projeto)
                      TextButton(
                        onPressed: () {
                          // Navega para a tela de registro
                          Navigator.pushNamed(context, '/registro');
                        },
                        child: const Text("Ainda não tem conta? Cadastre-se aqui."),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}