# Implementation Plan

- [x] 1. Update data models and add sequence field to questions
  - Add `sequence` field to Question model with proper serialization
  - Update Question.fromMap() and toMap() methods to handle sequence field
  - Create migration script to add sequence field to existing questions in Firestore
  - _Requirements: 2.2, 4.4_

- [x] 2. Create enhanced QuestionState model for pool architecture
  - Add pool-specific fields: categoryId, difficulty, randomSeed, sequence, addedToPoolAt, poolBatch
  - Update QuestionState.fromMap() and toMap() methods
  - Add computed properties: isUnseen, isUnmastered
  - Add factory constructor QuestionState.createForPool()
  - _Requirements: 2.3, 4.4_

- [x] 3. Create pool metadata model and service
  - Create PoolMetadata model with totalPoolSize, unseenCount, maxSequenceInPool fields
  - Create PoolMetadataService for reading and updating pool statistics
  - Implement methods: loadPoolMetadata(), updatePoolMetadata()
  - _Requirements: 2.1, 4.1_

- [x] 4. Implement QuestionPoolService core functionality
  - Create QuestionPoolService class with dependency injection
  - Implement getQuestionsForSession() with three-tier priority system
  - Implement pool querying with mastery and difficulty filtering
  - Add error handling and logging throughout service
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 6.4_

- [ ]* 4.1 Write property test for priority-based selection
  - **Property 1: Priority-based question selection**
  - **Validates: Requirements 1.1, 1.2**

- [ ]* 4.2 Write property test for difficulty filtering
  - **Property 3: Difficulty filtering consistency**
  - **Validates: Requirements 1.3**

- [x] 4.3 Write property test for count constraints
  - **Property 4: Count constraint satisfaction**
  - **Validates: Requirements 1.4**

- [x] 5. Implement pool expansion functionality
  - Implement expandPool() method with batch loading and retry logic
  - Create _loadCandidateQuestions() for sequence-based pagination
  - Implement _batchCreateStatesAndUpdateMetadata() for atomic updates
  - Add logic to handle insufficient questions by retrying with next batch
  - _Requirements: 2.1, 2.2, 2.4, 2.5, 2.6_

- [x] 5.1 Write property test for pool expansion correctness
  - **Property 2: Pool expansion correctness**
  - **Validates: Requirements 2.3, 2.4, 2.5**

- [ ]* 5.2 Write example test for batch size limit
  - Test that expansion stops at maximum number of batches (3 batches = 600 questions)
  - **Validates: Requirements 2.6**

- [x] 6. Implement answer recording with pool state updates
  - Update recordAnswer() method to work with enhanced QuestionState model
  - Implement mastery threshold logic (correctCount >= 3)
  - Add upsert operations for both new and existing question states
  - Update pool metadata counters when mastery status changes
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 6.1 Write property test for answer recording updates
  - **Property 5: Answer recording updates all fields**
  - **Validates: Requirements 3.1, 3.2, 3.3**

- [x] 6.2 Write property test for mastery threshold
  - **Property 6: Mastery threshold enforcement**
  - **Validates: Requirements 3.4**

- [x] 7. Add data consistency and error handling
  - Implement duplicate state prevention in pool expansion
  - Add error recovery for partial pool expansion failures
  - Ensure all question states have required fields with valid initial values
  - Add graceful error handling that continues with available questions
  - _Requirements: 4.1, 4.3, 4.4, 4.5_

- [x] 7.1 Write property test for duplicate prevention
  - **Property 7: No duplicate states in pool**
  - **Validates: Requirements 4.1**

- [x] 7.2 Write property test for partial failure consistency
  - **Property 8: Partial failure consistency**
  - **Validates: Requirements 4.3**

- [x] 7.3 Write property test for required fields completeness
  - **Property 9: Required fields completeness**
  - **Validates: Requirements 4.4**

- [x] 7.4 Write property test for error recovery
  - **Property 10: Error recovery with available questions**
  - **Validates: Requirements 4.5**

- [x] 8. Implement edge case handling
  - Add fallback logic for when all questions in pool are mastered
  - Handle empty global question collection gracefully
  - Implement automatic pool expansion for empty pools
  - Add retry logic for batch loading failures
  - _Requirements: 5.1, 5.2, 5.4, 5.5_

- [ ]* 8.1 Write property test for mastered fallback
  - **Property 11: Mastered fallback behavior**
  - **Validates: Requirements 5.1**

- [ ]* 8.2 Write example test for empty global collection
  - Test graceful handling when no active questions exist
  - **Validates: Requirements 5.2**

- [ ]* 8.3 Write property test for empty pool expansion
  - **Property 12: Empty pool triggers expansion**
  - **Validates: Requirements 5.4**

- [ ]* 8.4 Write property test for batch failure recovery
  - **Property 13: Batch failure recovery**
  - **Validates: Requirements 5.5**

- [x] 9. Create Firestore indexes for optimal performance
  - Create composite indexes for questionStates collection queries
  - Add indexes for questions collection sequence-based queries
  - Update firestore.indexes.json with all required indexes
  - Test query performance with indexes in place
  - _Requirements: 6.1, 6.2_

- [ ] 10. Implement migration system for existing users
  - Create migration script to add pool-specific fields to existing question states
  - Implement lazy migration that triggers on first pool operation
  - Add pool metadata creation for migrated users
  - Test migration with various existing user data scenarios
  - _Requirements: 4.1, 4.4_

- [x] 11. Update QuizService to use QuestionPoolService
  - Modify getQuestionsForSession() to use new pool architecture
  - Update getQuestionsFromAllCategories() to work with pools
  - Ensure backward compatibility with existing API
  - Add feature flag support for gradual rollout
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ]* 11.1 Write property test for filtering by mastery and difficulty
  - **Property 14: Filtering by mastery and difficulty**
  - **Validates: Requirements 6.4**

- [x] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Add comprehensive error handling and logging
  - Implement proper error types for different failure scenarios
  - Add structured logging for pool operations and performance monitoring
  - Create error recovery strategies for network failures
  - Add monitoring hooks for pool expansion metrics
  - _Requirements: 4.5, 5.3_

- [ ] 14. Performance optimization and caching
  - Implement in-memory caching for pool statistics during session
  - Add question document caching to avoid repeated fetches
  - Optimize batch operations for better Firestore performance
  - Add performance monitoring and alerting
  - _Requirements: 1.5, 6.1, 6.3, 6.5_

- [ ] 15. Final integration testing and validation
  - Test complete quiz session flow with pool expansion
  - Validate migration from old to new architecture
  - Test concurrent user scenarios and pool expansion
  - Verify all correctness properties hold in integration tests
  - _Requirements: All requirements_

- [ ] 16. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.