import 'history.dart'; // さっき作ったモデルをインポート

class AppUser {
  final String id;
  final String userName;
  final int lastType;
  final List<String> favoriteShrineIds;
  final String avatarUrl;
  final String coverUrl;

  // ★追加：過去の診断結果リスト（初期値は空）
  List<DiagnosticHistory> history;

  AppUser({
    required this.id,
    required this.userName,
    required this.lastType,
    required this.favoriteShrineIds,
    this.avatarUrl = '',
    this.coverUrl = '',
    this.history = const [], // ★追加：最初は空っぽにしておく
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      userName: data['userName'] ?? '',
      lastType: data['lastType'] ?? 0,
      favoriteShrineIds: List<String>.from(data['favoriteShrineIds'] ?? []),
      avatarUrl: data['avatarUrl'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      // history はサブコレクションから取得して後から入れるため、ここでは処理しない
    );
  }
}