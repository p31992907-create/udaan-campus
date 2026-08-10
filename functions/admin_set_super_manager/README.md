Admin script to assign `super_manager` custom claim

Setup
1. Create a Firebase service account and download the JSON key.
2. Export the environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

3. Install dependencies and run:

```bash
cd functions/admin_set_super_manager
npm install
npm run verify-auth
npm run check-firestore
npm run initialize-owner
npm run verify-claim
```

If `npm install` asks to install `firebase-admin`, allow it.

## Permission checklist before deploy
1. Upgrade Firebase project `udaan-campus` to Blaze (pay-as-you-go).
2. Ensure the service account JSON belongs to `udaan-campus`.
3. Grant the service account the required Firestore permissions:
   - `roles/firestore.admin` or `roles/datastore.owner`
   - `roles/firebase.admin` is also acceptable for broader admin access.
4. If deploying Cloud Functions, also enable:
   - `cloudfunctions.googleapis.com`
   - `cloudbuild.googleapis.com`
   - `artifactregistry.googleapis.com`
5. Re-run `npm run check-firestore` to verify Firestore access before deploying.

Notes
- This must run in a trusted environment. Do not commit service account keys.
- Alternatively implement as a Firebase Cloud Function with proper IAM protections.
