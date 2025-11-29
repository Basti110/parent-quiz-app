import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

/// Provider for AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for authentication state changes stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// Provider for UserService singleton
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Provider for user data stream (requires userId parameter)
final userDataProvider = StreamProvider.family<UserModel, String>((
  ref,
  userId,
) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserStream(userId);
});
