import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shrine.dart';
import '../models/question.dart';
import '../models/app_user.dart';
import '../models/kami.dart';     // ★変更：kami.dart
import '../models/history.dart';  // ★変更：history.dart

class FirestoreService {
  // Firestoreのインスタンス（通信窓口）を変数にしておく
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // ① 神社のデータを全件取得する関数
  // ==========================================
  Future<List<Shrine>> getShrines() async {
    final snapshot = await _db.collection('Shrines').get();
    return snapshot.docs.map((doc) {
      return Shrine.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // ==========================================
  // ② 質問のデータを全件取得する関数
  // ==========================================
  Future<List<Question>> getQuestions() async {
    final snapshot = await _db.collection('Questions').get();
    return snapshot.docs.map((doc) {
      return Question.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // ==========================================
  // ③ お気に入りを追加・解除する関数
  // ==========================================
  Future<void> toggleFavorite({
    required String userId,
    required String shrineId,
    required bool isAdding,
  }) async {
    final userRef = _db.collection('Users').doc(userId);
    final shrineRef = _db.collection('Shrines').doc(shrineId);

    if (isAdding) {
      await userRef.update({
        'favoriteShrineIds': FieldValue.arrayUnion([shrineId]),
      });
      await shrineRef.update({'favoriteCount': FieldValue.increment(1)});
    } else {
      await userRef.update({
        'favoriteShrineIds': FieldValue.arrayRemove([shrineId]),
      });
      await shrineRef.update({'favoriteCount': FieldValue.increment(-1)});
    }
  }

  // ==========================================
  // ④ 特定のタイプで神社を絞り込む関数
  // ==========================================
  Future<List<Shrine>> getShrinesByType(String type) async {
    final snapshot = await _db
        .collection('Shrines')
        .where('type', isEqualTo: type)
        .get();

    return snapshot.docs
        .map((doc) => Shrine.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ==========================================
  // ⑤ ユーザーがお気に入りした神社の詳細をまとめて取得する関数
  // ==========================================
  Future<List<Shrine>> getFavoriteShrines(List<String> favoriteIds) async {
    if (favoriteIds.isEmpty) return [];

    final snapshot = await _db
        .collection('Shrines')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .get();

    return snapshot.docs
        .map((doc) => Shrine.fromFirestore(doc.data(), doc.id))
        .toList();
  }

 // ==========================================
  // ⑥ 神社一覧と、それぞれの神様（サブコレクション）をまとめて取得する関数
  // ==========================================
  Future<List<Shrine>> getShrinesWithKami() async {
    final shrineSnapshot = await _db.collection('Shrines').get();
    List<Shrine> shrines = [];

    for (var doc in shrineSnapshot.docs) {
      Shrine shrine = Shrine.fromFirestore(doc.data(), doc.id);

      // ★サブコレクションの名前も 'Kamis' などにする場合はここを変更します
      // （ここではFirestore上のコレクション名は 'Deities' のままと仮定しています）
      final kamiSnapshot = await _db
          .collection('Shrines')
          .doc(shrine.id)
          .collection('Deities') 
          .get();

      // ★変更：Deity から Kami に変更
      List<Kami> kamiList = kamiSnapshot.docs.map((kamiDoc) {
        return Kami.fromFirestore(kamiDoc.data(), kamiDoc.id);
      }).toList();

      shrine.kamis = kamiList; // ★変更：kamis にセット
      shrines.add(shrine);
    }
    return shrines;
  }

  // ==========================================
  // ⑦ 診断結果を履歴に保存しつつ、最新タイプも更新する関数
  // ==========================================
  Future<void> saveDiagnosticResult(String userId, int resultType) async {
    final userRef = _db.collection('Users').doc(userId);

    await userRef.collection('History').add({
      'resultType': resultType,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await userRef.update({
      'lastType': resultType,
    });
  }

  // ==========================================
  // ⑧ ユーザー情報と過去の診断履歴をまとめて取得する関数
  // ==========================================
  Future<AppUser?> getUserWithHistory(String userId) async {
    final userDoc = await _db.collection('Users').doc(userId).get();
    if (!userDoc.exists) return null;

    AppUser user = AppUser.fromFirestore(userDoc.data()!, userDoc.id);

    final historySnapshot = await _db
        .collection('Users')
        .doc(userId)
        .collection('History')
        .orderBy('createdAt', descending: true)
        .get();

    // ※もしhistory.dartのクラス名を History にしている場合は、以下の DiagnosticHistory を History に変えてください
    List<DiagnosticHistory> historyList = historySnapshot.docs.map((doc) {
      return DiagnosticHistory.fromFirestore(doc.data(), doc.id);
    }).toList();

    user.history = historyList;
    return user;
  }

  // ==========================================
  // ⑨ 【追加】質問データをFirebaseに保存（または上書き）する関数
  // ==========================================
  Future<void> setupQuestions(List<Map<String, dynamic>> questionsData) async {
    for (var data in questionsData) {
      await _db.collection('Questions').doc(data['id'] as String).set({
        'question': data['question'],
        'answer1': data['answer1'],
        'answer2': data['answer2'],
        'value': data['value'],
      });
    }
    print("質問データの保存・更新が完了しました！");
  }
}