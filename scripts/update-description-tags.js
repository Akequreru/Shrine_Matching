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
  // 各行: [name, , latitude, longitude, address, image1, image2, image3, description, tag1, tag2, ...]

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
    const description = (row[8] || '').trim();
    const tags = row.slice(9, 17).map((t) => (t || '').trim()).filter(Boolean);

    if (!description && tags.length === 0) {
      skippedNoData++;
      continue; // このシートには説明・タグの新データがない神社は何もしない
    }

    // 緯度経度で照合（座標データが壊れている行のフォールバックとして名前でも照合する）
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
    if (description) updateData.description = description;
    if (tags.length > 0) updateData.tags = tags;

    batch.update(db.collection('Shrines').doc(match.id), updateData);
    updated++;
    console.log(`${match.name}: description=${description ? '更新' : '維持'}, tags=${tags.length > 0 ? `[${tags.join(', ')}]` : '維持'}`);
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件を更新しました（新データなしでスキップ: ${skippedNoData}件） ---`);
}

main().then(() => process.exit(0));
