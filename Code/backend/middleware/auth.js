const jwt = require('jsonwebtoken');

const verificarToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ erro: 'Token não fornecido. Acesso negado.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'pingu_wallet_super_secret_key_2024');
    req.usuario = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ erro: 'Token inválido ou expirado.' });
  }
};

module.exports = { verificarToken };
