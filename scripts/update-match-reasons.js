const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// diagnote.dart の _convertToTypeId / import-shrine.js と同じ対応表
const MBTI_TO_ID = {
  ESTJ: 1, ENTJ: 2, ESFJ: 3, ENFJ: 4,
  ESTP: 5, ENTP: 6, ESFP: 7, ENFP: 8,
  ISTJ: 9, INTJ: 10, ISFJ: 11, INFJ: 12,
  ISTP: 13, INTP: 14, ISFP: 15, INFP: 16,
};

async function main() {
  const csvText = fs.readFileSync('./Book2.csv', 'utf8');
  const rows = parse(csvText, { columns: false, skip_empty_lines: true, bom: true });
  // 各行: [神社名, 緯度, 経度, 住所, 神様名, mbti, 説明,
  //        相性1mbti, 相性1タイプ名, 相性1の理由, 相性2mbti, 相性2タイプ名, 相性2の理由]

  const shrineSnapshot = await db.collection('Shrines').get();
  const shrines = shrineSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  const batch = db.batch();
  let updated = 0;

  for (const row of rows) {
    const [
      shrineName, lat, lng, , kamiName, , ,
      match1Mbti, , match1Reason,
      match2Mbti, , match2Reason,
    ] = row;

    const latNum = parseFloat(lat);
    const lngNum = parseFloat(lng);
    const trimmedKamiName = (kamiName || '').trim();
    if (!trimmedKamiName) continue;

    let shrine = null;
    if (!Number.isNaN(latNum) && !Number.isNaN(lngNum)) {
      shrine = shrines.find(
        (s) => Math.abs(s.latitude - latNum) < 0.0001 && Math.abs(s.longitude - lngNum) < 0.0001
      );
    }
    if (!shrine) {
      shrine = shrines.find((s) => s.name === (shrineName || '').trim());
    }
    if (!shrine) {
      console.warn(`一致する神社が見つかりません: ${shrineName} / ${kamiName}`);
      continue;
    }

    const deitiesSnapshot = await db
      .collection('Shrines')
      .doc(shrine.id)
      .collection('Deities')
      .where('name', '==', trimmedKamiName)
      .get();

    if (deitiesSnapshot.empty) {
      console.warn(`一致する祭神が見つかりません: ${shrine.name} / ${kamiName}`);
      continue;
    }

    const matchReasons = {};
    for (const [mbti, reason] of [[match1Mbti, match1Reason], [match2Mbti, match2Reason]]) {
      const typeId = MBTI_TO_ID[(mbti || '').trim()];
      const trimmedReason = (reason || '').trim();
      if (typeId !== undefined && trimmedReason) {
        matchReasons[String(typeId)] = trimmedReason;
      }
    }

    if (Object.keys(matchReasons).length === 0) continue;

    for (const deityDoc of deitiesSnapshot.docs) {
      batch.update(deityDoc.ref, { matchReasons });
      updated++;
    }
    console.log(`${shrine.name} / ${trimmedKamiName}: matchReasons ${Object.keys(matchReasons).length}件を反映`);
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件の祭神にmatchReasonsを反映しました ---`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
