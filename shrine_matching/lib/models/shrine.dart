class Shrine {
  final String id;
  final String name;
  final List<String> images;
  final String type;
  final String concept;
  final String description;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final String address;
  final int favoriteCount;

  Shrine({
    required this.id,
    required this.name,
    required this.images,
    required this.type,
    required this.concept,
    required this.description,
    required this.tags,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.favoriteCount,
  });

  factory Shrine.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Shrine(
      id: documentId,
      name: data['name'] ?? '', // データが無い場合は空文字にする安全対策
      images: List<String>.from(
        data['images'] ?? [],
      ), // FirebaseのリストをDartのリストに変換
      type: data['type'] ?? '',
      concept: data['concept'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      favoriteCount: data['favoriteCount'] ?? 0,
    );
  }
}
