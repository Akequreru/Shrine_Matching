class Kami {
  final String id;
  final String name;             // 神様・人物の名前（例：源頼政）
  final int type;             // MBTIタイプ（例：ISTJ）
  final String description;      // 説明（例：忠義と責任感を重んじた武将。）
  final List<int> matchTypes; // 相性の良いタイプ（例：[ENFP, ESFP]）
  final Map<int, String> matchReasons; // 相性の良いタイプごとの、なぜ相性がいいかの説明文

  Kami({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.matchTypes,
    this.matchReasons = const {},
  });

  factory Kami.fromFirestore(Map<String, dynamic> data, String documentId) {
    final rawReasons = data['matchReasons'] as Map<String, dynamic>? ?? {};

    return Kami(
      id: documentId,
      name: data['name'] ?? '',
      type: data['mbti'] ?? 0,
      description: data['description'] ?? '',
      matchTypes: List<int>.from(data['matchTypes'] ?? []),
      matchReasons: rawReasons.map(
        (key, value) => MapEntry(int.tryParse(key) ?? 0, value as String? ?? ''),
      ),
    );
  }
}