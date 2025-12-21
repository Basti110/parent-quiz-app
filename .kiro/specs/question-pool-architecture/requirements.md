# Requirements Document

## Introduction

This feature redesigns the question loading architecture from a lazy loading system to a pool-based system. Currently, questions cannot be randomly loaded and filtered effectively based on existing question states. The new architecture will pre-populate question states for better query performance and more flexible question selection.

## Glossary

- **Question Pool**: A user-specific collection of question states that includes both seen and unseen questions
- **Question State**: A document tracking user progress for a specific question (seen count, correct count, mastery status)
- **Unseen Question**: A question with seenCount == 0 in the question state
- **Mastered Question**: A question where the user has achieved mastery (correctCount >= threshold)
- **Pool Expansion**: The process of adding new questions from the global questions collection to a user's question pool
- **Global Questions Collection**: The centralized collection containing all quiz questions with metadata
- **Batch Loading**: Loading questions in groups (e.g., 200 at a time) for performance optimization

## Requirements

### Requirement 1

**User Story:** As a user, I want questions to be selected randomly and efficiently, so that I get a varied quiz experience without performance issues.

#### Acceptance Criteria

1. WHEN the system selects questions for a quiz THEN it SHALL prioritize unseen questions (seenCount == 0) from the user's question pool
2. WHEN there are insufficient unseen questions in the pool THEN the system SHALL select unmastered questions (mastered == false) as secondary priority
3. WHEN selecting questions THEN the system SHALL support difficulty filtering if specified
4. WHEN questions are selected THEN the system SHALL return the requested count or the maximum available
5. WHEN question selection occurs THEN the system SHALL complete within reasonable time limits (< 2 seconds)

### Requirement 2

**User Story:** As a user, I want my question pool to automatically expand when needed, so that I always have fresh questions available without manual intervention.

#### Acceptance Criteria

1. WHEN the existing question pool has insufficient unseen questions THEN the system SHALL automatically expand the pool by loading new questions from the global collection
2. WHEN expanding the pool THEN the system SHALL load questions in batches of 200 to optimize performance
3. WHEN new questions are added to the pool THEN the system SHALL create question states with seenCount = 0 for each new question
4. WHEN pool expansion occurs THEN the system SHALL filter global questions by isActive == true
5. WHEN pool expansion occurs THEN the system SHALL respect difficulty filters if specified
6. WHEN pool expansion reaches the maximum number of batches (3 batches = 600 questions) THEN the system SHALL stop expansion to prevent performance issues

### Requirement 3

**User Story:** As a user, I want my question progress to be accurately tracked, so that the system knows which questions I've seen and mastered.

#### Acceptance Criteria

1. WHEN a user answers a question THEN the system SHALL update the question state with incremented seenCount
2. WHEN a user answers correctly THEN the system SHALL increment the correctCount in the question state
3. WHEN a user answers a question THEN the system SHALL update the lastSeenAt timestamp
4. WHEN correctCount reaches the mastery threshold THEN the system SHALL set mastered = true
5. WHEN updating question states THEN the system SHALL use upsert operations to handle both new and existing states

### Requirement 4

**User Story:** As a developer, I want the question pool system to maintain data consistency, so that user progress is never lost or corrupted.

#### Acceptance Criteria

1. WHEN creating question states for pool expansion THEN the system SHALL check for existing states to avoid duplicates
2. WHEN multiple operations access the same question state THEN the system SHALL handle concurrent updates safely
3. WHEN pool expansion fails partially THEN the system SHALL maintain consistency of existing question states
4. WHEN question states are created THEN the system SHALL include all required fields (seenCount, correctCount, mastered, lastSeenAt)
5. WHEN the system encounters errors during pool operations THEN it SHALL log errors appropriately and continue with available questions

### Requirement 5

**User Story:** As a user, I want the system to handle edge cases gracefully, so that I can always continue using the quiz functionality.

#### Acceptance Criteria

1. WHEN all questions in the pool are mastered THEN the system SHALL fall back to selecting from mastered questions
2. WHEN no active questions exist in the global collection THEN the system SHALL handle this gracefully with appropriate messaging
3. WHEN network connectivity is poor THEN the system SHALL work with cached question states where possible
4. WHEN the question pool is empty initially THEN the system SHALL automatically trigger pool expansion
5. WHEN batch loading fails THEN the system SHALL retry with smaller batch sizes or continue with available questions

### Requirement 6

**User Story:** As a system administrator, I want the new architecture to be performant and scalable, so that it can handle many users efficiently.

#### Acceptance Criteria

1. WHEN querying question states THEN the system SHALL use efficient Firestore queries with appropriate indexes
2. WHEN loading questions in batches THEN the system SHALL use pagination to avoid loading excessive data
3. WHEN expanding pools for multiple users THEN the system SHALL not create excessive load on the global questions collection
4. WHEN question states are queried THEN the system SHALL support filtering by mastery status and difficulty
5. WHEN the system scales to many users THEN pool expansion SHALL not significantly impact global question collection performance