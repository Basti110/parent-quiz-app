import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/statistics_service.dart';
import '../models/user_statistics.dart';
import '../models/category_statistics.dart';

/// Provider for StatisticsService singleton
/// Requirements: 2.1, 2.2, 2.3
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

/// Provider for user statistics calculated from questionStates
/// Requirements: 2.1, 2.2, 2.3
final userStatisticsProvider = FutureProvider.family<UserStatistics, String>((
  ref,
  userId,
) {
  final statisticsService = ref.watch(statisticsServiceProvider);
  return statisticsService.getUserStatistics(userId);
});

/// Provider for category statistics for a specific user and category
/// Requirements: 2.1, 2.2, 2.3
final categoryStatisticsProvider = FutureProvider.family<CategoryStatistics, (String, String)>((
  ref,
  params,
) {
  final (userId, categoryId) = params;
  final statisticsService = ref.watch(statisticsServiceProvider);
  return statisticsService.getCategoryStatistics(userId, categoryId);
});
