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

module.exports = { getProfile };
