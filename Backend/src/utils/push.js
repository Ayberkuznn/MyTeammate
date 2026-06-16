const pool = require('../config/db');
const { getFirebaseApp } = require('../config/firebase');
const { getMessaging } = require('firebase-admin/messaging');

// Tek bir kullanıcıya push bildirimi gönderir. Token kayıtlı değilse veya
// Firebase yapılandırılmamışsa sessizce atlar.
async function sendPushToUser(userId, title, body, data = {}) {
  const app = getFirebaseApp();
  if (!app) return;

  const result = await pool.query(
    'SELECT fcm_token FROM "User" WHERE user_id = $1 LIMIT 1',
    [userId]
  );
  const token = result.rows[0]?.fcm_token;
  if (!token) return;

  try {
    await getMessaging(app).send({
      token,
      notification: { title, body },
      data,
    });
  } catch (err) {
    console.error(`[Push] Kullanıcı ${userId} için bildirim gönderilemedi:`, err.message);
    // Geçersiz/iptal edilmiş token ise temizle
    if (
      err.code === 'messaging/registration-token-not-registered' ||
      err.code === 'messaging/invalid-registration-token'
    ) {
      await pool.query('UPDATE "User" SET fcm_token = NULL WHERE user_id = $1', [userId]);
    }
  }
}

async function sendPushToUsers(userIds, title, body, data = {}) {
  for (const userId of userIds) {
    await sendPushToUser(userId, title, body, data);
  }
}

module.exports = { sendPushToUser, sendPushToUsers };
