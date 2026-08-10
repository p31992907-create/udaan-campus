const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const path = require('path');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('MISSING_GOOGLE_APPLICATION_CREDENTIALS');
  process.exit(1);
}
const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS.trim();

try {
  const serviceAccount = require(path.resolve(keyPath));
  initializeApp({
    credential: cert(serviceAccount),
  });
  getAuth();
  console.log('ADMIN_AUTH_OK');
} catch (err) {
  console.error('ADMIN_AUTH_FAIL', err.message || err);
  process.exit(2);
}
