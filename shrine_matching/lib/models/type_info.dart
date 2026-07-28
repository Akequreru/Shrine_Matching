class TypeInfo {
  final int id;
  final String name;
  final String image;
  final String mbti;
  final String concept;
  final String description;
  final String paraphrase;
  final String attitude;
  final String favorite;

  TypeInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.mbti,
    required this.concept,
    required this.description,
    required this.paraphrase,
    required this.attitude,
    required this.favorite,
  });

  factory TypeInfo.fromFirestore(Map<String, dynamic> data) {
    return TypeInfo(
      id: data['id'] ?? 0,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      mbti: data['mbti'] ?? '',
      concept: data['concept'] ?? '',
      description: data['description'] ?? '',
      paraphrase: data['paraphrase'] ?? '',
      attitude: data['attitude'] ?? '',
      favorite: data['favorite'] ?? '',
    );
  }
}
