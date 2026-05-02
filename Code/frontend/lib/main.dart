import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importe as telas
import 'pages/login/login_page.dart';
import 'pages/login/registro_page.dart';
import 'pages/dashboard/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PinguWallet());
}

class PinguWallet extends StatelessWidget {
  const PinguWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pingu Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),

      // Começa diretamente na checagem de autenticação (AuthCheck)
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheck(),
        '/login': (context) => const LoginPage(),
        '/registro': (context) => const RegistroPage(),
        '/home': (context) => const DashboardPage(),
      },
    );
  }
}

// ========================================================
// TELA DE CHECAGEM DE AUTENTICAÇÃO
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E3A8A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.icecream, size: 80, color: Colors.white),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
