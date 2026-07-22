class AppUser {
  final String id;
  final String userName;
  final int lastType;
  final List<String> favoriteShrineIds;

  AppUser({
    required this.id,
    required this.userName,
    required this.lastType,
    required this.favoriteShrineIds,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      userName: data['userName'] ?? '', // データが無い場合は空文字にする安全対策
      lastType: data['lastType'] ?? 0,
      favoriteShrineIds: List<String>.from(data['favoriteShrineIds'] ?? []),
    );
  }
}
