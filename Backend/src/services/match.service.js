const pool = require('../config/db');

async function createMatch(creatorId, { fieldId, date, time, requiredPlayers, minPointRequired, pricePerPerson, positions }) {
  const errors = [];

  if (!fieldId)                                       errors.push('Saha seçilmedi.');
  if (!date)                                          errors.push('Tarih seçilmedi.');
  if (!time)                                          errors.push('Saat seçilmedi.');
  if (requiredPlayers == null || requiredPlayers < 0) errors.push('Eksik oyuncu sayısı geçersiz.');
  if (![1, 2, 3].includes(minPointRequired))          errors.push('Geçersiz yetenek seviyesi.');
  if (pricePerPerson == null || pricePerPerson < 0)   errors.push('Ücret geçersiz.');
  if (!positions || typeof positions !== 'object')    errors.push('Pozisyon bilgisi eksik.');

  if (errors.length > 0) return { status: 400, body: { errors } };

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const matchResult = await client.query(
      `INSERT INTO "Match"
         ("Creator_id", "Date", "Time", field_id, required_players, min_point_required, price_per_person, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'active')
       RETURNING match_id`,
      [creatorId, date, time, fieldId, requiredPlayers, minPointRequired, pricePerPerson],
    );
    const matchId = matchResult.rows[0].match_id;

    const positionMap = {
      kaleci:   'Kaleci',
      defans:   'Defans',
      ortaSaha: 'Orta Saha',
      forvet:   'Forvet',
    };

    for (const [key, label] of Object.entries(positionMap)) {
      const count = positions[key] ?? 0;
      if (count > 0) {
        await client.query(
          `INSERT INTO "Match_req" (match_id, position, req_count, filled_count)
           VALUES ($1, $2, $3, 0)`,
          [matchId, label, count],
        );
      }
    }

    await client.query('COMMIT');
    return { status: 201, body: { matchId } };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { createMatch };
