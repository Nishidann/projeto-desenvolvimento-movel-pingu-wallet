import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // Importa o modelo que criamos

class ApiService {
  final String baseUrl = 'http://localhost:3000';

  Future<void> cadastrarUsuarioNoBanco(UserModel usuario) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()), // Usa o método toJson do modelo
      );

      if (response.statusCode == 201) {
        print('✅ Usuário ${usuario.name} sincronizado com sucesso!');
      } else {
        print('❌ Erro no Backend: ${response.body}');
      }
    } catch (e) {
      print('❌ Falha na conexão: $e');
    }
  }
}
