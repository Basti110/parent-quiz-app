# Implementation Plan: Statistics and Counting Fixes

- [x] 1. Update Category Model and QuizService
  - Add `questionCounter` field to Category model
  - Update Category.fromMap() to read the new field
  - Update QuizService.getQuestionCountForCategory() to use the field with fallback
  - _Requirements: 1.1, 1.4, 1.5_

- [ ]* 1.1 Write property test for question counter fallback
  - **Feature: statistics-and-counting-fixes, Property 3: Fallback to query when counter missing**
  - **Validates: Requirements 1.5**

- [x] 2. Create Statistics Service and Models
  - Create CategoryStatistics model with calculated properties
  - Create UserStatistics model with aggregation logic
  - Create StatisticsService with getUserStatistics() method
  - Implement statistics calculation from questionStates subcollection
  - _Requirements: 2.1, 2.2, 2.3_

- [ ]* 2.1 Write property test for seen questions count
  - **Feature: statistics-and-counting-fixes, Property 4: Seen questions count accuracy**
  - **Validates: Requirements 2.1**

- [ ]* 2.2 Write property test for correct questions count
  - **Feature: statistics-and-counting-fixes, Property 5: Correct questions count accuracy**
  - **Validates: Requirements 2.2**

- [ ]* 2.3 Write property test for mastered questions count
  - **Feature: statistics-and-counting-fixes, Property 6: Mastered questions count accuracy**
  - **Validates: Requirements 2.3**

- [x] 3. Create Statistics Providers
  - Create statisticsServiceProvider
  - Create userStatisticsProvider with FutureProvider.family
  - Create categoryStatisticsProvider with FutureProvider.family
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 3.1 Write property test for category statistics accuracy
  - **Feature: statistics-and-counting-fixes, Property 8: Category answered count accuracy**
  - **Validates: Requirements 5.2**

- [x] 3.2 Write property test for statistics consistency
  - **Feature: statistics-and-counting-fixes, Property 13: Statistics consistency across calls**
  - **Validates: Requirements 2.1, 2.2, 2.3**

- [x] 4. Create Statistics Screen
  - Create StatisticsScreen widget with ConsumerWidget
  - Display overall statistics (answered, mastered, seen)
  - Display category-level statistics in a list with category icons
  - Show progress bars for each category
  - Implement loading and error states
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.2_

- [x] 4.1 Write unit tests for statistics screen
  - Test that overall statistics are displayed
  - Test that category statistics are displayed
  - Test loading state
  - Test error state with retry
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 5. Update Main Navigation
  - Add statistics route to main_navigation.dart
  - Add statistics tab to navigation bar as last item
  - Implement tab highlighting when statistics screen is active
  - _Requirements: 4.1, 4.2, 4.3_

- [ ]* 5.1 Write unit tests for navigation integration
  - Test that statistics tab appears in navbar
  - Test that tapping statistics tab navigates to screen
  - Test that statistics tab is highlighted when active
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 6. Create Migration Script
  - Create migration script to populate questionCounter for all categories
  - Verify that stored counts match calculated counts
  - Log any discrepancies
  - Handle errors gracefully
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 6.1 Write unit tests for migration script
  - Test that questionCounter is populated for all categories
  - Test that counts are accurate
  - Test error handling
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7. Update CategoryCard Widget
  - Update CategoryCard to use questionCounter from category model
  - Remove dynamic question count calculation
  - _Requirements: 1.4_

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Integration Testing
  - Test complete flow: answer questions → view statistics → verify accuracy
  - Test category statistics accuracy
  - Test statistics update after answering questions
  - _Requirements: 2.1, 2.2, 2.3, 5.2, 5.3, 5.4_

- [x] 10. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
