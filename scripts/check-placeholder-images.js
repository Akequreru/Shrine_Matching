const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const PLACEHOLDER_IMAGES = [
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_A.jpg?alt=media&token=f1c501c1-1afa-4f95-9e06-9996e1319cef',
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_B.jpg?alt=media&token=41dd5ef7-fc9e-4cfa-9bdc-ed77df36a71b',
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_C.jpg?alt=media&token=c7189f70-ba3b-45a2-ab97-7cd7cc0a7d3c',
];

async function main() {
  const snapshot = await db.collection('Shrines').get();
  let placeholderCount = 0;
  let realCount = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const images = data.images || [];
    const isPlaceholder = images.length > 0 && images.every((u) => PLACEHOLDER_IMAGES.includes(u));
    const isEmpty = images.length === 0;
    if (isPlaceholder || isEmpty) {
      placeholderCount++;
      console.log(`[仮画像/空] ${data.name} (${doc.id}) images=${images.length}件`);
    } else {
      realCount++;
    }
  }
  console.log(`--- 仮画像/画像なし: ${placeholderCount}件, 実画像あり: ${realCount}件, 合計: ${snapshot.docs.length}件 ---`);
}
main().then(() => process.exit(0));
