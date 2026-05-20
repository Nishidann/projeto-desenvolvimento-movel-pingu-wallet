import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Necessário para o kIsWeb
import 'package:jwt_decoder/jwt_decoder.dart';

class ApiService {
  // Define o IP dinamicamente: localhost para Web, 10.0.2.2 para Emulador Android
  static const String baseUrl =
      kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

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
        final emailUsuario = data['usuario']['email'] ?? 'usuario@wallet.com';

        // Salva o token e o nome na memória segura do navegador/celular
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('nome_usuario', nomeUsuario);
        await prefs.setString('email_usuario', emailUsuario);

        return true; // Retorna sucesso para a tela fechar o loading
      } else {
        debugPrint('Falha no login. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Erro de rede ao tentar logar: $e');
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
      debugPrint('Erro de rede ao registrar: $e');
      return false;
    }
  }

  // ==========================
  // FUNÇÃO DE TRANSAÇÃO
  // ==========================
  Future<void> cadastrarTransacao(
      TransactionModel transacao, int usuarioId) async {
    final url = Uri.parse('$baseUrl/transacoes/adicionar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuarioId': usuarioId,
          'descricao': transacao.descricao,
          'valor': transacao.valor,
          'tipo': transacao.tipo,
          'categoria': transacao.categoria,
          'data_transacao': transacao.dataTransacao?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Erro ao salvar transação: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // ==========================
  // FUNÇÃO DE BUSCA DE TRANSAÇÕES (CORRIGIDA COM RECENTES)
  // ==========================
  Future<List<dynamic>> obterTransacoes(int usuarioId) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/transacoes/usuario/$usuarioId/todas'), // <--- ADICIONADO /recentes AQUI
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

  // ==========================
  // Para o app saber quem está logando
  // ==========================
  Future<int?> getUsuarioId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token != null && !JwtDecoder.isExpired(token)) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        return decodedToken['id'];
      }
    } catch (e) {
      debugPrint("Erro ao decodificar token: $e");
    }
    return null;
  }

  // ==========================
  // FUNÇÕES DE CATEGORIAS
  // ==========================
  Future<List<dynamic>> listarCategorias(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categorias/usuario/$usuarioId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Erro ao listar categorias: $e');
    }
    return [];
  }

  Future<bool> adicionarCategoria({
    required int usuarioId,
    required String nome,
    required String tipo,
    required String icone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categorias'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usuarioId': usuarioId, 'nome': nome, 'tipo': tipo, 'icone': icone}),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro ao adicionar categoria: $e');
      return false;
    }
  }

  Future<bool> editarCategoria({
    required int id,
    required String nome,
    required String icone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categorias/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome, 'icone': icone}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao editar categoria: $e');
      return false;
    }
  }

  Future<bool> deletarCategoria(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categorias/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao deletar categoria: $e');
      return false;
    }
  }
}
