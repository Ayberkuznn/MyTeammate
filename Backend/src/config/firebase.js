const path = require('path');
const { initializeApp, getApps, cert } = require('firebase-admin/app');

let app = null;
let initAttempted = false;

function getFirebaseApp() {
  if (initAttempted) return app;
  initAttempted = true;

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!serviceAccountPath) {
    console.warn('[Firebase] FIREBASE_SERVICE_ACCOUNT_PATH tanımlı değil, push bildirimleri devre dışı.');
    return null;
  }

  const serviceAccount = require(path.resolve(serviceAccountPath));
  app = getApps()[0] || initializeApp({ credential: cert(serviceAccount) });
  return app;
}

module.exports = { getFirebaseApp };
