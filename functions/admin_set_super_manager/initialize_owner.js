const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const path = require('path');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Error: GOOGLE_APPLICATION_CREDENTIALS is not set.');
  process.exit(1);
}
const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS.trim();

let app;
try {
  const serviceAccount = require(path.resolve(keyPath));
  app = initializeApp({
    credential: cert(serviceAccount),
    projectId: 'udaan-campus',
  });
  console.log('APP_INITIALIZED', app.name, JSON.stringify(app.options));
} catch (e) {
  console.error('Error initializing Firebase Admin SDK:', e.message || e);
  process.exit(1);
}

async function main() {
  const email = 'sharmaumeshchand773@gmail.com';
  const actor = 'udaanacademydr@gmail.com';
  const reason = 'Primary owner initialization via trusted admin script';

  const auth = getAuth(app);
  const db = getFirestore(app);

  let userRecord;
  try {
    console.log('STEP: getUserByEmail', email);
    userRecord = await auth.getUserByEmail(email);
    console.log('STEP: got user', userRecord.uid);
  } catch (err) {
    console.error('STEP: getUserByEmail failed', err.code || err.message || err);
    if (err.code === 'auth/user-not-found' || err.message?.includes('user-not-found')) {
      console.error('USER_NOT_FOUND');
      process.exit(2);
    }
    process.exit(1);
  }

  const uid = userRecord.uid;
  try {
    console.log('STEP: setCustomUserClaims', uid);
    await auth.setCustomUserClaims(uid, { role: 'super_manager' });
    console.log('STEP: custom claims set');
  } catch (err) {
    console.error('STEP: setCustomUserClaims failed', err.code || err.message || err);
    process.exit(1);
  }

  const userRef = db.collection('users').doc(uid);
  let userSnapshot;
  try {
    console.log('STEP: read user doc', uid);
    userSnapshot = await userRef.get();
    console.log('STEP: user doc read', userSnapshot.exists);
  } catch (err) {
    console.error('STEP: read user doc failed', err.code || err.message || err);
    process.exit(1);
  }
  const existingData = userSnapshot.exists ? userSnapshot.data() || {} : {};
  const uniqueId = existingData.uniqueId || `OWNER_${uid.substring(0, 8)}`;

  const updateData = {
    email,
    role: 'super_manager',
    normalizedRole: 'super_manager',
    isPrimaryOwner: true,
    primaryOwnerUid: uid,
    uniqueId,
    updatedAt: FieldValue.serverTimestamp(),
  };

  await userRef.set(updateData, { merge: true });

  const auditRef = db.collection('audit_logs').doc();
  await auditRef.set({
    type: 'OWNER_INITIALIZED',
    actor,
    targetUid: uid,
    targetEmail: email,
    newRole: 'super_manager',
    reason,
    timestamp: FieldValue.serverTimestamp(),
    immutable: true,
  });

  const primaryOwnerRef = db.collection('config').doc('primary_owner');
  await primaryOwnerRef.set({
    uid,
    email,
    uniqueId,
    initializedAt: FieldValue.serverTimestamp(),
  });

  console.log('OWNER_INITIALIZED_SUCCESS');
}

main().catch((err) => {
  console.error('Unexpected error:', err.message || err);
  process.exit(1);
});
