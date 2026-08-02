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
  // 各行: [name, , latitude, longitude, address, , , ]

  const snapshot = await db.collection('Shrines').get();
  const shrines = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

  const batch = db.batch();
  let updated = 0;

  for (const row of rows) {
    const name = (row[0] || '').trim();
    const lat = parseFloat(row[2]);
    const lng = parseFloat(row[3]);
    const newAddress = (row[4] || '').trim();
    if (!name || Number.isNaN(lat) || Number.isNaN(lng) || !newAddress) continue;

    // 名前が変わっている場合があるため、緯度経度で照合する
    const match = shrines.find(
      (s) => Math.abs(s.latitude - lat) < 0.0001 && Math.abs(s.longitude - lng) < 0.0001
    );

    if (!match) {
      console.warn(`一致する神社が見つかりません: ${name} (${lat}, ${lng})`);
      continue;
    }

    if (match.name !== name) {
      console.log(`名前の表記差分（住所のみ更新、名前はそのまま）: Firestore「${match.name}」 / CSV「${name}」`);
    }

    if (match.address === newAddress) continue; // 変更なしはスキップ

    batch.update(db.collection('Shrines').doc(match.id), { address: newAddress });
    updated++;
  }

  await batch.commit();
  console.log(`--- 完了: ${updated}件の住所を更新しました ---`);
}

main().then(() => process.exit(0));
