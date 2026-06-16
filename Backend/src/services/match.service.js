const pool = require('../config/db');
const { sendPushToUser } = require('../utils/push');

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^\d{2}:\d{2}$/;

async function createMatch(creatorId, { fieldId, date, time, requiredPlayers, minPointRequired, pricePerPerson, positions }) {
  const errors = [];

  if (!fieldId || !Number.isInteger(Number(fieldId)) || Number(fieldId) < 1)
    errors.push('Geçersiz saha.');

  if (!date || !DATE_RE.test(date) || isNaN(Date.parse(date)))
    errors.push('Geçersiz tarih formatı (YYYY-MM-DD bekleniyor).');
  else if (time && TIME_RE.test(time)) {
    // Kullanıcı saatini Istanbul local olarak değerlendir; UTC+3 sabit offset ile dönüştür
    const [y, mo, d] = date.split('-').map(Number);
    const [h, mi] = time.split(':').map(Number);
    const matchUtcMs = Date.UTC(y, mo - 1, d, h, mi) - 3 * 60 * 60 * 1000;
    if (matchUtcMs <= Date.now())
      errors.push('Geçmiş bir tarih/saate maç oluşturulamaz.');
  } else if (new Date(date) < new Date(new Date().toISOString().slice(0, 10))) {
    errors.push('Geçmiş bir tarihe maç oluşturulamaz.');
  }

  if (!time || !TIME_RE.test(time))
    errors.push('Geçersiz saat formatı (HH:MM bekleniyor).');

  if (!Number.isInteger(requiredPlayers) || requiredPlayers < 0)
    errors.push('Eksik oyuncu sayısı geçersiz.');

  if (![1, 2, 3].includes(minPointRequired))
    errors.push('Geçersiz yetenek seviyesi.');

  if (typeof pricePerPerson !== 'number' || pricePerPerson < 0)
    errors.push('Ücret geçersiz.');

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
       TO_CHAR(m."Date", 'YYYY-MM-DD') AS date,
       TO_CHAR(m."Time", 'HH24:MI')    AS time,
       m.required_players,
       (SELECT COUNT(*) FROM match_participants mp WHERE mp.match_id = m.match_id)::int AS filled_players,
       m.min_point_required,
       m.price_per_person,
       m.status,
       f."locationX"                   AS lat,
       f."locationY"                   AS lng
     FROM "Match" m
     JOIN "Field" f ON m.field_id = f.field_id
     WHERE ${where}
     ORDER BY m."Date" ASC, m."Time" ASC`,
    params,
  );

  const skillMap = { 1: 'Başlangıç', 2: 'Orta Seviye', 3: 'İleri Seviye' };

  return {
    status: 200,
    body: result.rows.map((r) => ({
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
      lat:             r.lat != null ? Number(r.lat) : null,
      lng:             r.lng != null ? Number(r.lng) : null,
    })),
  };
}

async function getMatchById(matchId) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };

  const [matchResult, posResult] = await Promise.all([
    pool.query(
      `SELECT
         m.match_id,
         f.field_name,
         f.city,
         f.district,
         TO_CHAR(m."Date", 'YYYY-MM-DD') AS date,
         TO_CHAR(m."Time", 'HH24:MI')    AS time,
         m.required_players,
         (SELECT COUNT(*) FROM match_participants mp WHERE mp.match_id = m.match_id)::int AS filled_players,
         m.min_point_required,
         m.price_per_person,
         m.status,
         u."Name"     AS creator_name,
         u."Surname"  AS creator_surname,
         u.avg_rating AS creator_rating
       FROM "Match" m
       JOIN "Field" f ON m.field_id     = f.field_id
       JOIN "User"  u ON m."Creator_id" = u.user_id
       WHERE m.match_id = $1`,
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

  if (matchResult.rows.length === 0)
    return { status: 404, body: { error: 'Maç bulunamadı.' } };

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

async function joinMatch(userId, matchId, position) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };

  if (!position || typeof position !== 'string' || !position.trim())
    return { status: 400, body: { error: 'Pozisyon seçimi zorunludur.' } };

  const cleanPosition = position.trim();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const matchRow = await client.query(
      `SELECT status, required_players, "Creator_id" AS creator_id FROM "Match" WHERE match_id = $1`,
      [id],
    );
    if (matchRow.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 404, body: { error: 'Maç bulunamadı.' } };
    }

    const { status, required_players, creator_id } = matchRow.rows[0];
    if (status !== 'active') {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Bu maça katılım mümkün değil.' } };
    }

    const posCheck = await client.query(
      `SELECT req_count, filled_count FROM "Match_req" WHERE match_id = $1 AND position = $2`,
      [id, cleanPosition],
    );
    if (posCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Seçilen pozisyon bu maçta mevcut değil.' } };
    }
    if (posCheck.rows[0].filled_count >= posCheck.rows[0].req_count) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Bu pozisyon dolu.' } };
    }

    const countRow = await client.query(
      `SELECT COUNT(*) AS cnt FROM match_participants WHERE match_id = $1`,
      [id],
    );
    if (parseInt(countRow.rows[0].cnt) >= required_players) {
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
       VALUES ($1, $2, $3, 0)`,
      [id, userId, cleanPosition],
    );

    await client.query('COMMIT');

    sendPushToUser(
      creator_id,
      'Yeni katılım isteği',
      'Maçınıza yeni bir katılım isteği gönderildi.',
      { type: 'match_request', matchId: String(id) },
    );

    return { status: 200, body: { message: 'Katılım isteği başarıyla gönderildi.' } };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function getMatchRequests(userId) {
  const result = await pool.query(
    `SELECT
       pr.log_id                        AS request_id,
       pr.match_id,
       pr.status,
       pr.applied_at,
       u."Name"                         AS user_name,
       u."Surname"                      AS user_surname,
       u.avg_rating                     AS user_rating,
       f.field_name,
       TO_CHAR(m."Date", 'YYYY-MM-DD')  AS match_date,
       TO_CHAR(m."Time", 'HH24:MI')     AS match_time
     FROM "Position_request" pr
     JOIN "Match" m ON pr.match_id = m.match_id
     JOIN "User"  u ON pr.user_id  = u.user_id
     JOIN "Field" f ON m.field_id  = f.field_id
     WHERE m."Creator_id" = $1
       AND (m."Date" + m."Time") > NOW() AT TIME ZONE 'Europe/Istanbul'
     ORDER BY pr.applied_at DESC`,
    [userId],
  );

  return {
    status: 200,
    body: result.rows.map((r) => ({
      requestId:  r.request_id,
      matchId:    r.match_id,
      status:     r.status,
      appliedAt:  r.applied_at,
      userName:   `${r.user_name} ${r.user_surname}`.toUpperCase(),
      userRating: parseFloat(r.user_rating) || 0,
      fieldName:  r.field_name,
      matchDate:  r.match_date,
      matchTime:  r.match_time,
    })),
  };
}

