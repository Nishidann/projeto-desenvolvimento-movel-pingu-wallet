import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Necessário para o kIsWeb

class ApiService {
  // Define o IP dinamicamente: 127.0.0.1 para Web, 10.0.2.2 para Emulador Android
  static const String baseUrl =
      kIsWeb ? 'http://127.0.0.1:3000' : 'http://10.0.2.2:3000';

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
        final token =
            data['token']; // Pega o token gigante que o Node.js enviou
        final nomeUsuario =
            data['usuario']['nome'] ?? 'Usuário'; // Extrai o nome do usuário

        // Salva o token e o nome na memória segura do navegador/celular
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('nome_usuario', nomeUsuario);

        return true; // Retorna sucesso para a tela fechar o loading
      } else {
        print('Falha no login. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      //ignore_for_file: avoid_print
      print('Erro de rede ao tentar logar: $e');
      return false;
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

      if (response.statusCode == 201) {
        // Salva o nome do usuário após registro bem-sucedido
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nome_usuario', nome);
        return true;
      }
      return false;
    } catch (e) {
      print('Erro de rede ao registrar: $e');
      return false;
    }
  }

  // ==========================
  // FUNÇÃO DE TRANSAÇÃO
  // ==========================
  Future<void> cadastrarTransacao(
      TransactionModel transacao, int usuarioId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transacoes/adicionar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioId': usuarioId,
        'descricao': transacao.descricao,
        'valor': transacao.valor,
        'tipo': transacao.tipo,
        'categoria': transacao.categoria,
        if (transacao.dataTransacao != null)
          'data_transacao': transacao.dataTransacao!.toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao salvar transação no backend.');
    }
  }

  // ==========================
  // FUNÇÃO DE BUSCA DE TRANSAÇÕES
  // ==========================
  Future<List<dynamic>> obterTransacoes(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transacoes/usuario/$usuarioId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar transações do servidor.');
    }
  }

  // ==========================
  // GASTOS POR CATEGORIA
  // ==========================
  Future<List<dynamic>> obterGastosPorCategoria(int usuarioId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transacoes/usuario/$usuarioId/gastos-por-categoria'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar gastos por categoria.');
    }
  }
}
