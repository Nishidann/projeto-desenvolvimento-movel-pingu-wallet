const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../db');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'pingu_wallet_super_secret_key_2024';

/**
 * @swagger
 * tags:
 *   name: Usuarios
 *   description: Endpoints de autenticação e registro de usuários
 */

/**
 * @swagger
 * /usuarios/registrar:
 *   post:
 *     summary: Registra um novo usuário
 *     tags: [Usuarios]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nome
 *               - email
 *               - senha
 *             properties:
 *               nome:
 *                 type: string
 *                 example: João Silva
 *               email:
 *                 type: string
 *                 example: joao@email.com
 *               senha:
 *                 type: string
 *                 example: senha123
 *               idade:
 *                 type: integer
 *                 example: 25
 *               cpf:
 *                 type: string
 *                 example: 123.456.789-00
 *               cep:
 *                 type: string
 *                 example: 01310-100
 *     responses:
 *       201:
 *         description: Usuário criado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 mensagem:
 *                   type: string
 *                   example: Usuário criado com sucesso!
 *                 id:
 *                   type: integer
 *                   example: 1
 *       400:
 *         description: E-mail já cadastrado ou dados inválidos
 *       500:
 *         description: Erro interno do servidor
 */
router.post('/registrar', async (req, res) => {
  const { nome, email, senha, idade, cpf, cep } = req.body;

  if (!nome || !email || !senha) {
    return res.status(400).json({ erro: 'Nome, e-mail e senha são obrigatórios.' });
  }

  try {
    const senhaHash = await bcrypt.hash(senha, 10);

    const result = await pool.query(
      'INSERT INTO usuarios (nome, email, senha, idade, cpf, cep) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id',
      [nome, email, senhaHash, idade || null, cpf || null, cep || null]
    );

    res.status(201).json({ mensagem: 'Usuário criado com sucesso!', id: result.rows[0].id });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ erro: 'E-mail já cadastrado.' });
    }
    console.error('Erro ao registrar usuário:', err.message);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

/**
 * @swagger
 * /usuarios/login:
 *   post:
 *     summary: Autentica um usuário e retorna um token JWT
 *     tags: [Usuarios]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - senha
 *             properties:
 *               email:
 *                 type: string
 *                 example: joao@email.com
 *               senha:
 *                 type: string
 *                 example: senha123
 *     responses:
 *       200:
 *         description: Login realizado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                   example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *                 usuario:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     nome:
 *                       type: string
 *                     email:
 *                       type: string
 *       401:
 *         description: E-mail ou senha inválidos
 *       500:
 *         description: Erro interno do servidor
 */
router.post('/login', async (req, res) => {
  const { email, senha } = req.body;

  if (!email || !senha) {
    return res.status(400).json({ erro: 'E-mail e senha são obrigatórios.' });
  }

  try {
    const result = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email]);

    if (result.rows.length === 0) {
      return res.status(401).json({ erro: 'E-mail ou senha inválidos.' });
    }

    const usuario = result.rows[0];
    const senhaValida = await bcrypt.compare(senha, usuario.senha);

    if (!senhaValida) {
      return res.status(401).json({ erro: 'E-mail ou senha inválidos.' });
    }

    const token = jwt.sign(
      { id: usuario.id, email: usuario.email, nome: usuario.nome },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email },
    });
  } catch (err) {
    console.error('Erro ao fazer login:', err.message);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

/**
 * @swagger
 * /usuarios/perfil:
 *   get:
 *     summary: Retorna o perfil do usuário autenticado
 *     tags: [Usuarios]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dados do perfil do usuário
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                 nome:
 *                   type: string
 *                 email:
 *                   type: string
 *                 idade:
 *                   type: integer
 *                 cpf:
 *                   type: string
 *                 cep:
 *                   type: string
 *       401:
 *         description: Token não fornecido
 *       403:
 *         description: Token inválido
 */
router.get('/perfil', require('../middleware/auth').verificarToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nome, email, idade, cpf, cep, criado_em FROM usuarios WHERE id = $1',
      [req.usuario.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao buscar perfil:', err.message);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

module.exports = router;
