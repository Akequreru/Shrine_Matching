const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { randomUUID } = require('crypto');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const BUCKET_NAME = 'shrine-matching-f1a77.firebasestorage.app';
const bucket = getStorage().bucket(BUCKET_NAME);

// gs://bucket/path.jpg -> { bucket, path }
function parseGsUri(uri) {
  const match = /^gs:\/\/([^/]+)\/(.+)$/.exec(uri.trim());
  if (!match) return null;
  return { bucket: match[1], path: match[2] };
}

// Storage上のファイルに公開ダウンロードURL（トークン付き）を発行する。
// 既存の仮画像と同じ形式のURLになるようにしている。
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
    // 複数トークンがカンマ区切りで入っていることがあるので先頭だけ使う
    token = token.split(',')[0];
  }

  const encodedPath = encodeURIComponent(objectPath);
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET_NAME}/o/${encodedPath}?alt=media&token=${token}`;
}

async function main() {
  const csvText = fs.readFileSync('./Book3.csv', 'utf8');
  const rows = parse(csvText, { columns: false, skip_empty_lines: true, bom: true });
  // 各行: [name, , latitude, longitude, address, image1(gs://), image2(gs://), image3(gs://)]

  const snapshot = await db.collection('Shrines').get();
  const shrines = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  const batch = db.batch();
  let updated = 0;
  let skippedNoImage = 0;

  for (const row of rows) {
    const name = (row[0] || '').trim();
    const lat = parseFloat(row[2]);
    const lng = parseFloat(row[3]);
    if (!name || Number.isNaN(lat) || Number.isNaN(lng)) continue;

    const gsUris = [row[5], row[6], row[7]]
      .map((v) => (v || '').trim())
      .filter(Boolean);

    if (gsUris.length === 0) {
      skippedNoImage++;
      continue; // 画像指定なし＝仮画像のまま
    }

    const match = shrines.find(
      (s) => Math.abs(s.latitude - lat) < 0.0001 && Math.abs(s.longitude - lng) < 0.0001
    );
    if (!match) {
      console.warn(`一致する神社が見つかりません: ${name} (${lat}, ${lng})`);
      continue;
    }

    const urls = [];
    for (const uri of gsUris) {
      const parsed = parseGsUri(uri);
      if (!parsed) {
        console.warn(`gs://形式として解釈できません: ${uri}`);
        continue;
      }
      const url = await getDownloadUrl(parsed.path);
      if (url) {
        urls.push(url);
      } else {
        console.warn(`Storageにファイルが見つかりません: ${parsed.path}（${name}）`);
      }
    }

    if (urls.length === 0) {
      skippedNoImage++;
      continue; // 指定はあったが実ファイルが1つも無かった＝仮画像のまま
    }

    batch.update(db.collection('Shrines').doc(match.id), { images: urls });
    updated++;
    console.log(`${name}: 画像${urls.length}枚を反映`);
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件を更新、${skippedNoImage}件は仮画像のまま ---`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
