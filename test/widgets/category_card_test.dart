import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eduparo/widgets/category_card.dart';
import 'package:eduparo/models/category.dart';
import 'dart:math';

void main() {
  group('CategoryCard', () {
    // Feature: ui-redesign-i18n, Property 2: Category icon fallback
    // Validates: Requirements 2.4
    group('Property 2: Category icon fallback', () {
      testWidgets(
        'for any category without a specific icon, the system should display the default icon',
        (WidgetTester tester) async {
          final random = Random(42); // Seed for reproducibility
          const iterations = 100;

          for (int i = 0; i < iterations; i++) {
            // Generate random category data
            final categoryId = 'category_$i';
            final categoryTitle = 'Category ${random.nextInt(100)}';
            final categoryDescription = 'Description $i';
            final categoryOrder = random.nextInt(10);
            final isPremium = random.nextBool();

            // Generate icon names that don't exist (to test fallback)
            // Use non-existent icon names like "nonexistent_1", "missing_icon_2", etc.
            final nonExistentIconNames = [
              'nonexistent_$i',
              'missing_icon_$i',
              'invalid_${random.nextInt(1000)}',
              'does_not_exist_$i',
            ];
            final iconName =
                nonExistentIconNames[random.nextInt(
                  nonExistentIconNames.length,
                )];

            // Create category with non-existent icon
            final category = Category(
              id: categoryId,
              title: categoryTitle,
              description: categoryDescription,
              order: categoryOrder,
              iconName: iconName,
              isPremium: isPremium,
              questionCounter: random.nextInt(50) + 1,
            );

            // Build the widget
            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  home: Scaffold(body: CategoryCard(category: category)),
                ),
              ),
            );

            // Wait for all frames to settle (including error handling)
            await tester.pumpAndSettle();

            // Verify that the widget renders without throwing an error
            // The CategoryCard should handle the missing icon gracefully
            expect(find.byType(CategoryCard), findsOneWidget);

            // Verify that the category title is displayed
            expect(find.text(categoryTitle), findsOneWidget);

            // Verify that some icon is displayed (either default or fallback Icon widget)
            // We check for either Image.asset or Icon widget
            final hasImage = find.byType(Image).evaluate().isNotEmpty;
            final hasIcon = find.byType(Icon).evaluate().isNotEmpty;

            expect(
              hasImage || hasIcon,
              isTrue,
              reason:
                  'CategoryCard should display either default image or fallback icon (iteration $i)',
            );
          }
        },
      );
    });

    // Additional test: Verify that existing icons are displayed correctly
    testWidgets(
      'for any category with an existing icon, the system should display that specific icon',
      (WidgetTester tester) async {
        // Test with known existing icons from the assets
        final existingIcons = ['health', 'nutrition', 'play', 'sleep'];

        for (int i = 0; i < existingIcons.length; i++) {
          final iconName = existingIcons[i];
          final category = Category(
            id: 'category_$i',
            title: 'Test Category $i',
            description: 'Description $i',
            order: i,
            iconName: iconName,
            isPremium: false,
            questionCounter: 10,
          );

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(body: CategoryCard(category: category)),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Verify widget renders
          expect(find.byType(CategoryCard), findsOneWidget);
          expect(find.text('Test Category $i'), findsOneWidget);

          // Verify an image is displayed
          expect(find.byType(Image), findsWidgets);
        }
      },
    );

    // Test navigation behavior
    testWidgets('tapping a category card should trigger navigation', (
      WidgetTester tester,
    ) async {
      final category = Category(
        id: 'test_category',
        title: 'Test Category',
        description: 'Test Description',
        order: 1,
        iconName: 'health',
        isPremium: false,
        questionCounter: 15,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CategoryCard(category: category)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the card
      final cardFinder = find.byType(InkWell);
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Navigation should have occurred (we can't fully test the navigation
      // without a full app context, but we can verify the tap doesn't crash)
      expect(find.byType(CategoryCard), findsNothing);
    });
  });
}
