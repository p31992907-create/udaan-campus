const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('NO_CREDENTIAL_ENV');
  process.exit(1);
}
process.env.GOOGLE_APPLICATION_CREDENTIALS = process.env.GOOGLE_APPLICATION_CREDENTIALS.trim();

initializeApp({
  credential: applicationDefault(),
  projectId: 'udaan-campus',
});

const db = getFirestore();
const docRef = db.collection('users').doc('fhKbFTuGDtQaHEQ5JuuqOQC7Aoj1');
console.log('DEBUG_FIRESTORE_READ');
docRef.get()
  .then(doc => {
    console.log('doc.exists', doc.exists);
    if (doc.exists) console.log('data', doc.data());
  })
  .catch(err => {
    console.error('FIRESTORE_ERROR_CODE', err.code || err.status || 'NO_CODE');
    console.error('FIRESTORE_ERROR_MESSAGE', err.message || err);
    console.error('FIRESTORE_ERROR_STACK', err.stack);
    console.error('FIRESTORE_ERROR_RAW', JSON.stringify(err, Object.getOwnPropertyNames(err), 2));
    process.exit(1);
  });
