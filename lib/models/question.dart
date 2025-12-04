class Question {
  final String id;
  final String categoryId;
  final String text;
  final List<String> options;
  final List<int> correctIndices;
  final String explanation;
  final String? tips;
  final String? sourceLabel;
  final String? sourceUrl;
  final int difficulty;
  final bool isActive;

  Question({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.options,
    required this.correctIndices,
    required this.explanation,
    this.tips,
    this.sourceLabel,
    this.sourceUrl,
    required this.difficulty,
    required this.isActive,
  });

  bool get isSingleChoice => correctIndices.length == 1;

  bool get isMultipleChoice => correctIndices.length > 1;

  bool isCorrectAnswer(List<int> selectedIndices) {
    return selectedIndices.toSet().containsAll(correctIndices) &&
        correctIndices.toSet().containsAll(selectedIndices);
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'text': text,
      'options': options,
      'correctIndices': correctIndices,
      'explanation': explanation,
      'tips': tips,
      'sourceLabel': sourceLabel,
      'sourceUrl': sourceUrl,
      'difficulty': difficulty,
      'isActive': isActive,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    return Question(
      id: id,
      categoryId: map['categoryId'] as String,
      text: map['text'] as String,
      options: List<String>.from(map['options'] as List),
      correctIndices: List<int>.from(map['correctIndices'] as List),
      explanation: map['explanation'] as String,
      tips: map['tips'] as String?,
      sourceLabel: map['sourceLabel'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      difficulty: map['difficulty'] as int,
      isActive: map['isActive'] as bool,
    );
  }
}
