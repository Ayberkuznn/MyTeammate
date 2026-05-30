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

async function getMatches({ city, district } = {}) {
  const cleanCity     = typeof city     === 'string' ? city.trim()     : null;
  const cleanDistrict = typeof district === 'string' ? district.trim() : null;

  const params = [];
  const conditions = [
    `m.status = 'active'`,
    `(m."Date" + m."Time") > NOW() AT TIME ZONE 'Europe/Istanbul'`,
  ];

  if (cleanCity) {
    params.push(cleanCity);
    conditions.push(`f.city = $${params.length}`);
  }
  if (cleanDistrict) {
    params.push(cleanDistrict);
    conditions.push(`f.district = $${params.length}`);
  }

  const where = conditions.join(' AND ');

  const result = await pool.query(
    `SELECT
       m.match_id,
       f.field_name,
       f.city,
       f.district,
       TO_CHAR(m."Date", 'YYYY-MM-DD')        AS date,
       TO_CHAR(m."Time", 'HH24:MI')           AS time,
       m.required_players,
       COALESCE(SUM(mr.filled_count), 0)::int AS filled_players,
       m.min_point_required,
       m.price_per_person,
       m.status
     FROM "Match" m
     JOIN "Field" f ON m.field_id = f.field_id
     LEFT JOIN "Match_req" mr ON m.match_id = mr.match_id
     WHERE ${where}
     GROUP BY m.match_id, f.field_name, f.city, f.district
     ORDER BY m."Date" ASC, m."Time" ASC`,
    params,
  );

  const skillMap = { 1: 'Başlangıç', 2: 'Orta Seviye', 3: 'İleri Seviye' };

  return {
    status: 200,
    body: result.rows.map((r) => ({
      matchId:        r.match_id,
      fieldName:      r.field_name,
      city:           r.city,
      district:       r.district,
      date:           r.date,
      time:           r.time,
      requiredPlayers: r.required_players,
      filledPlayers:  r.filled_players,
      skillLevel:     skillMap[r.min_point_required] ?? 'Orta Seviye',
      pricePerPerson: Number(r.price_per_person),
    })),
  };
}

async function getMatchById(matchId) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1) {
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };
  }

  const [matchResult, posResult] = await Promise.all([
    pool.query(
      `SELECT
         m.match_id,
         f.field_name,
         f.city,
         f.district,
         TO_CHAR(m."Date", 'YYYY-MM-DD')        AS date,
         TO_CHAR(m."Time", 'HH24:MI')           AS time,
         m.required_players,
         COALESCE(SUM(mr.filled_count), 0)::int AS filled_players,
         m.min_point_required,
         m.price_per_person,
         m.status,
         u."Name"                               AS creator_name,
         u."Surname"                            AS creator_surname,
         u.avg_rating                           AS creator_rating
       FROM "Match" m
       JOIN "Field" f  ON m.field_id     = f.field_id
       JOIN "User"  u  ON m."Creator_id" = u.user_id
       LEFT JOIN "Match_req" mr ON m.match_id = mr.match_id
       WHERE m.match_id = $1
       GROUP BY m.match_id, f.field_name, f.city, f.district,
                u."Name", u."Surname", u.avg_rating`,
      [id],
    ),
    pool.query(
      `SELECT position, req_count, filled_count
       FROM "Match_req"
       WHERE match_id = $1
       ORDER BY log_id`,
      [id],
    ),
  ]);

  if (matchResult.rows.length === 0) {
    return { status: 404, body: { error: 'Maç bulunamadı.' } };
  }

  const r = matchResult.rows[0];
  const skillMap = { 1: 'Başlangıç', 2: 'Orta Seviye', 3: 'İleri Seviye' };

  const positions = posResult.rows.map((p) => ({
    position:  p.position,
    required:  p.req_count,
    filled:    p.filled_count,
    available: p.req_count - p.filled_count,
  }));

  return {
    status: 200,
    body: {
      matchId:         r.match_id,
      fieldName:       r.field_name,
      city:            r.city,
      district:        r.district,
      date:            r.date,
      time:            r.time,
      requiredPlayers: r.required_players,
      filledPlayers:   r.filled_players,
      skillLevel:      skillMap[r.min_point_required] ?? 'Orta Seviye',
      pricePerPerson:  Number(r.price_per_person),
      creatorName:     `${r.creator_name} ${r.creator_surname}`.toUpperCase(),
      creatorRating:   parseFloat(r.creator_rating) || 0,
      positions,
    },
  };
}

async function joinMatch(userId, matchId) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1) {
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const matchRow = await client.query(
      `SELECT status, required_players,
              COALESCE(SUM(mr.filled_count), 0)::int AS filled
       FROM "Match" m
       LEFT JOIN "Match_req" mr ON m.match_id = mr.match_id
       WHERE m.match_id = $1
       GROUP BY m.match_id`,
      [id],
    );
    if (matchRow.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 404, body: { error: 'Maç bulunamadı.' } };
    }
    const { status, required_players, filled } = matchRow.rows[0];
    if (status !== 'active') {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Bu maça katılım mümkün değil.' } };
    }
    if (filled >= required_players) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Maç kadrosu dolu.' } };
    }

    const existing = await client.query(
      `SELECT log_id FROM "Position_request"
       WHERE match_id = $1 AND user_id = $2 AND status != 2`,
      [id, userId],
    );
    if (existing.rows.length > 0) {
      await client.query('ROLLBACK');
      return { status: 409, body: { error: 'Bu maça zaten katılım isteği gönderildi.' } };
    }

    await client.query(
      `INSERT INTO "Position_request" (match_id, user_id, position_applied, status)
       VALUES ($1, $2, 'Belirsiz', 0)`,
      [id, userId],
    );

    await client.query('COMMIT');
    return { status: 200, body: { message: 'Katılım isteği başarıyla gönderildi.' } };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { createMatch, getMatches, getMatchById, joinMatch };
