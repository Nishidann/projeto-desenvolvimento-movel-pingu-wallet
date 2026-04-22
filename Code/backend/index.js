require('dotenv').config();
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

const { initDb } = require('./db');
const usuariosRouter = require('./routes/usuarios');
const resumoRouter = require('./routes/resumo');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Configuração do Swagger
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Pingu Wallet API',
      version: '1.0.0',
      description: `
## API do Pingu Wallet 🐧

Sistema de gestão financeira pessoal.

### Autenticação
Use o endpoint \`/usuarios/login\` para obter um token JWT.
Em seguida, clique em **Authorize** e insira: \`Bearer <seu_token>\`
      `,
      contact: {
        name: 'Equipe Pingu Wallet',
      },
    },
    servers: [
      { url: 'http://localhost:3000', description: 'Servidor local' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Insira o token JWT obtido no login',
        },
      },
    },
  },
  apis: ['./routes/*.js'],
};

const swaggerDocs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs, {
  customCss: '.swagger-ui .topbar { background-color: #1565C0; }',
  customSiteTitle: 'Pingu Wallet - API Docs',
}));

// Rotas
app.use('/usuarios', usuariosRouter);
app.use('/resumo', resumoRouter);

// Rota raiz
app.get('/', (req, res) => {
  res.json({
    message: '🐧 Pingu Wallet API está rodando!',
    docs: `http://localhost:${PORT}/api-docs`,
    endpoints: {
      usuarios: '/usuarios/registrar | /usuarios/login | /usuarios/perfil',
      resumo: '/resumo | /resumo/transacoes',
    },
  });
});

// Inicializa o banco e sobe o servidor
initDb().then(() => {
  app.listen(PORT, () => {
    console.log(`\n🐧 Pingu Wallet API rodando em http://localhost:${PORT}`);
    console.log(`📚 Swagger disponível em http://localhost:${PORT}/api-docs\n`);
  });
});
