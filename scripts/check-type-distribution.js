const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const shrineSnapshot = await db.collection('Shrines').get();
  const shrines = shrineSnapshot.docs.map((doc) => ({ id: doc.id, name: doc.data().name }));

  const deitiesSnapshot = await db.collectionGroup('Deities').get();
  const kamiByShrineId = new Map();
  for (const doc of deitiesSnapshot.docs) {
    const shrineId = doc.ref.parent.parent.id;
    if (!kamiByShrineId.has(shrineId)) kamiByShrineId.set(shrineId, []);
    kamiByShrineId.get(shrineId).push(doc.data());
  }

  const countByType = {};
  for (let t = 1; t <= 16; t++) countByType[t] = 0;

  for (const shrine of shrines) {
    const kamis = kamiByShrineId.get(shrine.id) || [];
    const typesInThisShrine = new Set(kamis.map((k) => k.mbti));
    for (const t of typesInThisShrine) {
      if (countByType[t] !== undefined) countByType[t]++;
    }
  }

  console.log('タイプID: 一致する神社数');
  for (let t = 1; t <= 16; t++) {
    console.log(`${t}: ${countByType[t]}`);
  }
  console.log(`神社総数: ${shrines.length}, 祭神総数: ${deitiesSnapshot.docs.length}`);
}
main().then(() => process.exit(0));
