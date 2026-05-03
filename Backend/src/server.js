require('dotenv').config();
const express = require('express');
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/api',    (req, res) => res.json({ message: 'MyTeammate API' }));

app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);

if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app;
