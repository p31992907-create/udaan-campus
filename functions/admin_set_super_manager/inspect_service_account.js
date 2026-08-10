const fs = require('fs');
const path = require('path');
const p = process.argv[2];
if (!p) {
  console.error('Usage: node inspect_service_account.js <path>');
  process.exit(1);
}
try {
  const raw = fs.readFileSync(p, 'utf8');
  const json = JSON.parse(raw);
  console.log('project_id=', json.project_id);
  console.log('client_email=', json.client_email);
  console.log('type=', json.type);
} catch (err) {
  console.error('READ_ERROR', err.message || err);
  process.exit(2);
}
