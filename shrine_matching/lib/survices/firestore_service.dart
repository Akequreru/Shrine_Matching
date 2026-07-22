import 'package:cloud_firestore/cloud_firestore.dart';
// 先ほど作ったモデルをインポート（パスはご自身の環境に合わせてください）
import '../models/shrine.dart';
import '../models/question.dart';
import '../models/app_user.dart';

class FirestoreService {
  // Firestoreのインスタンス（通信窓口）を変数にしておく
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // ① 神社のデータを全件取得する関数
  // ==========================================
  Future<List<Shrine>> getShrines() async {
    // 'Shrines' コレクションからデータを取得
    final snapshot = await _db.collection('Shrines').get();

    // 取得したデータを、さっき作った Shrine モデルのリストに変換して返す
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
    required String userId, // ログイン中のユーザーID
    required String shrineId, // お気に入りした神社のID
    required bool isAdding, // 追加するならtrue、解除するならfalse
  }) async {
    final userRef = _db.collection('Users').doc(userId);
    final shrineRef = _db.collection('Shrines').doc(shrineId);

    if (isAdding) {
      // リストに追加する ＆ 神社側のお気に入り数を+1する
      await userRef.update({
        'favoriteShrineIds': FieldValue.arrayUnion([shrineId]),
      });
      await shrineRef.update({'favoriteCount': FieldValue.increment(1)});
    } else {
      // リストから削除する ＆ 神社側のお気に入り数を-1する
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
    // 'type' フィールドが一致する神社だけを取得
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

    // 'whereIn' を使うと、指定したIDリストに含まれるものを一発で取得できる
    final snapshot = await _db
        .collection('Shrines')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .get();

    return snapshot.docs
        .map((doc) => Shrine.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
