class Kami {
  final String id;
  final String name;             // 神様・人物の名前（例：源頼政）
  final int type;             // MBTIタイプ（例：ISTJ）
  final String description;      // 説明（例：忠義と責任感を重んじた武将。）
  final List<int> matchTypes; // 相性の良いタイプ（例：[ENFP, ESFP]）

  Kami({
    required this.id,
    required this.name,
    required this.mbti,
    required this.description,
    required this.matchTypes,
  });

  factory Kami.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Kami(
      id: documentId,
      name: data['name'] ?? '',
      mbti: data['mbti'] ?? '',
      description: data['description'] ?? '',
      matchTypes: List<String>.from(data['matchTypes'] ?? []),
    );
  }
}