const { Router } = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const matchService = require('../services/match.service');

const router = Router();

router.get('/', requireAuth, async (req, res) => {
  try {
    const { city, district } = req.query;
    const { status, body } = await matchService.getMatches({ city, district });
    res.status(status).json(body);
  } catch (err) {
    console.error('Get matches error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.get('/:id', requireAuth, async (req, res) => {
  try {
    const { status, body } = await matchService.getMatchById(req.params.id);
    res.status(status).json(body);
  } catch (err) {
    console.error('Get match error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.post('/:id/join', requireAuth, async (req, res) => {
  try {
    const { status, body } = await matchService.joinMatch(req.user.userId, req.params.id);
    res.status(status).json(body);
  } catch (err) {
    console.error('Join match error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

router.post('/', requireAuth, async (req, res) => {
  try {
    const { status, body } = await matchService.createMatch(req.user.userId, req.body);
    res.status(status).json(body);
  } catch (err) {
    console.error('Create match error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

module.exports = router;
