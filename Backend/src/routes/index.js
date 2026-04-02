const express = require('express');
const router = express.Router();



// test route
router.get('/', (req, res) => {
  res.json({ message: 'MyTeammate API' });
});


module.exports = router;
