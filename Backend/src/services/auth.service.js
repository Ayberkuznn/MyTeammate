const bcrypt = require('bcrypt');
const pool = require('../config/db');
const { sendOtpEmail, generateOtp } = require('../utils/mailer');
const { generateTokens } = require('../utils/jwt');

const ALLOWED_POSITIONS = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];
const ALLOWED_FEET      = ['Sağ', 'Sol', 'Her İkisi'];

function validateRegisterInput({ Name, Surname, Email, Password, confirmPassword,
  Phone_number, Birthday, City, District, Position, Foot }) {

  const errors = [];

  if (!Name?.trim())        errors.push('Ad zorunludur.');
  if (!Surname?.trim())     errors.push('Soyad zorunludur.');
  if (!City?.trim())        errors.push('İl zorunludur.');
  if (!District?.trim())    errors.push('İlçe zorunludur.');

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!Email?.trim())                      errors.push('E-posta zorunludur.');
  else if (!emailRegex.test(Email.trim())) errors.push('Geçerli bir e-posta adresi girin.');

  const phoneRegex = /^(\+90|0)?[5][0-9]{9}$/;
  if (!Phone_number?.trim())                        errors.push('Telefon numarası zorunludur.');
  else if (!phoneRegex.test(Phone_number.trim()))   errors.push('Geçerli bir telefon numarası girin.');

  if (!Birthday) {
    errors.push('Doğum tarihi zorunludur.');
  } else {
    const birth = new Date(Birthday);
    const age   = new Date().getFullYear() - birth.getFullYear();
    if (isNaN(birth.getTime()))      errors.push('Geçerli bir doğum tarihi girin.');
    else if (age < 10 || age > 100)  errors.push('Yaşınız 10 ile 100 arasında olmalıdır.');
  }

  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
  if (!Password)                           errors.push('Şifre zorunludur.');
  else if (!passwordRegex.test(Password))  errors.push('Şifre en az 8 karakter, bir büyük harf, bir küçük harf ve bir rakam içermelidir.');

  if (Password !== confirmPassword) errors.push('Şifreler eşleşmiyor.');

  if (!Position || !ALLOWED_POSITIONS.includes(Position)) errors.push('Geçersiz pozisyon.');
  if (!Foot     || !ALLOWED_FEET.includes(Foot))          errors.push('Geçersiz ayak tercihi.');

  return errors;
}

async function register(data) {
  const errors = validateRegisterInput(data);
  if (errors.length > 0) return { status: 400, body: { errors } };

  const cleanEmail = data.Email.trim().toLowerCase();
  const cleanPhone = data.Phone_number.trim();

  const existing = await pool.query(
    'SELECT user_id FROM "User" WHERE "Email" = $1 OR "Phone_number" = $2 LIMIT 1',
    [cleanEmail, cleanPhone]
  );
  if (existing.rows.length > 0) {
    return { status: 409, body: { error: 'Bu e-posta veya telefon numarası zaten kayıtlı.' } };
  }

  const hashedPassword = await bcrypt.hash(data.Password, 12);

  const result = await pool.query(
    `INSERT INTO "User" ("Name","Surname","Email","Password","Phone_number","Birthday","City","District","Position","Foot")
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
     RETURNING user_id, "Name", "Surname", "Email"`,
    [
      data.Name.trim(), data.Surname.trim(), cleanEmail, hashedPassword,
      cleanPhone, data.Birthday, data.City.trim(), data.District.trim(), data.Position, data.Foot,
    ]
  );

  const newUser = result.rows[0];
  const otp = generateOtp();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  await pool.query('DELETE FROM "Validation" WHERE user_id = $1', [newUser.user_id]);
  await pool.query(
    'INSERT INTO "Validation" (user_id, code, expires_at, is_used) VALUES ($1, $2, $3, false)',
    [newUser.user_id, otp, expiresAt]
  );

  let emailSent = true;
  try {
    await sendOtpEmail(cleanEmail, otp);
  } catch (mailErr) {
    console.error('OTP email error:', mailErr.message);
    emailSent = false;
  }

  return { status: 201, body: { message: 'Kayıt başarılı.', emailSent, user: newUser } };
}

async function verifyEmail({ email, code }) {
  if (!email?.trim() || !code?.trim()) {
    return { status: 400, body: { error: 'E-posta ve kod zorunludur.' } };
  }

  const userResult = await pool.query(
    'SELECT user_id FROM "User" WHERE "Email" = $1 LIMIT 1',
    [email.trim().toLowerCase()]
  );
  if (userResult.rows.length === 0) {
    return { status: 404, body: { error: 'Kullanıcı bulunamadı.' } };
  }

  const userId = userResult.rows[0].user_id;

  const validation = await pool.query(
    `SELECT * FROM "Validation"
     WHERE user_id = $1 AND code = $2 AND is_used = false AND expires_at > NOW()
     LIMIT 1`,
    [userId, code.trim()]
  );
  if (validation.rows.length === 0) {
    return { status: 400, body: { error: 'Kod hatalı veya süresi dolmuş.' } };
  }

  await pool.query('UPDATE "User" SET is_verified = true WHERE user_id = $1', [userId]);
  await pool.query('UPDATE "Validation" SET is_used = true WHERE user_id = $1', [userId]);

  return { status: 200, body: { message: 'E-posta doğrulandı.' } };
}

async function login({ Email, Password }) {
  if (!Email?.trim() || !Password) {
    return { status: 400, body: { error: 'E-posta ve şifre zorunludur.' } };
  }

  const result = await pool.query(
    'SELECT user_id, "Name", "Surname", "Email", "Password" FROM "User" WHERE "Email" = $1 LIMIT 1',
    [Email.trim().toLowerCase()]
  );
  if (result.rows.length === 0) {
    return { status: 401, body: { error: 'E-posta veya şifre hatalı.' } };
  }

  const user = result.rows[0];
  const passwordMatch = await bcrypt.compare(Password, user.Password);
  if (!passwordMatch) {
    return { status: 401, body: { error: 'E-posta veya şifre hatalı.' } };
  }

  const payload = { userId: user.user_id, email: user.Email };
  const { accessToken, refreshToken } = generateTokens(payload);

  return {
    status: 200,
    body: {
      accessToken,
      refreshToken,
      user: { userId: user.user_id, name: user.Name, surname: user.Surname, email: user.Email },
    },
  };
}

module.exports = { register, verifyEmail, login };
