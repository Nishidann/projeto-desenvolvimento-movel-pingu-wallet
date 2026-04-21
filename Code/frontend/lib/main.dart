import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nota: O Firebase precisa do arquivo google-services.json para funcionar
  // Se for testar sem Firebase agora, comente a linha abaixo
  //await Firebase.initializeApp();
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
      home: const LoginPage(), // Sua tela inicial
    );
  }
}
