const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not initialized (emulator/local deploy will use env creds)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Expected: set environment variable ADMIN_SECRET in function config or environment
// e.g. firebase functions:config:set supermanager.admin_secret="your-secret"
// and access via functions.config().supermanager.admin_secret

const getConfiguredSecret = () => {
  try {
    const cfg = functions.config() && functions.config().supermanager;
    if (cfg && cfg.admin_secret) return cfg.admin_secret;
  } catch (e) {
    // ignore
  }
  return process.env.ADMIN_SECRET || '';
};

exports.setSuperManager = functions.https.onRequest(async (req, res) => {
  // Only allow POST
  if (req.method !== 'POST') {
    return res.status(405).send({ error: 'Method not allowed. Use POST.' });
  }

  const adminSecret = getConfiguredSecret();
  const provided = req.get('x-admin-secret') || req.body.adminSecret;
  if (!adminSecret || provided !== adminSecret) {
    return res.status(401).send({ error: 'Unauthorized: missing/invalid admin secret' });
  }

  const actor = req.get('x-actor') || req.body.actor || 'trusted-backend';
  const { email, reason } = req.body || {};
  if (!email) return res.status(400).send({ error: 'Missing required field: email' });

  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    // Set custom claim: role=super_manager
    await admin.auth().setCustomUserClaims(uid, { role: 'super_manager' });

    // Write an immutable audit log entry using admin credentials
    const db = admin.firestore();
    const auditRef = db.collection('audit_logs').doc();
    const entry = {
      type: 'ROLE_ASSIGNED',
      actor: actor,
      targetUid: uid,
      targetEmail: email,
      newRole: 'super_manager',
      reason: reason || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      immutable: true
    };
    await auditRef.set(entry, { merge: false });

    return res.send({ success: true, uid });
  } catch (e) {
    console.error('setSuperManager error', e);
    return res.status(500).send({ error: e.message || String(e) });
  }
});
