const pool = require('./config/db');

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

function startScheduler() {
  // Başlangıçta bir kez çalıştır, sonra her 2 dakikada bir
  processFinalizedMatches();
  setInterval(processFinalizedMatches, 2 * 60 * 1000);
  console.log('[Scheduler] Başlatıldı. Her 2 dakikada bir maç kontrolü yapılacak.');
}

module.exports = { startScheduler };
