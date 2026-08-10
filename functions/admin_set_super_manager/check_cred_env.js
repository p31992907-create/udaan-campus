const fs = require('fs');
const p = process.env.GOOGLE_APPLICATION_CREDENTIALS;
console.log('GOOGLE_APPLICATION_CREDENTIALS=', JSON.stringify(p));
if (!p) process.exit(0);
console.log('exists=', fs.existsSync(p));
if (fs.existsSync(p)) {
  console.log('stat.isFile=', fs.statSync(p).isFile());
  console.log('size=', fs.statSync(p).size);
}
