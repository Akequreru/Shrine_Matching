const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const snapshot = await db.collection('Shrines').get();
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    if (data.name && data.name.includes('金毘羅') || (data.name && data.name.includes('金比羅'))) {
      console.log(JSON.stringify({ id: doc.id, name: data.name, lat: data.latitude, lng: data.longitude }));
    }
  });
}

main().then(() => process.exit(0));
