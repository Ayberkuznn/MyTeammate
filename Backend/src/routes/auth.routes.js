const { Router } = require('express');
const authService = require('../services/auth.service');
const { requireAuth } = require('../middleware/auth.middleware');
const { verifyRefreshToken, generateTokens } = require('../utils/jwt');

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

router.post('/forgot-password', async (req, res) => {
  try {
    const { status, body } = await authService.forgotPassword(req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.post('/verify-reset-code', async (req, res) => {
  try {
    const { status, body } = await authService.verifyResetCode(req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Verify reset code error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.post('/reset-password', async (req, res) => {
  try {
    const { status, body } = await authService.resetPassword(req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.post('/change-password', requireAuth, async (req, res) => {
  try {
    const { status, body } = await authService.changePassword(req.user.userId, req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Change password error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.post('/refresh', (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ error: 'Refresh token gerekli.' });

  try {
    const payload = verifyRefreshToken(refreshToken);
    const { accessToken, refreshToken: newRefreshToken } = generateTokens({
      userId: payload.userId,
      email: payload.email,
    });
    res.json({ accessToken, refreshToken: newRefreshToken });
  } catch {
    res.status(401).json({ error: 'Geçersiz veya süresi dolmuş refresh token.' });
  }
});

module.exports = router;
