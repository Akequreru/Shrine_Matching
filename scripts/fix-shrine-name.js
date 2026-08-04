const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const snapshot = await db.collection('Shrines').where('name', '==', '栗田神社').get();

  if (snapshot.empty) {
    console.log('「栗田神社」という名前のドキュメントは見つかりませんでした。');
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    console.log(`更新: ${doc.id}（栗田神社 → 粟田神社）`);
    batch.update(doc.ref, { name: '粟田神社' });
  });
  await batch.commit();

  console.log(`--- 完了: ${snapshot.size}件の名前を更新しました ---`);
}

main().then(() => process.exit(0));
