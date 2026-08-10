const admin = require('firebase-admin');
console.log('adminCredentialExists', admin && typeof admin.credential !== 'undefined');
if (admin && typeof admin.credential !== 'undefined') {
  console.log('credentialType', typeof admin.credential);
  console.log('credentialKeys', Object.keys(admin.credential || {}).join(','));
}
