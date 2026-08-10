const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS && process.env.GOOGLE_APPLICATION_CREDENTIALS.trim();
if (!keyPath) {
  console.error('MISSING_GOOGLE_APPLICATION_CREDENTIALS');
  process.exit(1);
}
const serviceAccount = require(path.resolve(keyPath));
initializeApp({ credential: cert(serviceAccount), projectId: 'udaan-campus' });
const auth = getAuth();

const email = 'sharmaumeshchand773@gmail.com';

async function main() {
  const user = await auth.getUserByEmail(email);
  console.log('uid=', user.uid);
  console.log('customClaims=', JSON.stringify(user.customClaims || {}));
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
