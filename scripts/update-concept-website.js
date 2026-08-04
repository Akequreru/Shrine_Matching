const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const { parse } = require('csv-parse/sync');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function main() {
  const csvText = fs.readFileSync('./Book3.csv', 'utf8');
  const rows = parse(csvText, { columns: false, skip_empty_lines: true, bom: true });
  // 各行の末尾2列: [..., 公式HP URL(または「なし」), コンセプト]

  const snapshot = await db.collection('Shrines').get();
  const shrines = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  const batch = db.batch();
  let updated = 0;
  let skippedNoData = 0;

  for (const row of rows) {
    const name = (row[0] || '').trim();
    if (!name) continue;

    const lat = parseFloat(row[2]);
    const lng = parseFloat(row[3]);
    const website = (row[17] || '').trim(); // 「なし」はそのまま「なし」として保存する
    const concept = (row[18] || '').trim();

    if (!website && !concept) {
      skippedNoData++;
      continue; // このシートに新データがない神社は何もしない
    }

    let match = null;
    if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
      match = shrines.find(
        (s) => Math.abs(s.latitude - lat) < 0.0001 && Math.abs(s.longitude - lng) < 0.0001
      );
    }
    if (!match) {
      match = shrines.find((s) => s.name === name);
    }
    if (!match) {
      console.warn(`一致する神社が見つかりません: ${name}`);
      continue;
    }

    const updateData = {};
    if (concept) updateData.concept = concept;
    if (website) updateData.officialSite = website;

    batch.update(db.collection('Shrines').doc(match.id), updateData);
    updated++;
    console.log(`${match.name}: concept=${concept ? '更新' : '維持'}, officialSite=${website ? '更新' : '維持(なし)'}`);
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件を更新しました（新データなしでスキップ: ${skippedNoData}件） ---`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
