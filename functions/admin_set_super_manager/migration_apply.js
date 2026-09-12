const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: applicationDefault(),
  projectId: 'udaan-campus',
});

const db = getFirestore();

function buildUserPatch(doc) {
  const data = doc.data();
  const patch = {};
  if (!data.uid) patch.uid = doc.id;
  if (!data.normalizedRole && data.role) patch.normalizedRole = String(data.role).trim().toLowerCase();
  if (!data.phoneNumber && data['phone number']) patch.phoneNumber = data['phone number'];
  return patch;
}

function buildStudentPatch(doc) {
  const data = doc.data();
  return data.uid ? {} : { uid: doc.id };
}

async function collectPatches() {
  const patches = [];
  const users = await db.collection('users').get();
  for (const doc of users.docs) {
    const patch = buildUserPatch(doc);
    if (Object.keys(patch).length) patches.push({ collection: 'users', id: doc.id, patch });
  }

  const students = await db.collection('students').get();
  for (const doc of students.docs) {
    const patch = buildStudentPatch(doc);
    if (Object.keys(patch).length) patches.push({ collection: 'students', id: doc.id, patch });
  }
  return patches;
}

async function main() {
  const patches = await collectPatches();
  console.log(JSON.stringify({ projectId: 'udaan-campus', patches }, null, 2));

  if (process.env.MIGRATION_APPLY !== 'true') {
    console.log('Read-only mode: set MIGRATION_APPLY=true to apply these merge patches.');
    return;
  }

  const batch = db.batch();
  for (const item of patches) {
    batch.set(
      db.collection(item.collection).doc(item.id),
      { ...item.patch, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
  if (patches.length) await batch.commit();
  console.log(`Applied ${patches.length} non-destructive merge patches.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
