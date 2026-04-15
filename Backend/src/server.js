require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const app = express();
const PORT = process.env.PORT || 3000;

// DB bağlantısı (pg Pool)
const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

pool.query('SELECT 1')
  .then(() => console.log('Database connected'))
  .catch((err) => console.error('Database connection failed:', err.message));

// Middleware
app.use(express.json());

// ─── Sabit Listeler ───────────────────────────────────────────────────────────

const ALLOWED_POSITIONS = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];
const ALLOWED_FEET      = ['Sağ', 'Sol', 'Her İkisi'];

// ─── Yardımcı: Input Doğrulama ────────────────────────────────────────────────

function validateRegisterInput({ Name, Surname, Email, Password, confirmPassword,
  Phone_number, Birthday, City, District, Position, Foot }) {

  const errors = [];

  if (!Name?.trim())        errors.push('Ad zorunludur.');
  if (!Surname?.trim())     errors.push('Soyad zorunludur.');
  if (!City?.trim())        errors.push('İl zorunludur.');
  if (!District?.trim())    errors.push('İlçe zorunludur.');

  // E-posta formatı
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!Email?.trim())             errors.push('E-posta zorunludur.');
  else if (!emailRegex.test(Email.trim())) errors.push('Geçerli bir e-posta adresi girin.');

  // Telefon: başında opsiyonel +90, ardından 10 rakam
  const phoneRegex = /^(\+90|0)?[5][0-9]{9}$/;
  if (!Phone_number?.trim())             errors.push('Telefon numarası zorunludur.');
  else if (!phoneRegex.test(Phone_number.trim())) errors.push('Geçerli bir telefon numarası girin.');

  // Doğum tarihi
  if (!Birthday) errors.push('Doğum tarihi zorunludur.');
  else {
    const birth = new Date(Birthday);
    const today = new Date();
    const age   = today.getFullYear() - birth.getFullYear();
    if (isNaN(birth.getTime()))  errors.push('Geçerli bir doğum tarihi girin.');
    else if (age < 10 || age > 100) errors.push('Yaşınız 10 ile 100 arasında olmalıdır.');
  }

  // Şifre: en az 8 karakter, büyük harf, küçük harf, rakam
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
  if (!Password)                          errors.push('Şifre zorunludur.');
  else if (!passwordRegex.test(Password)) errors.push('Şifre en az 8 karakter, bir büyük harf, bir küçük harf ve bir rakam içermelidir.');

  if (Password !== confirmPassword) errors.push('Şifreler eşleşmiyor.');

  // Whitelist kontrolü — enum dışı değer injection'ı engeller
  if (!Position || !ALLOWED_POSITIONS.includes(Position)) errors.push('Geçersiz pozisyon.');
  if (!Foot     || !ALLOWED_FEET.includes(Foot))          errors.push('Geçersiz ayak tercihi.');

  return errors;
}

// ─── Endpoints ────────────────────────────────────────────────────────────────

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  const {
    Name, Surname, Email, Password, confirmPassword,
    Phone_number, Birthday, City, District, Position, Foot,
  } = req.body;

  // 1. Girdi doğrulama
  const errors = validateRegisterInput(req.body);
  if (errors.length > 0) {
    return res.status(400).json({ errors });
  }

  const cleanEmail = Email.trim().toLowerCase();
  const cleanPhone = Phone_number.trim();

  try {
    // 2. Tekrar eden e-posta / telefon kontrolü — parametreli sorgu, SQL injection yok
    const existing = await pool.query(
      'SELECT user_id FROM "User" WHERE "Email" = $1 OR "Phone_number" = $2 LIMIT 1',
      [cleanEmail, cleanPhone]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Bu e-posta veya telefon numarası zaten kayıtlı.' });
    }

    // 3. Şifreyi hashle (salt rounds: 12)
    const hashedPassword = await bcrypt.hash(Password, 12);

    // 4. Kayıt
    const result = await pool.query(
      `INSERT INTO "User" ("Name","Surname","Email","Password","Phone_number","Birthday","City","District","Position","Foot")
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING user_id, "Name", "Surname", "Email"`,
      [
        Name.trim(), Surname.trim(), cleanEmail, hashedPassword,
        cleanPhone, Birthday, City.trim(), District.trim(), Position, Foot,
      ]
    );

    // 5. Yanıtta şifre hash'i veya hassas alan döndürülmez
    return res.status(201).json({
      message: 'Kayıt başarılı.',
      user: result.rows[0],
    });

  } catch (err) {
    // DB hatası detayı kullanıcıya sızdırılmaz
    console.error('Register error:', err);
    return res.status(500).json({ error: 'Sunucu hatası. Lütfen tekrar deneyin.' });
  }
});

// ─────────────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});