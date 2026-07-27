import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosticHistory {
  final String id;
  final int resultType;  // 診断結果（1〜16の整数）
  final DateTime createdAt; // 診断した日時

  DiagnosticHistory({
    required this.id,
    required this.resultType,
    required this.createdAt,
  });

  factory DiagnosticHistory.fromFirestore(Map<String, dynamic> data, String documentId) {
    // FirestoreのTimestamp型を、Dartで扱いやすいDateTime型に変換
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] != null) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    }

    return DiagnosticHistory(
      id: documentId,
      resultType: data['resultType'] ?? 0,
      createdAt: parsedDate,
    );
  }
}