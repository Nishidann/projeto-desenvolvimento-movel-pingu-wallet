const express = require('express');
const pool = require('./db');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger');

const app = express();
app.use(express.json());

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// rota teste
app.get('/', (req, res) => {
  res.send('API funcionando!');
});

// criar usuário
app.post('/users', async (req, res) => {
  const { name, email } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).send('Erro ao criar usuário');
  }
});

// listar usuários
app.get('/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users');
    res.json(result.rows);
  } catch (err) {
    res.status(500).send('Erro ao buscar usuários');
  }
});

app.listen(3000, () => {
  console.log('Servidor rodando em http://localhost:3000');
});