import 'package:cloud_firestore/cloud_firestore.dart';

class Crossing {
  final String id;
  final String shrineId;
  final String shrineName;
  final String image;
  final List<String> tags;
  final String address;
  final DateTime crossedAt;

  Crossing({
    required this.id,
    required this.shrineId,
    required this.shrineName,
    required this.image,
    required this.tags,
    required this.address,
    required this.crossedAt,
  });

  factory Crossing.fromFirestore(Map<String, dynamic> data, String documentId) {
    DateTime parsedDate = DateTime.now();
    if (data['crossedAt'] != null) {
      parsedDate = (data['crossedAt'] as Timestamp).toDate();
    }

    return Crossing(
      id: documentId,
      shrineId: data['shrineId'] ?? '',
      shrineName: data['shrineName'] ?? '',
      image: data['image'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      address: data['address'] ?? '',
      crossedAt: parsedDate,
    );
  }
}
