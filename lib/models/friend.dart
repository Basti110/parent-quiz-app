import 'package:cloud_firestore/cloud_firestore.dart';

class OpenChallenge {
  final String duelId;
  final String challengerId;
  final DateTime createdAt;
  final String status; // 'pending' or 'accepted'

  OpenChallenge({
    required this.duelId,
    required this.challengerId,
    required this.createdAt,
    this.status = 'pending',
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  Map<String, dynamic> toMap() {
    return {
      'duelId': duelId,
      'challengerId': challengerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory OpenChallenge.fromMap(Map<String, dynamic> map) {
    return OpenChallenge(
      duelId: map['duelId'] as String,
      challengerId: map['challengerId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'pending',
    );
  }
}

class Friend {
  final String friendUserId;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final String? avatarPath;
  
  // Head-to-head duel statistics
  final int myWins;
  final int theirWins;
  final int ties;
  final int totalDuels;

  // Active challenge tracking
  final OpenChallenge? openChallenge;

  Friend({
    required this.friendUserId,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.avatarPath,
    this.myWins = 0,
    this.theirWins = 0,
    this.ties = 0,
    this.totalDuels = 0,
    this.openChallenge,
  });

  /// Returns formatted head-to-head record (e.g., "5-3-1")
  String getRecordString() {
    return '$myWins-$theirWins-$ties';
  }

  /// Returns true if user is leading in head-to-head
  bool isLeading() {
    return myWins > theirWins;
  }

  /// Returns true if tied in head-to-head
  bool isTied() {
    return myWins == theirWins;
  }

  /// Returns true if there's an open challenge from this friend
  bool hasIncomingChallenge(String currentUserId) {
    return openChallenge != null && openChallenge!.challengerId != currentUserId;
  }

  /// Returns true if there's an open challenge sent to this friend
  bool hasOutgoingChallenge(String currentUserId) {
    return openChallenge != null && openChallenge!.challengerId == currentUserId;
  }

  /// Returns true if there's any active challenge (incoming or outgoing)
  bool hasAnyChallenge() {
    return openChallenge != null;
  }

  Map<String, dynamic> toMap() {
    return {
      'friendUserId': friendUserId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'avatarPath': avatarPath,
      'myWins': myWins,
      'theirWins': theirWins,
      'ties': ties,
      'totalDuels': totalDuels,
      'openChallenge': openChallenge?.toMap(),
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      friendUserId: map['friendUserId'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      avatarPath: map['avatarPath'] as String?,
      myWins: map['myWins'] as int? ?? 0,
      theirWins: map['theirWins'] as int? ?? 0,
      ties: map['ties'] as int? ?? 0,
      totalDuels: map['totalDuels'] as int? ?? 0,
      openChallenge: map['openChallenge'] != null 
          ? OpenChallenge.fromMap(map['openChallenge'] as Map<String, dynamic>)
          : null,
    );
  }
}
