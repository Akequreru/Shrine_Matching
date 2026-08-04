const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const snapshot = await db.collection('Shrines').get();
  console.log(`Shrines総数: ${snapshot.size}`);

  const byName = new Map();
  snapshot.docs.forEach((doc) => {
    const name = doc.data().name;
    if (!byName.has(name)) byName.set(name, []);
    byName.get(name).push(doc.id);
  });

  for (const [name, ids] of byName) {
    if (ids.length > 1) {
      console.log(`重複: ${name} -> ${ids.join(', ')}`);
    }
  }
}

main().then(() => process.exit(0));
