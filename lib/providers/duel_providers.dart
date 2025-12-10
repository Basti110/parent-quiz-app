import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/duel_model.dart';
import '../services/duel_service.dart';

/// Provider for DuelService singleton
/// Requirements: 10.2, 14.1, 14.2
final duelServiceProvider = Provider<DuelService>((ref) {
  return DuelService();
});

/// Provider for pending duel challenges (stream)
/// Requirements: 14.1
final pendingDuelsProvider = StreamProvider.family<List<DuelModel>, String>((
  ref,
  userId,
) {
  final service = ref.watch(duelServiceProvider);
  return service.getPendingDuels(userId);
});

/// Provider for active duels (stream)
/// Requirements: 14.2
final activeDuelsProvider = StreamProvider.family<List<DuelModel>, String>((
  ref,
  userId,
) {
  final service = ref.watch(duelServiceProvider);
  return service.getActiveDuels(userId);
});

/// Provider for completed duels (stream)
/// Requirements: 14.4
final completedDuelsProvider = StreamProvider.family<List<DuelModel>, String>((
  ref,
  userId,
) {
  final service = ref.watch(duelServiceProvider);
  return service.getCompletedDuels(userId);
});

/// Provider for a single duel (stream) for real-time updates
/// Requirements: 12.1, 13.1
final duelStreamProvider = StreamProvider.family<DuelModel, String>((
  ref,
  duelId,
) {
  final service = ref.watch(duelServiceProvider);
  return service.getDuelStream(duelId);
});
