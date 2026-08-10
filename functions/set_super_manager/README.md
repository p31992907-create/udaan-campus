SetSuperManager Cloud Function

Purpose
- Securely assign `role: 'super_manager'` as a custom claim for a Firebase Auth user.
- Write an immutable audit log to `audit_logs` collection when the role is assigned.

Security model
- The function requires a secret (environment variable `ADMIN_SECRET` or functions config `supermanager.admin_secret`).
- Deploy this function into a trusted project and restrict invocation using IAM or by keeping the secret safe.

Local testing (emulator)
1. Install deps:

```bash
cd functions/set_super_manager
npm install
```

2. Start Firebase emulators (auth + firestore + functions):

```bash
firebase emulators:start --only auth,firestore,functions
```

3. Call locally (example using curl):

```bash
curl -X POST "http://localhost:5001/<PROJECT>/us-central1/setSuperManager" \
  -H "Content-Type: application/json" \
  -d '{"email":"sharmaumeshchand773@gmail.com","adminSecret":"your-secret","actor":"ops@yourorg.com","reason":"initial owner setup"}'
```

Deployment
1. Upgrade project `udaan-campus` to Blaze (pay-as-you-go) before deploying Cloud Functions.
2. Set function config secret:

```bash
firebase functions:config:set supermanager.admin_secret="your-secret"
```

3. Deploy:

```bash
cd functions/set_super_manager
npm install
# from project root where firebase.json exists
firebase deploy --only functions:setSuperManager --project udaan-campus
```

## Before deploy
- Confirm Blaze plan is enabled for `udaan-campus`.
- Confirm required APIs are enabled: `cloudfunctions.googleapis.com`, `cloudbuild.googleapis.com`, `artifactregistry.googleapis.com`.
- Grant the service account used for admin operations one of these roles:
  - `roles/firestore.admin`
  - `roles/datastore.owner`
  - or `roles/firebase.admin`
- Use the local admin workflow in `functions/admin_set_super_manager` to verify credentials first.

Usage notes
- The initial assignment should run from a secure environment; after creating this owner, restrict who can call this function (IAM). You can also remove the secret after deployment and require IAM-based invocation only.
- The function writes an immutable audit entry to `audit_logs`. Ensure Firestore rules allow writes to `audit_logs` only from service accounts (see `firestore.rules`).
