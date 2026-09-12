# External backend adapter

This service keeps Firebase Cloud Functions out of the runtime path so the
project can be hosted on a free external platform. Firebase Auth and Firestore
remain the source of truth.

## Endpoints

- `GET /health` - unauthenticated health check.
- `POST /v1/auth/sync-user` - verifies a Firebase ID token and upserts only
  identity fields in `users/{uid}`. It never accepts or changes a role.
- `POST /v1/parent-links` - verifies a Firebase ID token, requires a
  `manager` or `super_manager` claim, and creates
  `parent_links/{parentUid_studentUid}`.

All protected requests must send:

```text
Authorization: Bearer <Firebase ID token>
```

The service also applies security headers, CORS restrictions, a JSON body
limit, and a per-IP request limit. Set `CORS_ORIGIN` to a comma-separated
allowlist when serving a browser client.

## Local run

The service uses Application Default Credentials. Do not commit credentials.

```powershell
cd external-backend
npm install
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\secure\udaan-campus-service-account.json"
npm start
```

For a hosted deployment, configure the platform's secret store with the
service-account JSON or the platform's workload identity mechanism. Never put
the key in the repository or in the Flutter app.

## Render free deployment

1. Create a Render account and connect this repository.
2. Create a new Blueprint using `external-backend/render.yaml`.
3. Set `FIREBASE_SERVICE_ACCOUNT_JSON` to the complete service-account JSON
   for the `udaan-campus` project in Render's secret environment variables.
4. Set `CORS_ORIGIN` to the exact app/web origins that may call the API.
5. Deploy and verify `https://<service>.onrender.com/health`.

Render's free service can sleep when idle, so the first request after idle may
be slow. Never paste the service-account JSON into source control, chat, or a
public dashboard.

## Deployment note

This is intentionally a hosting adapter, not a Firebase deployment. The
hosting provider must support Node.js and secret environment variables. Before
connecting the Flutter client, verify `/health`, then test both protected
routes with a short-lived Firebase ID token in a non-production account.

The `parent_links` collection and its fields are explicit in this adapter;
existing production data is not migrated automatically.

## Container deployment

The included `Dockerfile` runs as the non-root `node` user:

```powershell
docker build -t udaan-campus-backend .
docker run --rm -p 8080:8080 `
  -e GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/firebase.json `
  -v C:\secure\udaan-campus-service-account.json:/run/secrets/firebase.json:ro `
  udaan-campus-backend
```
