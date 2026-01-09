import 'package:cloud_firestore/cloud_firestore.dart';

/// Base feedback model with common fields
abstract class FeedbackBase {
  final String? id;
  final DateTime createdAt;
  final String userComment;
  final String userId;
  final String username;
  final String status;
  final AppContext appContext;

  const FeedbackBase({
    this.id,
    required this.createdAt,
    required this.userComment,
    required this.userId,
    required this.username,
    required this.status,
    required this.appContext,
  });

  Map<String, dynamic> toMap();
  String get type;
}

/// App context information
class AppContext {
  final String version;
  final String os;
  final String? childAgeGroup;

  const AppContext({
    required this.version,
    required this.os,
    this.childAgeGroup,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'os': os,
      if (childAgeGroup != null) 'child_age_group': childAgeGroup,
    };
  }

  factory AppContext.fromMap(Map<String, dynamic> map) {
    return AppContext(
      version: map['version'] as String,
      os: map['os'] as String,
      childAgeGroup: map['child_age_group'] as String?,
    );
  }
}

/// Question snapshot for feedback
class QuestionSnapshot {
  final String text;
  final List<String> options;
  final List<int> correctIndices;
  final String explanation;
  final String? tips;
  final String? sourceLabel;
  final String? sourceUrl;
  final int difficulty;
  final String categoryTitle;

  const QuestionSnapshot({
    required this.text,
    required this.options,
    required this.correctIndices,
    required this.explanation,
    this.tips,
    this.sourceLabel,
    this.sourceUrl,
    required this.difficulty,
    required this.categoryTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correct_indices': correctIndices,
      'explanation': explanation,
      if (tips != null) 'tips': tips,
      if (sourceLabel != null) 'source_label': sourceLabel,
      if (sourceUrl != null) 'source_url': sourceUrl,
      'difficulty': difficulty,
      'category_title': categoryTitle,
    };
  }

  factory QuestionSnapshot.fromMap(Map<String, dynamic> map) {
    return QuestionSnapshot(
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List),
      correctIndices: List<int>.from(map['correct_indices'] as List),
      explanation: map['explanation'] as String,
      tips: map['tips'] as String?,
      sourceLabel: map['source_label'] as String?,
      sourceUrl: map['source_url'] as String?,
      difficulty: map['difficulty'] as int,
      categoryTitle: map['category_title'] as String,
    );
  }
}

/// Common feedback from settings screen
class CommonFeedback extends FeedbackBase {
  final int ratingApp;
  final int ratingTheme;
  final int ratingDuelMode;
  final int learningFactor;
  final int scientificTrust;
  final String doBetter;
  final String futureFeatures;

  const CommonFeedback({
    super.id,
    required super.createdAt,
    required super.userComment,
    required super.userId,
    required super.username,
    required super.status,
    required super.appContext,
    required this.ratingApp,
    required this.ratingTheme,
    required this.ratingDuelMode,
    required this.learningFactor,
    required this.scientificTrust,
    required this.doBetter,
    required this.futureFeatures,
  });

  @override
  String get type => 'common';

  @override
  Map<String, dynamic> toMap() {
    return {
      'created_at': FieldValue.serverTimestamp(),
      'user_comment': userComment,
      'user_id': userId,
      'username': username,
      'status': status,
      'type': type,
      'app_context': appContext.toMap(),
      'data': {
        'rating_app': ratingApp,
        'rating_theme': ratingTheme,
        'rating_duel_mode': ratingDuelMode,
        'learning_factor': learningFactor,
        'scientific_trust': scientificTrust,
        'do_better': doBetter,
        'future_features': futureFeatures,
      },
    };
  }

  factory CommonFeedback.fromMap(Map<String, dynamic> map, String id) {
    final data = map['data'] as Map<String, dynamic>;
    return CommonFeedback(
      id: id,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      userComment: map['user_comment'] as String,
      userId: map['user_id'] as String,
      username: map['username'] as String,
      status: map['status'] as String,
      appContext: AppContext.fromMap(map['app_context'] as Map<String, dynamic>),
      ratingApp: data['rating_app'] as int,
      ratingTheme: data['rating_theme'] as int,
      ratingDuelMode: data['rating_duel_mode'] as int,
      learningFactor: data['learning_factor'] as int,
      scientificTrust: data['scientific_trust'] as int,
      doBetter: data['do_better'] as String,
      futureFeatures: data['future_features'] as String,
    );
  }
}

/// Question-specific feedback from quiz screens
class QuestionFeedback extends FeedbackBase {
  final String questionId;
  final String category;
  final String issueType;
  final QuestionSnapshot questionSnapshot;

  const QuestionFeedback({
    super.id,
    required super.createdAt,
    required super.userComment,
    required super.userId,
    required super.username,
    required super.status,
    required super.appContext,
    required this.questionId,
    required this.category,
    required this.issueType,
    required this.questionSnapshot,
  });

  @override
  String get type => 'question';

  @override
  Map<String, dynamic> toMap() {
    return {
      'created_at': FieldValue.serverTimestamp(),
      'user_comment': userComment,
      'user_id': userId,
      'username': username,
      'status': status,
      'type': type,
      'app_context': appContext.toMap(),
      'data': {
        'question_id': questionId,
        'category': category,
        'issue_type': issueType,
        'question_snapshot': questionSnapshot.toMap(),
      },
    };
  }

  factory QuestionFeedback.fromMap(Map<String, dynamic> map, String id) {
    final data = map['data'] as Map<String, dynamic>;
    return QuestionFeedback(
      id: id,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      userComment: map['user_comment'] as String,
      userId: map['user_id'] as String,
      username: map['username'] as String,
      status: map['status'] as String,
      appContext: AppContext.fromMap(map['app_context'] as Map<String, dynamic>),
      questionId: data['question_id'] as String,
      category: data['category'] as String,
      issueType: data['issue_type'] as String,
      questionSnapshot: QuestionSnapshot.fromMap(data['question_snapshot'] as Map<String, dynamic>),
    );
  }
}

/// Issue types for question feedback
enum QuestionIssueType {
  typo('typo'),
  contentOutdated('content_outdated'),
  brokenLink('broken_link'),
  other('other');

  const QuestionIssueType(this.value);
  final String value;

  static QuestionIssueType fromString(String value) {
    return QuestionIssueType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionIssueType.other,
    );
  }
}