import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Necessário para o kIsWeb

class ApiService {
  // Define o IP dinamicamente: Localhost para Web (Firefox), 10.0.2.2 para Emulador Android
  static const String baseUrl = kIsWeb 
      ? 'http://localhost:3000' 
      : 'http://10.0.2.2:3000';

  // ==========================
  // FUNÇÃO DE LOGIN
  // ==========================
  Future<bool> login(String email, String senha) async {
    final url = Uri.parse('$baseUrl/usuarios/login');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']; // Pega o token gigante que o Node.js enviou
        
        // Salva o token na memória segura do navegador/celular
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        
        return true; // Retorna sucesso para a tela fechar o loading
      } else {
        print('Falha no login. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erro de rede ao tentar logar: $e');
      return false;
    }
  }

  // ==========================
  // FUNÇÃO DE RESUMO FINANCEIRO
  // ==========================
  Future<Map<String, dynamic>?> buscarResumo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return null;

    final url = Uri.parse('$baseUrl/resumo');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Falha ao buscar resumo. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro de rede ao buscar resumo: $e');
      return null;
    }
  }

  // ==========================
  // FUNÇÃO DE REGISTRO
  // ==========================
  Future<bool> registrar({
    required String nome,
    required int idade,
    required String cpf,
    required String cep,
    required String email,
    required String senha,
  }) async {
    final url = Uri.parse('$baseUrl/usuarios/registrar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'idade': idade,
          'cpf': cpf,
          'cep': cep,
          'email': email,
          'senha': senha,
        }),
      );

      return response.statusCode == 201; // 201 Significa "Criado com sucesso"
    } catch (e) {
      print('Erro de rede ao registrar: $e');
      return false;
    }
  }
}