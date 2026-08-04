const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const snapshot = await db.collection('Users').get();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    console.log(`${doc.id}: userName=${data.userName}, lastType=${data.lastType}`);
  }
}
main().then(() => process.exit(0));
