class Category {
  final String id;
  final String title;
  final String description;
  final int order;
  final String iconName;
  final bool isPremium;
  final int totalQuestions;

  Category({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.iconName,
    required this.isPremium,
    this.totalQuestions = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'order': order,
      'iconName': iconName,
      'isPremium': isPremium,
      'totalQuestions': totalQuestions,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      order: map['order'] as int,
      iconName: map['iconName'] as String,
      isPremium: map['isPremium'] as bool,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
    );
  }
}
