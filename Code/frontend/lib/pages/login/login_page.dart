import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Lado Esquerdo: Branding
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
          // Lado Direito: Login
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Bem-vindo de volta!",
                      style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () async {
                      print(
                          "Botão clicado! (Firebase desativado para teste de UI)");
                      //final user = await AuthService().signInWithGoogle();
                      //if (user != null) {
                      //print("Logado como: ${user.displayName}");
                      //}
                    },
                    icon: const Icon(Icons.login),
                    label: const Text("Entrar com Google"),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
