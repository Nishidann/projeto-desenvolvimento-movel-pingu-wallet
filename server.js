const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

// Configuração do Banco de Dados
const pool = new Pool({
    user: 'admin',
    host: 'localhost',
    database: 'financas_db',
    password: 'admin',
    port: 5432,
});

// Inicialização da Tabela (Roda ao iniciar o servidor)
const initDB = async () => {
    const query = `
        CREATE TABLE IF NOT EXISTS transacoes (
            id SERIAL PRIMARY KEY,
            valor NUMERIC(10, 2) NOT NULL,
            tipo VARCHAR(10) CHECK (tipo IN ('receita', 'despesa')),
            descricao VARCHAR(255) NOT NULL,
            data DATE DEFAULT CURRENT_DATE,
            user_id INTEGER DEFAULT 1 -- Hardcoded para a Sprint 1
        );
    `;
    await pool.query(query);
    console.log('✅ Tabela de transações verificada/criada.');
};

initDB();

// ==========================
// ENDPOINTS DA SPRINT 1
// ==========================

// 1. Criar nova transação
app.post('/transacoes', async (req, res) => {
    const { valor, tipo, descricao } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO transacoes (valor, tipo, descricao) VALUES ($1, $2, $3) RETURNING *',
            [valor, tipo, descricao]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erro ao salvar transação' });
    }
});

// 2. Listar todas as transações
app.get('/transacoes', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM transacoes ORDER BY data DESC, id DESC');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erro ao buscar transações' });
    }
});

// 3. Resumo Financeiro (Saldo, Receitas, Despesas)
app.get('/resumo', async (req, res) => {
    try {
        const receitasResult = await pool.query("SELECT COALESCE(SUM(valor), 0) as total FROM transacoes WHERE tipo = 'receita'");
        const despesasResult = await pool.query("SELECT COALESCE(SUM(valor), 0) as total FROM transacoes WHERE tipo = 'despesa'");
        
        const receitas = parseFloat(receitasResult.rows[0].total);
        const despesas = parseFloat(despesasResult.rows[0].total);
        const saldo = receitas - despesas;

        res.json({ saldo, receitas, despesas });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Erro ao calcular resumo' });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`🚀 Servidor rodando na porta ${PORT}`);
});