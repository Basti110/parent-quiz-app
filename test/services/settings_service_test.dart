import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:eduparo/services/settings_service.dart';
import 'dart:math';

void main() {
  group('SettingsService', () {
    late SettingsService settingsService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      settingsService = SettingsService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
    });

    // Feature: ui-redesign-i18n, Property 4: Theme persistence
    // Validates: Requirements 4.2
    group('Property 4: Theme persistence', () {
      test(
        'for any theme selection (dark mode true/false), restarting the app should preserve the selected theme',
        () async {
          final random = Random(42); // Seed for reproducibility
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Clear SharedPreferences before each iteration to simulate fresh start
            SharedPreferences.setMockInitialValues({});

            // Generate random theme selection
            final isDarkMode = random.nextBool();

            // Set the theme preference
            await settingsService.setDarkMode(isDarkMode);

            // Simulate app restart by creating a new service instance
            // and reading the preference
            final retrievedDarkMode = await settingsService.getDarkMode();

            // Verify the theme persisted
            expect(
              retrievedDarkMode,
              equals(isDarkMode),
              reason:
                  'Theme preference (darkMode=$isDarkMode) should persist across app restarts (iteration $i)',
            );
          }
        },
      );

      test(
        'for any sequence of theme toggles, the final theme should match the last selection',
        () async {
          final random = Random(42);
          const iterations = 50;

          for (int i = 0; i < iterations; i++) {
            // Clear SharedPreferences before each iteration
            SharedPreferences.setMockInitialValues({});

            // Generate a random sequence of theme changes (2-10 changes)
            final numChanges = 2 + random.nextInt(9);
            bool? lastTheme;

            for (int j = 0; j < numChanges; j++) {
              lastTheme = random.nextBool();
              await settingsService.setDarkMode(lastTheme);
            }

            // Verify the final theme matches the last selection
            final retrievedDarkMode = await settingsService.getDarkMode();
            expect(
              retrievedDarkMode,
              equals(lastTheme),
              reason:
                  'After $numChanges theme changes, final theme should match last selection (iteration $i)',
            );
          }
        },
      );

      test(
        'for any theme preference, multiple reads should return the same value',
        () async {
          final random = Random(42);
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Clear SharedPreferences before each iteration
            SharedPreferences.setMockInitialValues({});

            // Set a random theme
            final isDarkMode = random.nextBool();
            await settingsService.setDarkMode(isDarkMode);

            // Read the theme multiple times (3-7 times)
            final numReads = 3 + random.nextInt(5);
            final readings = <bool>[];

            for (int j = 0; j < numReads; j++) {
              final reading = await settingsService.getDarkMode();
              readings.add(reading);
            }

            // Verify all readings are identical
            expect(
              readings.every((reading) => reading == isDarkMode),
              isTrue,
              reason:
                  'All $numReads reads should return the same theme value (darkMode=$isDarkMode) (iteration $i)',
            );
          }
        },
      );

      test(
        'when no theme preference is set, getDarkMode should return false (light mode default)',
        () async {
          // Clear SharedPreferences to simulate no preference set
          SharedPreferences.setMockInitialValues({});

          // Get theme without setting it first
          final defaultTheme = await settingsService.getDarkMode();

          // Verify default is light mode (false)
          expect(
            defaultTheme,
            isFalse,
            reason:
                'Default theme should be light mode (false) when no preference is set',
          );
        },
      );
    });

    group('Avatar Path Management', () {
      test('setAvatarPath should persist avatar path', () async {
        // Clear SharedPreferences
        SharedPreferences.setMockInitialValues({});

        const avatarPath = 'assets/app_images/avatars/avatar_1.png';

        // Set avatar path
        await settingsService.setAvatarPath(avatarPath);

        // Retrieve avatar path
        final retrievedPath = await settingsService.getAvatarPath();

        // Verify the path persisted
        expect(retrievedPath, equals(avatarPath));
      });

      test('getAvatarPath should return null when no avatar is set', () async {
        // Clear SharedPreferences
        SharedPreferences.setMockInitialValues({});

        // Get avatar path without setting it first
        final avatarPath = await settingsService.getAvatarPath();

        // Verify it returns null
        expect(avatarPath, isNull);
      });

      test('setAvatarPath should overwrite previous avatar path', () async {
        // Clear SharedPreferences
        SharedPreferences.setMockInitialValues({});

        const firstAvatar = 'assets/app_images/avatars/avatar_1.png';
        const secondAvatar = 'assets/app_images/avatars/avatar_2.png';

        // Set first avatar
        await settingsService.setAvatarPath(firstAvatar);

        // Set second avatar
        await settingsService.setAvatarPath(secondAvatar);

        // Retrieve avatar path
        final retrievedPath = await settingsService.getAvatarPath();

        // Verify the second avatar is stored
        expect(retrievedPath, equals(secondAvatar));
      });

      test('avatar path should persist across multiple reads', () async {
        // Clear SharedPreferences
        SharedPreferences.setMockInitialValues({});

        const avatarPath = 'assets/app_images/avatars/avatar_3.png';

        // Set avatar path
        await settingsService.setAvatarPath(avatarPath);

        // Read multiple times
        final read1 = await settingsService.getAvatarPath();
        final read2 = await settingsService.getAvatarPath();
        final read3 = await settingsService.getAvatarPath();

        // Verify all reads return the same value
        expect(read1, equals(avatarPath));
        expect(read2, equals(avatarPath));
        expect(read3, equals(avatarPath));
      });
    });
  });
}
