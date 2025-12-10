import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:babycation/services/user_service.dart';

void main() {
  group('UserService - Simple Tests', () {
    late UserService userService;

    setUp(() {
      final fakeFirestore = FakeFirebaseFirestore();
      userService = UserService(firestore: fakeFirestore);
    });

    // Feature: simplified-gamification, Property 1: Daily goal bounds
    // Validates: Requirements 1.3
    test('calculateStreakPoints returns 0 for streaks 1-2', () {
      expect(userService.calculateStreakPoints(1), equals(0));
      expect(userService.calculateStreakPoints(2), equals(0));
    });

    test('calculateStreakPoints returns 3 for streak 3', () {
      expect(userService.calculateStreakPoints(3), equals(3));
    });

    test('calculateStreakPoints returns 3 for streaks > 3', () {
      expect(userService.calculateStreakPoints(4), equals(3));
      expect(userService.calculateStreakPoints(10), equals(3));
      expect(userService.calculateStreakPoints(100), equals(3));
    });
  });
}
