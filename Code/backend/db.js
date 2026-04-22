const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'admin',
  database: process.env.DB_NAME || 'users_db',
});

// Cria as tabelas necessárias ao iniciar
const initDb = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS usuarios (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        senha VARCHAR(255) NOT NULL,
        idade INTEGER,
        cpf VARCHAR(14),
        cep VARCHAR(9),
        criado_em TIMESTAMP DEFAULT NOW()
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS transacoes (
        id SERIAL PRIMARY KEY,
        usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
        descricao VARCHAR(255) NOT NULL,
        valor DECIMAL(10, 2) NOT NULL,
        tipo VARCHAR(10) CHECK (tipo IN ('receita', 'despesa')) NOT NULL,
        data TIMESTAMP DEFAULT NOW()
      )
    `);

    console.log('Banco de dados inicializado com sucesso!');
  } catch (err) {
    console.error('Erro ao inicializar o banco:', err.message);
  }
};

module.exports = { pool, initDb };
