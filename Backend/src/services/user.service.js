const pool = require('../config/db');

async function getProfile(userId) {
  const result = await pool.query(
    `SELECT "Name", "Surname", "City", "District", "Position", "Foot", "Skill_level",
            avg_rating, "Penalty_score", total_match, profile_photo
     FROM "User"
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (result.rows.length === 0) {
    return { status: 404, body: { error: 'Kullanıcı bulunamadı.' } };
  }

  const u = result.rows[0];
  return {
    status: 200,
    body: {
      name:         u.Name,
      surname:      u.Surname,
      city:         u.City,
      district:     u.District,
      position:     u.Position,
      foot:         u.Foot,
      skillLevel:   u.Skill_level,
      avgRating:    parseFloat(u.avg_rating) || 0,
      penaltyScore: u.Penalty_score ?? 0,
      totalMatch:   u.total_match ?? 0,
      profilePhoto: u.profile_photo ?? null,
    },
  };
}

const ALLOWED_POSITIONS   = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];
const ALLOWED_FEET        = ['Sağ', 'Sol', 'Her İkisi'];
const ALLOWED_SKILL_LEVELS = ['Başlangıç', 'Orta Seviye', 'İleri Seviye'];

async function updateProfile(userId, { City, District, Position, Foot, Skill_level }) {
  const errors = [];

  if (!City?.trim())     errors.push('İl zorunludur.');
  if (!District?.trim()) errors.push('İlçe zorunludur.');
  if (!Position || !ALLOWED_POSITIONS.includes(Position))       errors.push('Geçersiz pozisyon.');
  if (!Foot     || !ALLOWED_FEET.includes(Foot))                errors.push('Geçersiz ayak tercihi.');
  if (!Skill_level || !ALLOWED_SKILL_LEVELS.includes(Skill_level)) errors.push('Geçersiz yetenek seviyesi.');

  if (errors.length > 0) return { status: 400, body: { errors } };

  await pool.query(
    `UPDATE "User"
     SET "City" = $1, "District" = $2, "Position" = $3, "Foot" = $4, "Skill_level" = $5
     WHERE user_id = $6`,
    [City.trim(), District.trim(), Position, Foot, Skill_level, userId]
  );

  return { status: 200, body: { message: 'Profil güncellendi.' } };
}

async function updateFcmToken(userId, { fcmToken }) {
  if (!fcmToken?.trim()) {
    return { status: 400, body: { error: 'fcmToken zorunludur.' } };
  }

  const token = fcmToken.trim();
  // Aynı token başka bir kullanıcıda kayıtlıysa temizle
  await pool.query('UPDATE "User" SET fcm_token = NULL WHERE fcm_token = $1 AND user_id != $2', [token, userId]);
  await pool.query('UPDATE "User" SET fcm_token = $1 WHERE user_id = $2', [token, userId]);

  return { status: 200, body: { message: 'Bildirim token\'ı kaydedildi.' } };
}

async function clearFcmToken(userId) {
  await pool.query('UPDATE "User" SET fcm_token = NULL WHERE user_id = $1', [userId]);
  return { status: 200, body: { message: 'Oturum kapatıldı.' } };
}

module.exports = { getProfile, updateProfile, updateFcmToken, clearFcmToken };
