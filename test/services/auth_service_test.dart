import 'package:flutter_test/flutter_test.dart';
import 'package:babycation/services/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      final mockAuth = MockFirebaseAuth();
      final mockFirestore = FakeFirebaseFirestore();
      authService = AuthService(auth: mockAuth, firestore: mockFirestore);
    });

    group('generateFriendCode', () {
      test('generates code with length between 6 and 8 characters', () {
        final code = authService.generateFriendCode();
        expect(code.length, greaterThanOrEqualTo(6));
        expect(code.length, lessThanOrEqualTo(8));
      });

      test('generates alphanumeric code', () {
        final code = authService.generateFriendCode();
        final alphanumericRegex = RegExp(r'^[A-Z0-9]+$');
        expect(alphanumericRegex.hasMatch(code), isTrue);
      });

      test('generates different codes on multiple calls', () {
        final codes = List.generate(
          10,
          (_) => authService.generateFriendCode(),
        );
        final uniqueCodes = codes.toSet();
        // With high probability, at least some codes should be different
        expect(uniqueCodes.length, greaterThan(1));
      });
    });
  });
}
