import 'package:cloud_firestore/cloud_firestore.dart';

class Visit {
  final String id;
  final String shrineId;
  final String shrineName;
  final String image;
  final List<String> tags;
  final String address;
  final DateTime visitedAt;

  Visit({
    required this.id,
    required this.shrineId,
    required this.shrineName,
    required this.image,
    required this.tags,
    required this.address,
    required this.visitedAt,
  });

  factory Visit.fromFirestore(Map<String, dynamic> data, String documentId) {
    DateTime parsedDate = DateTime.now();
    if (data['visitedAt'] != null) {
      parsedDate = (data['visitedAt'] as Timestamp).toDate();
    }

    return Visit(
      id: documentId,
      shrineId: data['shrineId'] ?? '',
      shrineName: data['shrineName'] ?? '',
      image: data['image'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      address: data['address'] ?? '',
      visitedAt: parsedDate,
    );
  }
}
