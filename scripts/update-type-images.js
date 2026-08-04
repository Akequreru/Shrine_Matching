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

// diagnote.dart の _convertToTypeId / import-type.js と同じ対応表
const MBTI_TO_ID = {
  ESTJ: 1, ENTJ: 2, ESFJ: 3, ENFJ: 4,
  ESTP: 5, ENTP: 6, ESFP: 7, ENFP: 8,
  ISTJ: 9, INTJ: 10, ISFJ: 11, INFJ: 12,
  ISTP: 13, INTP: 14, ISFP: 15, INFP: 16,
};

function parseGsUri(uri) {
  const match = /^gs:\/\/([^/]+)\/(.+)$/.exec(uri.trim());
  if (!match) return null;
  return { bucket: match[1], path: match[2] };
}

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
  const csvText = fs.readFileSync('./Book1.csv', 'utf8');
  const rows = parse(csvText, {
    columns: false,
    skip_empty_lines: true,
    bom: true,
    relax_column_count: true,
  });
  // 各行: [name, mbti, concept(2行), , description, , , , paraphrase, , attitude, , favorite, image(gs://)]

  const batch = db.batch();
  let updated = 0;
  let skipped = 0;

  for (const row of rows) {
    const name = (row[0] || '').trim();
    const mbti = (row[1] || '').trim();
    const gsUri = (row[13] || '').trim();
    const id = MBTI_TO_ID[mbti];

    if (id === undefined) {
      console.warn(`未知のMBTI表記をスキップ: ${name} / ${mbti}`);
      continue;
    }

    if (!gsUri) {
      skipped++;
      continue; // 画像指定なし＝今の画像のまま
    }

    const parsed = parseGsUri(gsUri);
    if (!parsed) {
      console.warn(`gs://形式として解釈できません: ${gsUri}`);
      continue;
    }

    const url = await getDownloadUrl(parsed.path);
    if (!url) {
      console.warn(`Storageにファイルが見つかりません: ${parsed.path}（${name}）`);
      continue;
    }

    batch.update(db.collection('Type').doc(String(id)), { image: url });
    updated++;
    console.log(`${name}(${mbti}): 画像を反映`);
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件を更新、${skipped}件は元の画像のまま ---`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
