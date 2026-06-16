const pool = require('./config/db');
const { sendPushToUsers } = require('./utils/push');

// Bir maçın katılımcılarının ve organizatörünün user_id listesini döner.
async function getMatchUserIds(client, matchId, creatorId) {
  const participants = await client.query(
    `SELECT user_id FROM match_participants WHERE match_id = $1`,
    [matchId]
  );
  const userIds = new Set(participants.rows.map((r) => r.user_id));
  userIds.add(creatorId);
  return [...userIds];
}

// Her 2 dakikada bir maç bitmişse (1 saat geçmişse) katılımcıların total_match'ini artır.
async function processFinalizedMatches() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // match_counted = false ve maç saatinden 1 saat geçmiş maçları bul
    const matches = await client.query(
      `SELECT match_id, "Creator_id" AS creator_id FROM "Match"
       WHERE match_counted = FALSE
         AND (("Date" + "Time") AT TIME ZONE 'Europe/Istanbul') <= NOW() AT TIME ZONE 'Europe/Istanbul'`,
    );

    for (const row of matches.rows) {
      const matchId   = row.match_id;
      const creatorId = row.creator_id;

      // no_show olarak işaretlenmemiş katılımcıların total_match'ini artır
      await client.query(
        `UPDATE "User" u
         SET total_match = total_match + 1
         FROM match_participants mp
         WHERE mp.match_id = $1
           AND mp.user_id = u.user_id
           AND mp.attendance_status != 'no_show'`,
        [matchId],
      );

      // Organizatörün de maç sayısını artır
      await client.query(
        `UPDATE "User" SET total_match = total_match + 1 WHERE user_id = $1`,
        [creatorId],
      );

      await client.query(
        `UPDATE "Match" SET match_counted = TRUE WHERE match_id = $1`,
        [matchId],
      );
    }

    await client.query('COMMIT');
    if (matches.rows.length > 0)
      console.log(`[Scheduler] ${matches.rows.length} maç işlendi, katılımcı sayaçları güncellendi.`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[Scheduler] Hata:', err.message);
  } finally {
    client.release();
  }
}

// Başlamasına 1 saatten az kalan ve henüz hatırlatma bildirimi gönderilmemiş
// maçların katılımcılarına ve organizatörüne "maç yaklaşıyor" bildirimi gönderir.
async function sendMatchReminders() {
  const client = await pool.connect();
  try {
    const matches = await client.query(
      `SELECT match_id, "Creator_id" AS creator_id FROM "Match"
       WHERE reminder_sent = FALSE
         AND (("Date" + "Time") AT TIME ZONE 'Europe/Istanbul') > NOW() AT TIME ZONE 'Europe/Istanbul'
         AND (("Date" + "Time") AT TIME ZONE 'Europe/Istanbul') <= (NOW() AT TIME ZONE 'Europe/Istanbul' + INTERVAL '1 hour')`,
    );

    for (const row of matches.rows) {
      const matchId   = row.match_id;
      const creatorId = row.creator_id;

      const userIds = await getMatchUserIds(client, matchId, creatorId);
      await sendPushToUsers(
        userIds,
        'Maçınız yaklaşıyor!',
        'Katıldığınız maç 1 saat içinde başlayacak.',
        { type: 'match_reminder', matchId: String(matchId) },
      );

      await client.query(`UPDATE "Match" SET reminder_sent = TRUE WHERE match_id = $1`, [matchId]);
    }

    if (matches.rows.length > 0)
      console.log(`[Scheduler] ${matches.rows.length} maç için hatırlatma bildirimi gönderildi.`);
  } catch (err) {
    console.error('[Scheduler] Hatırlatma bildirimi hatası:', err.message);
  } finally {
    client.release();
  }
}

// Saati geçmiş ve henüz değerlendirme bildirimi gönderilmemiş maçların
// katılımcılarına ve organizatörüne "maçı değerlendir" bildirimi gönderir.
async function sendEvaluationNotifications() {
  const client = await pool.connect();
  try {
    const matches = await client.query(
      `SELECT match_id, "Creator_id" AS creator_id FROM "Match"
       WHERE eval_notif_sent = FALSE
         AND (("Date" + "Time") AT TIME ZONE 'Europe/Istanbul') <= NOW() AT TIME ZONE 'Europe/Istanbul'`,
    );

    for (const row of matches.rows) {
      const matchId   = row.match_id;
      const creatorId = row.creator_id;

      const userIds = await getMatchUserIds(client, matchId, creatorId);
      await sendPushToUsers(
        userIds,
        'Maçı değerlendir',
        'Katıldığınız maç sona erdi. Takım arkadaşlarınızı değerlendirmeyi unutmayın.',
        { type: 'match_evaluation', matchId: String(matchId) },
      );

      await client.query(`UPDATE "Match" SET eval_notif_sent = TRUE WHERE match_id = $1`, [matchId]);
    }

    if (matches.rows.length > 0)
      console.log(`[Scheduler] ${matches.rows.length} maç için değerlendirme bildirimi gönderildi.`);
  } catch (err) {
    console.error('[Scheduler] Değerlendirme bildirimi hatası:', err.message);
  } finally {
    client.release();
  }
}

async function runSchedulerTasks() {
  await processFinalizedMatches();
  await sendMatchReminders();
  await sendEvaluationNotifications();
}

function startScheduler() {
  // Başlangıçta bir kez çalıştır, sonra her 2 dakikada bir
  runSchedulerTasks();
  setInterval(runSchedulerTasks, 2 * 60 * 1000);
  console.log('[Scheduler] Başlatıldı. Her 2 dakikada bir maç kontrolü yapılacak.');
}

module.exports = { startScheduler };
