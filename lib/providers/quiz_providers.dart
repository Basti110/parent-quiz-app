import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_service.dart';
import '../models/category.dart';

/// Provider for QuizService singleton
/// Requirements: 3.2, 4.1
final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService();
});

/// Provider for loading all categories
/// Requirements: 3.2
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  final quizService = ref.watch(quizServiceProvider);
  return quizService.getCategories();
});

/// Provider for counting questions in a category
/// Requirements: 3.2
final questionCountProvider = FutureProvider.family<int, String>((
  ref,
  categoryId,
) {
  final quizService = ref.watch(quizServiceProvider);
  return quizService.getQuestionCountForCategory(categoryId);
});
