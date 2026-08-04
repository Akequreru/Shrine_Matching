const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { randomUUID } = require('crypto');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const BUCKET_NAME = 'shrine-matching-f1a77.firebasestorage.app';
const bucket = getStorage().bucket(BUCKET_NAME);
const LOGO_PATH = 'logo.png';

const PLACEHOLDER_IMAGES = [
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_A.jpg?alt=media&token=f1c501c1-1afa-4f95-9e06-9996e1319cef',
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_B.jpg?alt=media&token=41dd5ef7-fc9e-4cfa-9bdc-ed77df36a71b',
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_C.jpg?alt=media&token=c7189f70-ba3b-45a2-ab97-7cd7cc0a7d3c',
];

async function getDownloadUrl(objectPath) {
  const file = bucket.file(objectPath);
  const [exists] = await file.exists();
  if (!exists) return null;

  const [metadata] = await file.getMetadata();
  let token = metadata.metadata && metadata.metadata.firebaseStorageDownloadTokens;

  if (!token) {
    token = randomUUID();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  } else {
    token = token.split(',')[0];
  }

  const encodedPath = encodeURIComponent(objectPath);
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET_NAME}/o/${encodedPath}?alt=media&token=${token}`;
}

async function main() {
  const logoUrl = await getDownloadUrl(LOGO_PATH);
  if (!logoUrl) {
    console.error(`Storageに ${LOGO_PATH} が見つかりません`);
    process.exit(1);
  }

  const snapshot = await db.collection('Shrines').get();
  const batch = db.batch();
  let updated = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const images = data.images || [];
    const isPlaceholder = images.length > 0 && images.every((u) => PLACEHOLDER_IMAGES.includes(u));
    const isEmpty = images.length === 0;
    if (!isPlaceholder && !isEmpty) continue; // 実画像が既にある神社は触らない

    batch.update(doc.ref, { images: [logoUrl] });
    updated++;
    console.log(`${data.name}: logo.pngに置き換え`);
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件をlogo.png画像に置き換えました ---`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
