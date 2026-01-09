import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feedback_service.dart';
import '../models/feedback.dart';

/// Provider for FeedbackService
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

/// Provider for user's feedback history
final userFeedbackProvider = FutureProvider.family<List<FeedbackBase>, String>(
  (ref, userId) async {
    final feedbackService = ref.watch(feedbackServiceProvider);
    return await feedbackService.getUserFeedback(userId);
  },
);