/**
 * Simple admin script (Firebase Functions or standalone Node script) to set a user's custom claim
 * as `super_manager`. This must be executed from a trusted environment (server / admin local with
 * service account) — never expose this client-side.
 *
 * Usage (local Node):
 * 1. Install: npm install firebase-admin
 * 2. Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON
 * 3. Run: node index.js userEmail=someone@example.com
 */

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function setSuperManagerByEmail(email, actor, reason) {
  const auth = admin.auth();
  const db = admin.firestore();
  const user = await auth.getUserByEmail(email);
  if (!user) throw new Error('User not found');

  await auth.setCustomUserClaims(user.uid, { role: 'super_manager' });

  const auditRef = db.collection('audit_logs').doc();
  await auditRef.set({
    type: 'ROLE_ASSIGNED',
    actor: actor || 'local-admin',
    targetUid: user.uid,
    targetEmail: email,
    newRole: 'super_manager',
    reason: reason || null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    immutable: true
  });

  console.log(`Set super_manager claim for ${email} (uid=${user.uid}) and wrote audit log`);
}

async function main() {
  const args = process.argv.slice(2);
  const kv = {};
  args.forEach(a => {
    const [k, v] = a.split('=');
    kv[k] = v;
  });
  if (!kv.userEmail) {
    console.error('Usage: node index.js userEmail=someone@example.com [actor=admin@example.com] [reason=initial-setup]');
    process.exit(1);
  }
  try {
    await setSuperManagerByEmail(kv.userEmail, kv.actor, kv.reason);
    process.exit(0);
  } catch (e) {
    console.error('Error:', e);
    process.exit(2);
  }
}

main();
