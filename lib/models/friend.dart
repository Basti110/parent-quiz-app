import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String friendUserId;
  final String status;
  final DateTime createdAt;
  final String createdBy;

  Friend({
    required this.friendUserId,
    required this.status,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'friendUserId': friendUserId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      friendUserId: map['friendUserId'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
    );
  }
}