async function acceptRequest(userId, requestId) {
  const id = Number(requestId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz istek ID.' } };

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const reqRow = await client.query(
      `SELECT pr.log_id, pr.match_id, pr.user_id, pr.status, pr.position_applied, m."Creator_id", m.required_players
       FROM "Position_request" pr
       JOIN "Match" m ON pr.match_id = m.match_id
       WHERE pr.log_id = $1`,
      [id],
    );
    if (reqRow.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 404, body: { error: 'İstek bulunamadı.' } };
    }

    const req = reqRow.rows[0];
    if (req.Creator_id !== userId) {
      await client.query('ROLLBACK');
      return { status: 403, body: { error: 'Bu işlem için yetkiniz yok.' } };
    }
    if (req.status !== 0) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Bu istek zaten işleme alındı.' } };
    }

    const countRow = await client.query(
      `SELECT COUNT(*) AS cnt FROM match_participants WHERE match_id = $1`,
      [req.match_id],
    );
    if (parseInt(countRow.rows[0].cnt) >= req.required_players) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Maç kadrosu dolu.' } };
    }

    await client.query(
      `UPDATE "Position_request" SET status = 1, response_at = NOW() WHERE log_id = $1`,
      [id],
    );
    await client.query(
      `INSERT INTO match_participants (match_id, user_id, position, attendance_status)
       VALUES ($1, $2, $3, 'pending')`,
      [req.match_id, req.user_id, req.position_applied],
    );
    await client.query(
      `UPDATE "Match_req" SET filled_count = filled_count + 1
       WHERE match_id = $1 AND position = $2`,
      [req.match_id, req.position_applied],
    );

    const newCount = parseInt(countRow.rows[0].cnt) + 1;
    if (newCount >= req.required_players) {
      await client.query(
        `UPDATE "Match" SET status = 'full' WHERE match_id = $1`,
        [req.match_id],
      );
      await client.query(
        `INSERT INTO match_archive (match_id, reason) VALUES ($1, 'full')`,
        [req.match_id],
      );
    }

    await client.query('COMMIT');

    sendPushToUser(
      req.user_id,
      'Katılım isteğiniz kabul edildi',
      'Bir maça katılım isteğiniz organizatör tarafından kabul edildi.',
      { type: 'request_accepted', matchId: String(req.match_id) },
    );

    return { status: 200, body: { message: 'Katılım isteği kabul edildi.' } };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function rejectRequest(userId, requestId) {
  const id = Number(requestId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz istek ID.' } };

  const reqRow = await pool.query(
    `SELECT pr.log_id, pr.status, pr.user_id, pr.match_id, m."Creator_id"
     FROM "Position_request" pr
     JOIN "Match" m ON pr.match_id = m.match_id
     WHERE pr.log_id = $1`,
    [id],
  );
  if (reqRow.rows.length === 0)
    return { status: 404, body: { error: 'İstek bulunamadı.' } };

  const req = reqRow.rows[0];
  if (req.Creator_id !== userId)
    return { status: 403, body: { error: 'Bu işlem için yetkiniz yok.' } };
  if (req.status !== 0)
    return { status: 400, body: { error: 'Bu istek zaten işleme alındı.' } };

  await pool.query(
    `UPDATE "Position_request" SET status = 2, response_at = NOW() WHERE log_id = $1`,
    [id],
  );

  sendPushToUser(
    req.user_id,
    'Katılım isteğiniz reddedildi',
    'Bir maça katılım isteğiniz organizatör tarafından reddedildi.',
    { type: 'request_rejected', matchId: String(req.match_id) },
  );

  return { status: 200, body: { message: 'Katılım isteği reddedildi.' } };
}

async function getMyMatches(userId) {
  const result = await pool.query(
    `SELECT
       m.match_id,
       m."Creator_id"                   AS creator_id,
       f.field_name,
       f.city,
       f.district,
       TO_CHAR(m."Date", 'YYYY-MM-DD')  AS date,
       TO_CHAR(m."Time", 'HH24:MI')     AS time,
       m.required_players,
       (SELECT COUNT(*) FROM match_participants mp2 WHERE mp2.match_id = m.match_id)::int AS filled_players,
       m.min_point_required,
       m.price_per_person,
       m.status,
       m.evaluated_at,
       (m."Creator_id" = $1)            AS is_creator,
       mp.position                      AS my_position,
       mp.attendance_status             AS my_attendance,
       EXISTS (
         SELECT 1 FROM "Review_log" rl
         WHERE rl.reviewer_id = $1
           AND rl.related_match_id = m.match_id
           AND rl.user_id = m."Creator_id"
       )                                AS is_rated
     FROM "Match" m
     JOIN "Field" f ON m.field_id = f.field_id
     LEFT JOIN match_participants mp ON mp.match_id = m.match_id AND mp.user_id = $1
     WHERE m."Creator_id" = $1 OR mp.user_id = $1
     ORDER BY m."Date" DESC, m."Time" DESC`,
    [userId],
  );

  const skillMap = { 1: 'Başlangıç', 2: 'Orta Seviye', 3: 'İleri Seviye' };

  return {
    status: 200,
    body: result.rows.map((r) => ({
      matchId:         r.match_id,
      creatorId:       r.creator_id,
      fieldName:       r.field_name,
      city:            r.city,
      district:        r.district,
      date:            r.date,
      time:            r.time,
      requiredPlayers: r.required_players,
      filledPlayers:   r.filled_players,
      skillLevel:      skillMap[r.min_point_required] ?? 'Orta Seviye',
      pricePerPerson:  Number(r.price_per_person),
      status:          r.status,
      isEvaluated:     r.evaluated_at !== null,
      isCreator:       r.is_creator,
      myPosition:      r.my_position ?? null,
      myAttendance:    r.my_attendance ?? null,
      isRated:         r.is_rated ?? false,
    })),
  };
}

async function rateOrganizer(userId, matchId, star) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };

  const s = Math.round(Number(star));
  if (!s || s < 1 || s > 5)
    return { status: 400, body: { error: 'Puan 1-5 arasında olmalıdır.' } };

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Maç var mı, bitti mi?
    const matchRow = await client.query(
      `SELECT "Creator_id", "Date", "Time" FROM "Match" WHERE match_id = $1`,
      [id],
    );
    if (matchRow.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 404, body: { error: 'Maç bulunamadı.' } };
    }

    const match = matchRow.rows[0];
    if (match.Creator_id === userId) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Kendi organizasyonunuzu puanlayamazsınız.' } };
    }

    const [y, mo, d] = match.Date.toISOString().slice(0, 10).split('-').map(Number);
    const [h, mi] = String(match.Time).slice(0, 5).split(':').map(Number);
    const matchUtcMs = Date.UTC(y, mo - 1, d, h, mi) - 3 * 60 * 60 * 1000;
    if (matchUtcMs > Date.now()) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Maç henüz tamamlanmadı.' } };
    }

    // Katılımcı mı ve katıldı mı?
    const partRow = await client.query(
      `SELECT attendance_status FROM match_participants
       WHERE match_id = $1 AND user_id = $2`,
      [id, userId],
    );
    if (partRow.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 403, body: { error: 'Bu maça katılımcı olarak kayıtlı değilsiniz.' } };
    }
    if (partRow.rows[0].attendance_status === 'no_show') {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Maça katılmadığınız için değerlendirme yapamazsınız.' } };
    }

    // Daha önce puanlamış mı?
    const existing = await client.query(
      `SELECT 1 FROM "Review_log"
       WHERE reviewer_id = $1 AND related_match_id = $2 AND user_id = $3`,
      [userId, id, match.Creator_id],
    );
    if (existing.rows.length > 0) {
      await client.query('ROLLBACK');
      return { status: 409, body: { error: 'Bu organizatörü zaten puanladınız.' } };
    }

    await client.query(
      `INSERT INTO "Review_log" (user_id, reviewer_id, related_match_id, star)
       VALUES ($1, $2, $3, $4)`,
      [match.Creator_id, userId, id, s],
    );
    await client.query(
      `UPDATE "User"
       SET avg_rating = (
         SELECT ROUND(AVG(star)::numeric, 2) FROM "Review_log" WHERE user_id = $1
       )
       WHERE user_id = $1`,
      [match.Creator_id],
    );

    await client.query('COMMIT');
    return { status: 200, body: { message: 'Değerlendirme kaydedildi.' } };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function getMatchParticipants(userId, matchId) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };

  const matchRow = await pool.query(
    `SELECT "Creator_id", "Date", "Time" FROM "Match" WHERE match_id = $1`,
    [id],
  );
  if (matchRow.rows.length === 0)
    return { status: 404, body: { error: 'Maç bulunamadı.' } };

  const match = matchRow.rows[0];
  if (match.Creator_id !== userId)
    return { status: 403, body: { error: 'Bu işlem için yetkiniz yok.' } };

  const result = await pool.query(
    `SELECT
       mp.log_id,
       mp.user_id,
       u."Name"     AS name,
       u."Surname"  AS surname,
       u.avg_rating,
       mp.position,
       mp.attendance_status
     FROM match_participants mp
     JOIN "User" u ON mp.user_id = u.user_id
     WHERE mp.match_id = $1
     ORDER BY mp.log_id`,
    [id],
  );

  return {
    status: 200,
    body: result.rows.map((r) => ({
      userId:           r.user_id,
      name:             `${r.name} ${r.surname}`,
      avgRating:        parseFloat(r.avg_rating) || 0,
      position:         r.position,
      attendanceStatus: r.attendance_status,
    })),
  };
}

