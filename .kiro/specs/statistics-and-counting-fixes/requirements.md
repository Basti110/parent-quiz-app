# Requirements Document: Statistics and Counting Fixes

## Introduction

This specification addresses three critical issues with the gamification system:
1. Category question counters are calculated dynamically instead of using a stored field
2. Question statistics (answered, correct, mastered) are stored as denormalized counts instead of being calculated from question states
3. There is no dedicated statistics screen to display user progress

These fixes improve performance, data consistency, and user visibility into their learning progress.

## Glossary

- **System**: The parent quiz application
- **Category**: A quiz topic with associated questions
- **Question Counter**: A field in the category document storing the total number of active questions
- **Question State**: A document tracking user progress on a specific question (seen count, correct count, mastery status)
- **Statistics Screen**: A new UI screen displaying aggregated user learning metrics
- **Seen Count**: Number of times a user has encountered a specific question
- **Correct Count**: Number of times a user has answered a specific question correctly
- **Mastered Question**: A question where the user's correct count is 3 or more

## Requirements

### Requirement 1: Category Question Counter Field

**User Story:** As a system administrator, I want categories to store their question count in a dedicated field, so that the app doesn't need to calculate it dynamically on every load.

#### Acceptance Criteria

1. WHEN a category document is created THEN the System SHALL include a `questionCounter` field with the count of active questions
2. WHEN questions are added to a category THEN the System SHALL update the category's `questionCounter` field
3. WHEN questions are removed from a category THEN the System SHALL update the category's `questionCounter` field
4. WHEN displaying a category THEN the System SHALL read the `questionCounter` field instead of querying all questions
5. WHEN the `questionCounter` field is missing THEN the System SHALL fall back to querying active questions for that category

### Requirement 2: Dynamic Question Statistics Calculation

**User Story:** As a developer, I want question statistics to be calculated from question states rather than stored as denormalized counts, so that the data remains consistent and accurate.

#### Acceptance Criteria

1. WHEN retrieving user statistics THEN the System SHALL count questions in the `questionStates` subcollection where `seenCount > 0`
2. WHEN retrieving user statistics THEN the System SHALL count questions in the `questionStates` subcollection where `correctCount > 0`
3. WHEN retrieving user statistics THEN the System SHALL count questions in the `questionStates` subcollection where `mastered == true`
4. WHEN a user answers a question THEN the System SHALL update the corresponding `questionState` document
5. WHEN displaying user statistics THEN the System SHALL calculate totals from `questionStates` instead of reading stored counts

### Requirement 3: Statistics Screen

**User Story:** As a user, I want to see a dedicated statistics screen showing my learning progress, so that I can track how many questions I've answered, mastered, and seen.

#### Acceptance Criteria

1. WHEN the user navigates to the statistics screen THEN the System SHALL display total questions answered
2. WHEN the user navigates to the statistics screen THEN the System SHALL display total questions mastered
3. WHEN the user navigates to the statistics screen THEN the System SHALL display total questions seen
4. WHEN the user navigates to the statistics screen THEN the System SHALL display these statistics for each category
5. WHEN the statistics screen is displayed THEN the System SHALL show a visual representation of progress (e.g., progress bars or percentages)

### Requirement 4: Navigation Integration

**User Story:** As a user, I want the statistics screen to be easily accessible from the main navigation, so that I can quickly view my progress.

#### Acceptance Criteria

1. WHEN viewing the main navigation THEN the System SHALL display a statistics tab as the last item in the navbar
2. WHEN the user taps the statistics tab THEN the System SHALL navigate to the statistics screen
3. WHEN the statistics screen is active THEN the System SHALL highlight the statistics tab in the navbar
4. WHEN the statistics screen loads THEN the System SHALL display a loading indicator while fetching data
5. WHEN the statistics screen encounters an error THEN the System SHALL display an error message with a retry option

### Requirement 5: Category-Level Statistics

**User Story:** As a user, I want to see my progress broken down by category, so that I can identify which topics I've mastered and which need more practice.

#### Acceptance Criteria

1. WHEN viewing the statistics screen THEN the System SHALL display statistics grouped by category
2. WHEN displaying category statistics THEN the System SHALL show the category icon
3. WHEN displaying category statistics THEN the System SHALL show questions answered in that category
4. WHEN displaying category statistics THEN the System SHALL show questions mastered in that category
5. WHEN displaying category statistics THEN the System SHALL show questions seen in that category
6. WHEN a category has no questions answered THEN the System SHALL display 0 for all statistics

### Requirement 6: Data Migration

**User Story:** As a system administrator, I want to migrate existing data to use the new counting approach, so that the system transitions smoothly without data loss.

#### Acceptance Criteria

1. WHEN running the migration THEN the System SHALL populate `questionCounter` for all categories
2. WHEN running the migration THEN the System SHALL verify that stored counts match calculated counts
3. WHEN running the migration THEN the System SHALL log any discrepancies between stored and calculated counts
4. WHEN the migration completes THEN the System SHALL confirm all categories have valid `questionCounter` values
5. WHEN the migration encounters errors THEN the System SHALL provide detailed error messages for troubleshooting
