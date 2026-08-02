const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// diagnote.dart の _convertToTypeId と同じ対応表
const MBTI_TO_ID = {
  ESTJ: 1, ENTJ: 2, ESFJ: 3, ENFJ: 4,
  ESTP: 5, ENTP: 6, ESFP: 7, ENFP: 8,
  ISTJ: 9, INTJ: 10, ISFJ: 11, INFJ: 12,
  ISTP: 13, INTP: 14, ISFP: 15, INFP: 16,
};

const PLACEHOLDER_IMAGES = [
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_A.jpg?alt=media&token=f1c501c1-1afa-4f95-9e06-9996e1319cef',
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_B.jpg?alt=media&token=41dd5ef7-fc9e-4cfa-9bdc-ed77df36a71b',
  'https://firebasestorage.googleapis.com/v0/b/shrine-matching-f1a77.firebasestorage.app/o/kari_gazou_C.jpg?alt=media&token=c7189f70-ba3b-45a2-ab97-7cd7cc0a7d3c',
];

async function importShrinesAndKami() {
  const csvText = fs.readFileSync('./Book2.csv', 'utf8');
  const rows = parse(csvText, { columns: false, skip_empty_lines: true, bom: true });
  // 各行: [神社名, 緯度, 経度, 住所, 神様名, mbti, 説明, 相性1, 相性2]

  // 同じ神社名の行をグルーピング
  const shrineMap = new Map();
  for (const row of rows) {
    const [shrineName, lat, lng, address, kamiName, mbti, description, match1, match2] = row;

    if (!shrineMap.has(shrineName)) {
      shrineMap.set(shrineName, {
        name: shrineName,
        latitude: parseFloat(lat),
        longitude: parseFloat(lng),
        address,
        kamis: [],
      });
    }

    const mbtiId = MBTI_TO_ID[mbti];
    if (mbtiId === undefined) {
      console.warn(`未知のMBTI表記をスキップ: ${shrineName} / ${kamiName} / ${mbti}`);
    }

    shrineMap.get(shrineName).kamis.push({
      name: kamiName,
      mbti: mbtiId ?? 0,
      description,
      matchTypes: [match1, match2]
        .filter(Boolean)
        .map((t) => MBTI_TO_ID[t])
        .filter((v) => v !== undefined),
    });
  }

  for (const shrine of shrineMap.values()) {
    const shrineRef = await db.collection('Shrines').add({
      name: shrine.name,
      concept: '仮。後で埋める',
      description: '仮。後で埋める',
      tags: ['仮A','仮B'],
      images: PLACEHOLDER_IMAGES,
      latitude: shrine.latitude,
      longitude: shrine.longitude,
      address: shrine.address,
      favoriteCount: 0,
    });

    const batch = db.batch();
    shrine.kamis.forEach((kami) => {
      const kamiRef = shrineRef.collection('Deities').doc();
      batch.set(kamiRef, kami);
    });
    await batch.commit();

    console.log(`${shrine.name}: 神様${shrine.kamis.length}柱を登録しました`);
  }

  console.log(`--- 完了: 神社 ${shrineMap.size} 件 ---`);
}

importShrinesAndKami().then(() => process.exit(0));
