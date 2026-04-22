const express = require('express');
const { pool } = require('../db');
const { verificarToken } = require('../middleware/auth');

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Resumo
 *   description: Endpoints de resumo financeiro da conta
 */

/**
 * @swagger
 * /resumo:
 *   get:
 *     summary: Retorna o resumo financeiro do usuário autenticado
 *     tags: [Resumo]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Resumo financeiro com saldo total, receitas e despesas
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 saldo_total:
 *                   type: number
 *                   format: float
 *                   example: 1500.00
 *                   description: Saldo total (receitas - despesas)
 *                 total_receitas:
 *                   type: number
 *                   format: float
 *                   example: 3000.00
 *                 total_despesas:
 *                   type: number
 *                   format: float
 *                   example: 1500.00
 *                 total_transacoes:
 *                   type: integer
 *                   example: 12
 *                 ultima_atualizacao:
 *                   type: string
 *                   format: date-time
 *       401:
 *         description: Token não fornecido
 *       403:
 *         description: Token inválido
 *       500:
 *         description: Erro interno do servidor
 */
router.get('/', verificarToken, async (req, res) => {
  const usuarioId = req.usuario.id;

  try {
    const result = await pool.query(
      `SELECT
        COALESCE(SUM(CASE WHEN tipo = 'receita' THEN valor ELSE 0 END), 0) AS total_receitas,
        COALESCE(SUM(CASE WHEN tipo = 'despesa' THEN valor ELSE 0 END), 0) AS total_despesas,
        COUNT(*) AS total_transacoes
      FROM transacoes
      WHERE usuario_id = $1`,
      [usuarioId]
    );

    const { total_receitas, total_despesas, total_transacoes } = result.rows[0];

    const saldo_total = parseFloat(total_receitas) - parseFloat(total_despesas);

    res.json({
      saldo_total: parseFloat(saldo_total.toFixed(2)),
      total_receitas: parseFloat(parseFloat(total_receitas).toFixed(2)),
      total_despesas: parseFloat(parseFloat(total_despesas).toFixed(2)),
      total_transacoes: parseInt(total_transacoes),
      ultima_atualizacao: new Date().toISOString(),
    });
  } catch (err) {
    console.error('Erro ao buscar resumo:', err.message);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

/**
 * @swagger
 * /resumo/transacoes:
 *   get:
 *     summary: Lista as transações do usuário autenticado
 *     tags: [Resumo]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limite
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Número máximo de transações a retornar
 *     responses:
 *       200:
 *         description: Lista de transações
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                   descricao:
 *                     type: string
 *                   valor:
 *                     type: number
 *                   tipo:
 *                     type: string
 *                     enum: [receita, despesa]
 *                   data:
 *                     type: string
 *                     format: date-time
 *       401:
 *         description: Token não fornecido
 */
router.get('/transacoes', verificarToken, async (req, res) => {
  const usuarioId = req.usuario.id;
  const limite = parseInt(req.query.limite) || 10;

  try {
    const result = await pool.query(
      'SELECT id, descricao, valor, tipo, data FROM transacoes WHERE usuario_id = $1 ORDER BY data DESC LIMIT $2',
      [usuarioId, limite]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Erro ao listar transações:', err.message);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

/**
 * @swagger
 * /resumo/transacoes:
 *   post:
 *     summary: Adiciona uma nova transação
 *     tags: [Resumo]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - descricao
 *               - valor
 *               - tipo
 *             properties:
 *               descricao:
 *                 type: string
 *                 example: Salário de abril
 *               valor:
 *                 type: number
 *                 example: 3000.00
 *               tipo:
 *                 type: string
 *                 enum: [receita, despesa]
 *                 example: receita
 *     responses:
 *       201:
 *         description: Transação criada com sucesso
 *       400:
 *         description: Dados inválidos
 *       401:
 *         description: Token não fornecido
 */
router.post('/transacoes', verificarToken, async (req, res) => {
  const usuarioId = req.usuario.id;
  const { descricao, valor, tipo } = req.body;

  if (!descricao || !valor || !tipo) {
    return res.status(400).json({ erro: 'Descrição, valor e tipo são obrigatórios.' });
  }

  if (!['receita', 'despesa'].includes(tipo)) {
    return res.status(400).json({ erro: 'Tipo deve ser "receita" ou "despesa".' });
  }

  if (valor <= 0) {
    return res.status(400).json({ erro: 'Valor deve ser maior que zero.' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO transacoes (usuario_id, descricao, valor, tipo) VALUES ($1, $2, $3, $4) RETURNING *',
      [usuarioId, descricao, valor, tipo]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao adicionar transação:', err.message);
    res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
});

module.exports = router;
