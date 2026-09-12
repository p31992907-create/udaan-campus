const { applicationDefault, getApp, initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: applicationDefault(),
  projectId: 'udaan-campus',
});

const db = getFirestore();
const expectedCollections = ['users', 'students', 'teachers', 'classes', 'parent_links'];

function asRole(data) {
  return data.normalizedRole || data.role || '(missing)';
}

async function inspectCollection(name) {
  const snapshot = await db.collection(name).get();
  const fieldCounts = new Map();
  const roleCounts = new Map();
  let missingUid = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    for (const field of Object.keys(data)) {
      fieldCounts.set(field, (fieldCounts.get(field) || 0) + 1);
    }
    if (!data.uid && name !== 'classes' && name !== 'parent_links') {
      missingUid += 1;
    }
    if (name === 'users') {
      const role = String(asRole(data)).toLowerCase();
      roleCounts.set(role, (roleCounts.get(role) || 0) + 1);
    }
  }

  return {
    documents: snapshot.size,
    missingUid,
    fields: Object.fromEntries([...fieldCounts.entries()].sort()),
    roles: Object.fromEntries([...roleCounts.entries()].sort()),
  };
}

async function main() {
  const projectId = getApp().options.projectId;
  if (projectId !== 'udaan-campus') {
    throw new Error(`Refusing to inspect unexpected project: ${projectId || '(unknown)'}`);
  }

  const collections = await db.listCollections();
  const existing = new Set(collections.map((collection) => collection.id));
  const report = {};
  for (const name of expectedCollections) {
    report[name] = existing.has(name)
      ? await inspectCollection(name)
      : { documents: 0, missingUid: 0, fields: {}, roles: {}, absent: true };
  }

  console.log(JSON.stringify({
    mode: 'read-only',
    projectId,
    collectionsPresent: collections.map((collection) => collection.id).sort(),
    report,
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
