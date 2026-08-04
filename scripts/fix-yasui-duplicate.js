const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const DUPLICATE_IDS = ['Srl9qCjFCDB3la1SEwKs', 'pmAaaBHIp07jY1LdZjhM'];

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

// Book2.csvの安井金毘羅宮の3行分
const KAMIS = [
  { name: '源頼政', mbti: 'ISTJ', description: '忠義と責任感を重んじた武将。', match: ['ENFP', 'ESFP'] },
  { name: '崇徳天皇', mbti: 'INFJ', description: '強い信念と精神性を持ち、縁を司る象徴。', match: ['ENFP', 'ENTP'] },
  { name: '大物主神', mbti: 'INTJ', description: '知恵と見通しに優れた国土経営の神。', match: ['ENFP', 'ENTP'] },
];

async function deleteShrineDoc(shrineId) {
  const shrineRef = db.collection('Shrines').doc(shrineId);
  const deitiesSnapshot = await shrineRef.collection('Deities').get();

  const batch = db.batch();
  deitiesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
  batch.delete(shrineRef);
  await batch.commit();
  console.log(`削除: ${shrineId}（Deities ${deitiesSnapshot.size}件含む）`);
}

async function main() {
  for (const id of DUPLICATE_IDS) {
    await deleteShrineDoc(id);
  }

  const shrineRef = await db.collection('Shrines').add({
    name: '安井金毘羅宮',
    concept: '仮。後で埋める',
    description: '仮。後で埋める',
    tags: ['仮A', '仮B'],
    images: PLACEHOLDER_IMAGES,
    latitude: 35.00040221,
    longitude: 135.7768364,
    address: '京都市東山区',
    favoriteCount: 0,
  });

  const batch = db.batch();
  KAMIS.forEach((kami) => {
    const kamiRef = shrineRef.collection('Deities').doc();
    batch.set(kamiRef, {
      name: kami.name,
      mbti: MBTI_TO_ID[kami.mbti],
      description: kami.description,
      matchTypes: kami.match.map((t) => MBTI_TO_ID[t]),
    });
  });
  await batch.commit();

  console.log(`作成: ${shrineRef.id}（神様${KAMIS.length}柱）`);
}

main().then(() => process.exit(0));
