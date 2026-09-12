const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const admin = require('firebase-admin');
const helmet = require('helmet');

if (!admin.apps.length) {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const credential = serviceAccountJson
    ? admin.credential.cert(JSON.parse(serviceAccountJson))
    : undefined;
  admin.initializeApp(credential ? { credential } : {});
}

const app = express();
const db = admin.firestore();
const port = Number(process.env.PORT || 8080);

app.use(express.json({ limit: '32kb' }));
app.use(cors({
  origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : true,
  methods: ['GET', 'POST'],
}));
app.use(helmet());
app.use(rateLimit({
  windowMs: 60 * 1000,
  limit: 120,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
}));

function getBearerToken(req) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1] : null;
}

async function requireAuth(req, res, next) {
  const token = getBearerToken(req);
  if (!token) {
    return res.status(401).json({ error: 'Missing Firebase ID token' });
  }

  try {
    req.user = await admin.auth().verifyIdToken(token);
    return next();
  } catch (error) {
    console.error('Firebase token verification failed', error);
    return res.status(401).json({ error: 'Invalid Firebase ID token' });
  }
}

function requireManager(req, res, next) {
  const role = req.user.role;
  if (role !== 'manager' && role !== 'super_manager') {
    return res.status(403).json({ error: 'Manager role required' });
  }
  return next();
}

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.post('/v1/auth/sync-user', requireAuth, asyncRoute(async (req, res) => {
  const { displayName, email } = req.body || {};
  const user = req.user;
  const profile = {
    uid: user.uid,
    email: email || user.email || null,
    displayName: displayName || user.name || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const userRef = db.collection('users').doc(user.uid);
  const existing = await userRef.get();
  if (!existing.exists) {
    profile.createdAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await userRef.set(profile, { merge: true });
  return res.json({ ok: true, uid: user.uid });
}));

app.post('/v1/parent-links', requireAuth, requireManager, asyncRoute(async (req, res) => {
  const { parentUid, studentUid } = req.body || {};
  if (!parentUid || !studentUid) {
    return res.status(400).json({ error: 'parentUid and studentUid are required' });
  }
  if (parentUid === studentUid) {
    return res.status(400).json({ error: 'Parent and student must be different users' });
  }

  const linkId = `${parentUid}_${studentUid}`;
  await db.collection('parent_links').doc(linkId).set({
    parentUid,
    studentUid,
    createdBy: req.user.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    active: true,
  }, { merge: true });

  return res.status(201).json({ ok: true, linkId });
}));

app.use((error, _req, res, _next) => {
  if (error instanceof SyntaxError && error.status === 400) {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }
  console.error('Unhandled backend error', error);
  return res.status(500).json({ error: 'Internal server error' });
});

app.listen(port, () => {
  console.log(`External backend listening on port ${port}`);
});
