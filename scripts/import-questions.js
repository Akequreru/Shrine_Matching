const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// diagnote.dart の questions リストから抽出（value: 0=E/I, 1=S/N, 2=T/F, 3=J/P の軸）
const QUESTIONS = [
  { value: 0, question: 'にぎやかな旅が好きですか？それとも、静かで落ち着いた旅が好きですか？', answer1: 'にぎやかな旅', answer2: '静かで落ち着いた旅' },
  { value: 0, question: '大人数での旅行が好きですか？それとも、一人旅が好きですか？', answer1: '大人数での旅行', answer2: '一人旅' },
  { value: 0, question: '旅先で新しい友達を作りますか？それとも、人見知りしますか？', answer1: '新しい友達', answer2: '人見知り' },

  { value: 1, question: '事実や具体的な情報に基づいて判断しますか？それとも、未来の可能性や直感に頼りますか？', answer1: '事実や具体的な情報', answer2: '未来の可能性や直感' },
  { value: 1, question: '現実的で実用的なことに焦点を当てますか？それとも、理想や抽象的なアイデアに興味を持ちますか？', answer1: '現実的で実用的なこと', answer2: '理想や抽象的なアイデア' },
  { value: 1, question: '今起こっていることに集中しますか？それとも、先のことを考えることが多いですか？', answer1: '今起こっていること', answer2: '先のこと' },

  { value: 2, question: '論理的で客観的な判断を好みますか？それとも、人間関係や感情を考慮して判断しますか？', answer1: '論理的で客観的', answer2: '人間関係や感情' },
  { value: 2, question: '決定を下す際に、公平さや原則を重視しますか？それとも、調和や共感を重視しますか？', answer1: '公平さや原則', answer2: '調和や共感' },
  { value: 2, question: '自分の意見をはっきりと伝えることが得意ですか？それとも、他人の感情に配慮して言葉を選びますか？', answer1: '意見をはっきりと伝える', answer2: '他人の感情に配慮する' },

  { value: 3, question: '旅行は計画を立ててから出かけることが好きですか？それとも、気ままに出かけることを好みますか？', answer1: '計画を立ててから出かける', answer2: '気ままに出かける' },
  { value: 3, question: '旅行は予定通りに進めたいですか？それとも、思いがけない出来事がある方が良いですか？', answer1: '予定通りに進めたい', answer2: '思いがけない出来事がある方が良い' },
  { value: 3, question: 'お土産はあらかじめ何を買うか決めますか？それとも、お土産屋さんで決めますか？', answer1: 'あらかじめ決めておく', answer2: 'お土産屋さんで決める' },
];

async function importQuestions() {
  const batch = db.batch();

  QUESTIONS.forEach((q) => {
    const ref = db.collection('Questions').doc();
    batch.set(ref, {
      value: q.value,
      question: q.question,
      answer1: q.answer1,
      answer2: q.answer2,
    });
  });

  await batch.commit();
  console.log(`Questions: ${QUESTIONS.length}件登録しました`);
}

importQuestions().then(() => process.exit(0));
