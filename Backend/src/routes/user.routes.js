const { Router } = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const userService = require('../services/user.service');

const router = Router();

router.get('/profile', requireAuth, async (req, res) => {
  try {
    const { status, body } = await userService.getProfile(req.user.userId);
    res.status(status).json(body);
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

module.exports = router;
