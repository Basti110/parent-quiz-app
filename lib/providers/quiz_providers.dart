import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_service.dart';
import '../services/question_pool_service.dart';
import '../services/pool_metadata_service.dart';
import '../models/category.dart';

/// Provider for QuizService singleton
/// Requirements: 3.2, 4.1
final quizServiceProvider = Provider<QuizService>((ref) {
  final questionPoolService = ref.watch(questionPoolServiceProvider);
  return QuizService(
    questionPoolService: questionPoolService,
    usePoolArchitecture: true, // Enable pool architecture by default
  );
});

/// Provider for PoolMetadataService singleton
/// Requirements: 2.1, 4.1
final poolMetadataServiceProvider = Provider<PoolMetadataService>((ref) {
  return PoolMetadataService();
});

/// Provider for QuestionPoolService singleton
/// Requirements: 1.1, 1.2, 1.3, 1.4, 6.4
final questionPoolServiceProvider = Provider<QuestionPoolService>((ref) {
  final poolMetadataService = ref.watch(poolMetadataServiceProvider);
  return QuestionPoolService(poolMetadataService: poolMetadataService);
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
