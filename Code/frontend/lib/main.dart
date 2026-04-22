import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importe as telas (ajuste os caminhos se tiver salvado a HomePage em outro lugar)
import 'pages/login/login_page.dart';
import 'pages/login/registro_page.dart';
import 'pages/home_page.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase removido para usarmos o nosso próprio Back-end Node.js!
  runApp(const PinguWallet());
}

class PinguWallet extends StatelessWidget {
  const PinguWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pingu Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      
      // O mapa de navegação do seu aplicativo
      initialRoute: '/', // Começa pela tela de checagem
      routes: {
        '/': (context) => const AuthCheck(),
        '/login': (context) => const LoginPage(),
        '/registro': (context) => const RegistroPage(), // <- ROTA NOVA
        '/home': (context) => const HomePage(),
      },
    );
  }
}

// ========================================================
// TELA DE LOGIN INTELIGENTE (Splash Screen / Auth Check)
// ========================================================
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _verificarToken();
  }

  void _verificarToken() async {
    // 1. Busca o token na memória do aparelho/navegador
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // Um pequeno delay opcional apenas para a tela não piscar agressivamente
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Decide para onde o usuário vai
    if (mounted) {
      if (token != null && token.isNotEmpty) {
        // Usuário já está logado! Vai direto para a Home.
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Não tem token? Vai para a tela de Login comum.
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto o app pensa (esses 500ms), mostramos uma tela azul com loading
    return const Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}