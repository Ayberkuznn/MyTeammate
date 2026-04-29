const { Router } = require('express');
const authService = require('../services/auth.service');

const router = Router();

router.post('/register', async (req, res) => {
  try {
    const { status, body } = await authService.register(req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Sunucu hatası. Lütfen tekrar deneyin.' });
  }
});

router.post('/verify-email', async (req, res) => {
  try {
    const { status, body } = await authService.verifyEmail(req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Verify email error:', err);
    res.status(500).json({ error: 'Sunucu hatası. Lütfen tekrar deneyin.' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { status, body } = await authService.login(req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Sunucu hatası. Lütfen tekrar deneyin.' });
  }
});

module.exports = router;