async function evaluateMatch(organizerId, matchId, evaluations) {
  const id = Number(matchId);
  if (!Number.isInteger(id) || id < 1)
    return { status: 400, body: { error: 'Geçersiz maç ID.' } };

  if (!Array.isArray(evaluations) || evaluations.length === 0)
    return { status: 400, body: { error: 'Değerlendirme verisi eksik.' } };

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const matchRow = await client.query(
      `SELECT "Creator_id", "Date", "Time", evaluated_at, match_counted
       FROM "Match" WHERE match_id = $1 FOR UPDATE`,
      [id],
    );
    if (matchRow.rows.length === 0) {
      await client.query('ROLLBACK');
      return { status: 404, body: { error: 'Maç bulunamadı.' } };
    }

    const match = matchRow.rows[0];
    const alreadyCounted = match.match_counted;

    if (match.Creator_id !== organizerId) {
      await client.query('ROLLBACK');
      return { status: 403, body: { error: 'Bu işlem için yetkiniz yok.' } };
    }

    const matchDateTime = new Date(`${match.Date.toISOString().slice(0, 10)}T${match.Time}`);
    if (matchDateTime > new Date()) {
      await client.query('ROLLBACK');
      return { status: 400, body: { error: 'Maç henüz tamamlanmadı.' } };
    }

    if (match.evaluated_at !== null) {
      await client.query('ROLLBACK');
      return { status: 409, body: { error: 'Bu maç zaten değerlendirildi.' } };
    }

    for (const ev of evaluations) {
      const { userId, attended, rating } = ev;
      if (!userId || typeof attended !== 'boolean') continue;

      const status = attended ? 'attended' : 'no_show';
      await client.query(
        `UPDATE match_participants SET attendance_status = $1
         WHERE match_id = $2 AND user_id = $3`,
        [status, id, userId],
      );

      if (attended) {
        // total_match scheduler tarafından otomatik artırıldı, burada sadece puan veriyoruz
        const star = Math.min(5, Math.max(1, Math.round(rating ?? 3)));
        await client.query(
          `INSERT INTO "Review_log" (user_id, reviewer_id, related_match_id, star)
           VALUES ($1, $2, $3, $4)`,
          [userId, organizerId, id, star],
        );
        await client.query(
          `UPDATE "User"
           SET avg_rating = (
             SELECT ROUND(AVG(star)::numeric, 2) FROM "Review_log" WHERE user_id = $1
           )
           WHERE user_id = $1`,
          [userId],
        );
      } else {
        const PENALTY = 10;
        await client.query(
          `INSERT INTO "Penalty_log" (user_id, related_match_id, penalty, reason)
           VALUES ($1, $2, $3, 'Maça gelmedi')`,
          [userId, id, PENALTY],
        );
        // Scheduler zaten total_match artırdıysa geri al, artırmadıysa sadece ceza ver
        // (Scheduler no_show durumundaki kişileri artırmadığı için bu branch'te attendance_status
        //  zaten bu satırdan önce 'no_show' olarak güncellendi — scheduler doğru çalışır)
        await client.query(
          `UPDATE "User"
           SET "Penalty_score" = "Penalty_score" + $1
             ${alreadyCounted ? ', total_match = GREATEST(0, total_match - 1)' : ''}
           WHERE user_id = $2`,
          [PENALTY, userId],
        );
      }
    }

    await client.query(
      `UPDATE "Match" SET evaluated_at = NOW() WHERE match_id = $1`,
      [id],
    );

    await client.query('COMMIT');
    return { status: 200, body: { message: 'Değerlendirme kaydedildi.' } };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { createMatch, getMatches, getMatchById, joinMatch, getMatchRequests, acceptRequest, rejectRequest, getMyMatches, getMatchParticipants, evaluateMatch, rateOrganizer };
