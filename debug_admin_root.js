const admin = require('firebase-admin');
console.log('admin', admin);
console.log('typeof admin', typeof admin);
console.log('own property names', Object.getOwnPropertyNames(admin));
console.log('admin.applicationDefault', typeof admin.applicationDefault);
console.log('admin.cert', typeof admin.cert);
console.log('admin.refreshToken', typeof admin.refreshToken);
console.log('admin.credential', typeof admin.credential);
if (admin && admin.applicationDefault) {
  console.log('applicationDefault function: yes');
}
