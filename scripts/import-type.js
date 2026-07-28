const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// diagnote.dart の _convertToTypeId と同じ対応表（idをここに揃えることで、
// 診断結果のtypeIdでこのTypeコレクションをそのまま引けるようにする）
const MBTI_TO_ID = {
  ESTJ: 1, ENTJ: 2, ESFJ: 3, ENFJ: 4,
  ESTP: 5, ENTP: 6, ESFP: 7, ENFP: 8,
  ISTJ: 9, INTJ: 10, ISFJ: 11, INFJ: 12,
  ISTP: 13, INTP: 14, ISFP: 15, INFP: 16,
};

// 今マッチング画面(神社)で使っている仮画像をそのまま流用
const PLACEHOLDER_IMAGE =
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_A.jpg?alt=media&token=f1c501c1-1afa-4f95-9e06-9996e1319cef';

function clean(value) {
  return (value ?? '').replace(/\s+$/g, '').trim();
}

async function importTypes() {
  const csvText = fs.readFileSync('./Book1.csv', 'utf8');
  const rows = parse(csvText, { columns: false, skip_empty_lines: true, bom: true });
  // 各行: [name, mbti, concept(2行), , description, , , , paraphrase, , attitude, , favorite, ]

  const batch = db.batch();
  let count = 0;

  rows.forEach((row) => {
    const name = clean(row[0]);
    const mbti = clean(row[1]);
    const id = MBTI_TO_ID[mbti];

    if (id === undefined) {
      console.warn(`未知のMBTI表記をスキップ: ${name} / ${mbti}`);
      return;
    }

    const concept = clean(row[2]).split('\n').map((s) => s.trim()).filter(Boolean).join('/');
    const description = clean(row[4]);
    const paraphrase = clean(row[8]);
    const attitude = clean(row[10]);
    const favorite = clean(row[12]);

    const ref = db.collection('Type').doc(String(id));
    batch.set(ref, {
      id,
      name,
      image: PLACEHOLDER_IMAGE,
      mbti,
      concept,
      description,
      paraphrase,
      attitude,
      favorite,
    });
    count++;
  });

  await batch.commit();
  console.log(`Type: ${count}件登録しました`);
}

importTypes().then(() => process.exit(0));
