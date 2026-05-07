const { Router } = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const fieldService = require('../services/field.service');

const router = Router();

// GET /api/field?city=İstanbul&district=Kadıköy
router.get('/', requireAuth, async (req, res) => {
  try {
    const { city, district } = req.query;
    const { status, body } = await fieldService.getFields({ city, district });
    res.status(status).json(body);
  } catch (err) {
    console.error('Field list error:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});

module.exports = router;
