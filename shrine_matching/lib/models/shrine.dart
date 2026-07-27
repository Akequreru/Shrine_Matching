import 'kami.dart'; // 先ほど作った神様モデルをインポート

class Shrine {
  final String id;
  final String name;
  final List<String> images;
  final String concept;
  final String description;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final String address;
  final int favoriteCount;
  
  // ★追加：この神社に祀られている神様のリスト（初期値は空）
  List<Kami> deities; 

  Shrine({
    required this.id,
    required this.name,
    required this.images,
    required this.concept,
    required this.description,
    required this.tags,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.favoriteCount,
    this.deities = const [], // ★追加：最初は空っぽにしておく
  });

  factory Shrine.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Shrine(
      id: documentId,
      name: data['name'] ?? '', 
      images: List<String>.from(data['images'] ?? []), 
      concept: data['concept'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      favoriteCount: data['favoriteCount'] ?? 0,
      // deities はサブコレクションから別途取得して後から入れるため、ここでは処理しない
    );
  }
}