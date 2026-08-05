import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shrine.dart';
import '../models/question.dart';
import '../models/app_user.dart';
import '../models/kami.dart'; // ★変更：kami.dart
import '../models/history.dart'; // ★変更：history.dart
import '../models/type_info.dart';
import '../models/crossing.dart';
import '../models/visit.dart';

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
  // ③-2 マッチング終了時にまとめてお気に入りへ追加する関数
  // ==========================================
  Future<void> addFavoriteShrines(String userId, List<String> shrineIds) async {
    if (shrineIds.isEmpty) return;

    final userRef = _db.collection('Users').doc(userId);
    final userDoc = await userRef.get();
    final existingFavorites = Set<String>.from(
      userDoc.data()?['favoriteShrineIds'] ?? [],
    );
    final newShrineIds = shrineIds
        .where((id) => !existingFavorites.contains(id))
        .toSet();

    if (newShrineIds.isEmpty) return;

    final batch = _db.batch();
    batch.update(userRef, {
      'favoriteShrineIds': FieldValue.arrayUnion(newShrineIds.toList()),
    });
    for (final shrineId in newShrineIds) {
      batch.update(_db.collection('Shrines').doc(shrineId), {
        'favoriteCount': FieldValue.increment(1),
      });
    }
    await batch.commit();
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

    // Firestore whereIn has a max item limit, so split into small chunks.
    const int whereInLimit = 10;
    final ids = favoriteIds.where((id) => id.trim().isNotEmpty).toList();
    final shrineById = <String, Shrine>{};

    for (int i = 0; i < ids.length; i += whereInLimit) {
      final end = (i + whereInLimit) > ids.length
          ? ids.length
          : i + whereInLimit;
      final chunk = ids.sublist(i, end);

      final snapshot = await _db
          .collection('Shrines')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        shrineById[doc.id] = Shrine.fromFirestore(doc.data(), doc.id);
      }
    }

    // Keep the same order as favorite IDs and skip deleted shrine docs.
    return ids.map((id) => shrineById[id]).whereType<Shrine>().toList();
  }

  // ==========================================
  // ⑤-2 ユーザーがお気に入りした神社のID一覧だけを取得する軽量版
  // ==========================================
  Future<List<String>> getFavoriteShrineIds(String userId) async {
    final userDoc = await _db.collection('Users').doc(userId).get();
    if (!userDoc.exists) return [];
    return List<String>.from(userDoc.data()?['favoriteShrineIds'] ?? []);
  }

  // ==========================================
  // ⑤-3 現在ログイン中ユーザーの「縁を結んだ神社」を取得する関数
  // ==========================================
  Future<List<Shrine>> getMatchedShrinesForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final favoriteIds = await getFavoriteShrineIds(uid);
    return getFavoriteShrines(favoriteIds);
  }

  // ==========================================
  // ⑥ 神社一覧と、それぞれの神様（サブコレクション）をまとめて取得する関数
  // ==========================================
  Future<List<Shrine>> getShrinesWithKami() async {
    final shrineSnapshot = await _db.collection('Shrines').get();
    final shrines = shrineSnapshot.docs
        .map((doc) => Shrine.fromFirestore(doc.data(), doc.id))
        .toList();

    // ★変更：神社ごとに1件ずつDeitiesを取りに行くと件数分の通信が発生して遅いため、
    // collectionGroupで全Deitiesを1回のクエリでまとめて取得し、親の神社IDでグルーピングする
    final deitiesSnapshot = await _db.collectionGroup('Deities').get();

    final kamiByShrineId = <String, List<Kami>>{};
    for (final kamiDoc in deitiesSnapshot.docs) {
      final shrineId = kamiDoc.reference.parent.parent!.id;
      kamiByShrineId
          .putIfAbsent(shrineId, () => [])
          .add(Kami.fromFirestore(kamiDoc.data(), kamiDoc.id));
    }

    for (final shrine in shrines) {
      shrine.kami = kamiByShrineId[shrine.id] ?? [];
    }

    return shrines;
  }

  // ==========================================
  // ⑥-2 Home画面の「同じ○○タイプの神社」欄用に、祭神のタイプが指定タイプと
  // 一致する神社を取得する関数（相性(matchTypes)ではなく、タイプそのものの一致で絞り込む）
  // ==========================================
  Future<List<Shrine>> getShrinesWithSameKamiType(int typeId) async {
    final shrines = await getShrinesWithKami();
    return shrines
        .where((shrine) => shrine.kami.any((kami) => kami.type == typeId))
        .toList();
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

    await userRef.update({'lastType': resultType});
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

  // ==========================================
  // ⑩ 診断結果のtypeIdに対応するTypeプロフィールを取得する関数
  // ==========================================
  Future<TypeInfo?> getType(int typeId) async {
    final doc = await _db.collection('Type').doc(typeId.toString()).get();
    if (!doc.exists) return null;
    return TypeInfo.fromFirestore(doc.data()!, doc.id);
  }

  // ==========================================
  // ⑪ 16タイプすべてのTypeプロフィールを取得する関数
  // ==========================================
  Future<List<TypeInfo>> getAllTypes() async {
    final snapshot = await _db.collection('Type').get();
    final types = snapshot.docs
        .map((doc) => TypeInfo.fromFirestore(doc.data(), doc.id))
        .toList();
    types.sort((a, b) => a.id.compareTo(b.id));
    return types;
  }

  // ==========================================
  // ⑫ 前回確認していない「すれ違い」記録を取得する関数
  // ==========================================
  Future<List<Crossing>> getUnseenCrossings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('Users')
        .doc(uid)
        .collection('Crossings')
        .where('seen', isEqualTo: false)
        .orderBy('crossedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Crossing.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ==========================================
  // ⑫-2 Home画面の「最近すれ違った神社」欄用に、直近の「すれ違い」記録を取得する関数
  // （既読/未読を問わず、新しい順にlimit件だけ）
  // ==========================================
  Future<List<Crossing>> getRecentCrossings({int limit = 5}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('Users')
        .doc(uid)
        .collection('Crossings')
        .orderBy('crossedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Crossing.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ==========================================
  // ⑬ 「すれ違い」記録を確認済みにする関数
  // ==========================================
  Future<void> markCrossingsAsSeen(List<String> crossingIds) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || crossingIds.isEmpty) return;

    final batch = _db.batch();
    for (final id in crossingIds) {
      batch.update(
        _db.collection('Users').doc(uid).collection('Crossings').doc(id),
        {'seen': true},
      );
    }
    await batch.commit();
  }

  // ==========================================
  // ⑭ 参拝を記録する関数
  // ==========================================
  Future<void> recordVisit(Shrine shrine) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('Users').doc(uid).collection('Visits').add({
      'shrineId': shrine.id,
      'shrineName': shrine.name,
      'image': shrine.images.isNotEmpty ? shrine.images.first : '',
      'tags': shrine.tags,
      'address': shrine.address,
      'visitedAt': FieldValue.serverTimestamp(),
    });

    // 参拝した神社は、次にそこから離れたときに「すれ違い」として二重に
    // 記録されないよう、印を残しておく（バックグラウンド側のEXIT検知で消費する）
    await _db
        .collection('Users')
        .doc(uid)
        .collection('PendingVisitSuppressions')
        .doc(shrine.id)
        .set({'markedAt': FieldValue.serverTimestamp()});
  }

  // ==========================================
  // ⑮ プロフィールのアイコン画像URLを更新する関数
  // ==========================================
  Future<void> updateAvatarUrl(String userId, String url) async {
    await _db.collection('Users').doc(userId).update({'avatarUrl': url});
  }

  // ==========================================
  // ⑯ プロフィールの背景画像URLを更新する関数
  // ==========================================
  Future<void> updateCoverUrl(String userId, String url) async {
    await _db.collection('Users').doc(userId).update({'coverUrl': url});
  }

  // ==========================================
  // ⑰ ユーザーの参拝件数を取得する関数
  // ==========================================
  Future<int> getVisitsCount(String userId) async {
    final snapshot = await _db
        .collection('Users')
        .doc(userId)
        .collection('Visits')
        .get();
    return snapshot.size;
  }

  // ==========================================
  // ⑰-2 現在ログイン中ユーザーの「参拝履歴」を新しい順に取得する関数
  // ==========================================
  Future<List<Visit>> getVisits({int? limit}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    Query<Map<String, dynamic>> query = _db
        .collection('Users')
        .doc(uid)
        .collection('Visits')
        .orderBy('visitedAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Visit.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // ==========================================
  // ⑱ ユーザーのすれ違い件数を取得する関数
  // ==========================================
  Future<int> getCrossingsCount(String userId) async {
    final snapshot = await _db
        .collection('Users')
        .doc(userId)
        .collection('Crossings')
        .get();
    return snapshot.size;
  }

  // ==========================================
  // ⑲ ランダムな神社一覧を取得する関数
  // ==========================================
  Future<List<Shrine>> getRandomShrines({int limit = 5}) async {
    final shrines = await getShrines();
    shrines.shuffle();

    if (shrines.length <= limit) {
      return shrines;
    }

    return shrines.take(limit).toList();
  }
}
