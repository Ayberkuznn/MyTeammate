const pool = require('../config/db');

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^\d{2}:\d{2}$/;

async function createMatch(creatorId, { fieldId, date, time, requiredPlayers, minPointRequired, pricePerPerson, positions }) {
  const errors = [];

  // --- temel alan kontrolleri ---
  if (!fieldId || !Number.isInteger(Number(fieldId)) || Number(fieldId) < 1)
    errors.push('Geçersiz saha.');

  if (!date || !DATE_RE.test(date) || isNaN(Date.parse(date)))
    errors.push('Geçersiz tarih formatı (YYYY-MM-DD bekleniyor).');
  else if (new Date(date) < new Date(new Date().toISOString().slice(0, 10)))
    errors.push('Geçmiş bir tarihe maç oluşturulamaz.');

  if (!time || !TIME_RE.test(time))
    errors.push('Geçersiz saat formatı (HH:MM bekleniyor).');

  if (!Number.isInteger(requiredPlayers) || requiredPlayers < 0)
    errors.push('Eksik oyuncu sayısı geçersiz.');

  if (![1, 2, 3].includes(minPointRequired))
    errors.push('Geçersiz yetenek seviyesi.');

  if (typeof pricePerPerson !== 'number' || pricePerPerson < 0)
    errors.push('Ücret geçersiz.');

  // --- pozisyon kontrolleri ---
  if (!positions || typeof positions !== 'object' || Array.isArray(positions)) {
    errors.push('Pozisyon bilgisi eksik.');
  } else {
    const posKeys = ['kaleci', 'defans', 'ortaSaha', 'forvet'];
    for (const key of posKeys) {
      const val = positions[key] ?? 0;
      if (!Number.isInteger(val) || val < 0)
        errors.push(`Geçersiz pozisyon değeri: ${key}.`);
    }

    const posTotal = posKeys.reduce((sum, k) => sum + (positions[k] ?? 0), 0);
    if (errors.length === 0 && posTotal !== requiredPlayers)
      errors.push('Pozisyon toplamı eksik oyuncu sayısıyla eşleşmiyor.');
  }

  if (errors.length > 0) return { status: 400, body: { errors } };

  // --- saha varlık kontrolü ---
  const fieldCheck = await pool.query(
    `SELECT field_id FROM "Field" WHERE field_id = $1`,
    [Number(fieldId)],
  );
  if (fieldCheck.rows.length === 0)
    return { status: 404, body: { error: 'Saha bulunamadı.' } };

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
