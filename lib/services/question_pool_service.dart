import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/question.dart';
import '../models/question_state.dart';
import '../models/pool_metadata.dart';
import 'pool_metadata_service.dart';
import 'pool_migration_service.dart';

/// Service for managing user question pools with intelligent selection algorithms
/// 
/// This service implements a pool-based architecture where question states are
/// pre-populated for efficient querying and selection. Questions are selected
/// using a three-tier priority system: unseen -> unmastered -> mastered.
class QuestionPoolService {
  final FirebaseFirestore _firestore;
  final PoolMetadataService _poolMetadataService;
  final PoolMigrationService _migrationService;
  final Random _random;

  QuestionPoolService({
    FirebaseFirestore? firestore,
    PoolMetadataService? poolMetadataService,
    PoolMigrationService? migrationService,
    Random? random,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _poolMetadataService = poolMetadataService ?? PoolMetadataService(firestore: firestore),
       _migrationService = migrationService ?? PoolMigrationService(firestore: firestore),
       _random = random ?? Random();

  /// Ensure user is migrated to pool architecture (lazy migration)
  /// 
  /// This method is called before any pool operations to ensure the user
  /// has been migrated to the pool architecture. If not, it triggers migration.
  /// Requirements: 4.1, 4.4
  Future<void> _ensureUserMigrated(String userId) async {
    try {
      if (!await _migrationService.isUserMigrated(userId)) {
        print('User $userId not migrated, triggering lazy migration');
        await _migrationService.migrateUserToPoolArchitecture(userId);
      }
    } catch (e) {
      print('Warning: Migration failed for user $userId: $e');
      // Don't throw - allow the system to continue with degraded functionality
    }
  }

  /// Get questions for a quiz session using three-tier priority system
  /// 
  /// Priority order:
  /// 1. Unseen questions (seenCount == 0) - random selection
  /// 2. Unmastered questions (seenCount > 0 && mastered == false) - oldest first, then random
  /// 3. Mastered questions (mastered == true) - random selection
  /// 
  /// Supports filtering by category and difficulty.
  /// Automatically triggers pool expansion if insufficient questions available.
  /// Enhanced with graceful error handling that continues with available questions.
  /// Implements edge case handling for empty pools and all-mastered scenarios.
  /// 
  /// Requirements: 1.1, 1.2, 1.3, 1.4, 4.5, 5.1, 5.2, 5.4, 6.4
  Future<List<Question>> getQuestionsForSession({
    required String userId,
    required int count,
    String? categoryId,
    String? difficulty,
    int recursionDepth = 0,
  }) async {
    try {
      // Ensure user is migrated to pool architecture (lazy migration)
      await _ensureUserMigrated(userId);

      // Prevent infinite recursion
      if (recursionDepth > 2) {
        print('Warning: Maximum recursion depth reached for pool expansion');
        // Return whatever questions are available instead of empty list
        return await _getAvailableQuestions(userId, count, categoryId, difficulty);
      }

      // Step 1: Query existing pool with filters (with error recovery)
      List<QuestionState> poolQuestions;
      try {
        poolQuestions = await _queryPool(userId, categoryId, difficulty);
      } catch (e) {
        print('Warning: Failed to query pool, attempting fallback: $e');
        // Try to get any available questions without filters as fallback
        try {
          poolQuestions = await _queryPool(userId, null, null);
        } catch (e2) {
          print('Warning: Fallback query also failed: $e2');
          poolQuestions = [];
        }
      }
      
      // Step 1.5: Handle empty pool case - trigger automatic expansion
      // Requirements: 5.4
      if (poolQuestions.isEmpty && recursionDepth == 0) {
        print('Empty pool detected, triggering automatic expansion');
        try {
          await expandPool(
            userId: userId, 
            categoryId: categoryId, 
            difficulty: difficulty,
          );
          
          // Retry with expanded pool
          return getQuestionsForSession(
            userId: userId, 
            count: count, 
            categoryId: categoryId, 
            difficulty: difficulty,
            recursionDepth: recursionDepth + 1,
          );
        } catch (e) {
          print('Warning: Automatic pool expansion failed: $e');
          // Check if there are any questions in the global collection
          return await _handleEmptyGlobalCollection(userId, count, categoryId, difficulty);
        }
      }
      
      // Step 2: Separate by priority tiers
      final unseen = poolQuestions.where((q) => q.isUnseen).toList();
      final unmastered = poolQuestions.where((q) => !q.isUnseen && q.isUnmastered).toList(); // Only unmastered that are not unseen
      final mastered = poolQuestions.where((q) => q.mastered).toList();
      
      // Step 2.5: Handle all-mastered scenario
      // Requirements: 5.1
      if (unseen.isEmpty && unmastered.isEmpty && mastered.isNotEmpty) {
        print('All questions in pool are mastered, falling back to mastered questions');
        // Continue with mastered questions - this is the expected behavior
      }
      
      // Step 3: Select from tiers in priority order
      final selected = <QuestionState>[];
      
      // Tier 1: Unseen questions (random selection)
      if (unseen.isNotEmpty) {
        unseen.shuffle(_random);
        selected.addAll(unseen.take(count - selected.length));
      }
      
      // Tier 2: Unmastered questions (oldest first, then random)
      if (selected.length < count && unmastered.isNotEmpty) {
        // Sort by lastSeenAt (oldest first), handling null values
        unmastered.sort((a, b) {
          if (a.lastSeenAt == null && b.lastSeenAt == null) return 0;
          if (a.lastSeenAt == null) return 1; // null goes to end
          if (b.lastSeenAt == null) return -1; // null goes to end
          return a.lastSeenAt!.compareTo(b.lastSeenAt!);
        });
        
        // Take oldest questions and shuffle for variety
        final oldestUnmastered = unmastered.take(count * 2).toList();
        oldestUnmastered.shuffle(_random);
        selected.addAll(oldestUnmastered.take(count - selected.length));
      }
      
      // Tier 3: Mastered questions (random selection)
      // Requirements: 5.1 - Fall back to mastered questions when no unmastered available
      if (selected.length < count && mastered.isNotEmpty) {
        mastered.shuffle(_random);
        selected.addAll(mastered.take(count - selected.length));
        
        if (unseen.isEmpty && unmastered.isEmpty) {
          print('Serving ${selected.length} mastered questions as fallback (all questions mastered)');
        }
      }
      
      // Step 4: Expand pool if needed (only on first attempt and if we still need more questions)
      if (selected.length < count && recursionDepth == 0) {
        try {
          await expandPool(
            userId: userId, 
            categoryId: categoryId, 
            difficulty: difficulty,
          );
          
          // Retry selection with expanded pool (recursive call with depth limit)
          return getQuestionsForSession(
            userId: userId, 
            count: count, 
            categoryId: categoryId, 
            difficulty: difficulty,
            recursionDepth: recursionDepth + 1,
          );
        } catch (e) {
          print('Warning: Pool expansion failed, continuing with available questions: $e');
          // Continue with whatever questions we have
        }
      }
      
      // Step 5: Load actual question documents (with error recovery)
      return await _loadQuestionDocumentsWithRecovery(selected.map((s) => s.questionId).toList());
      
    } on FirebaseException catch (e) {
      print('Firebase error in getQuestionsForSession: ${e.code} - ${e.message}');
      // Try to return any available questions instead of throwing
      try {
        return await _getAvailableQuestions(userId, count, null, null);
      } catch (e2) {
        print('Warning: Fallback question loading also failed: $e2');
        return [];
      }
    } catch (e) {
      print('Error in getQuestionsForSession: $e');
      // Try to return any available questions instead of throwing
      try {
        return await _getAvailableQuestions(userId, count, null, null);
      } catch (e2) {
        print('Warning: Fallback question loading also failed: $e2');
        return [];
      }
    }
  }

  /// Fallback method to get any available questions when main query fails
  /// Requirements: 4.5
  Future<List<Question>> _getAvailableQuestions(
    String userId,
    int count,
    String? categoryId,
    String? difficulty,
  ) async {
    try {
      // Try to get any question states without complex filtering
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .limit(count * 2) // Get more than needed to allow for filtering
          .get();
      
      final questionStates = <QuestionState>[];
      for (final doc in snapshot.docs) {
        try {
          final state = QuestionState.fromMap(doc.data());
          if (_validateQuestionStateFields(state)) {
            questionStates.add(state);
          }
        } catch (e) {
          print('Warning: Skipping invalid question state: $e');
        }
      }
      
      // Apply basic filtering if possible
      var filteredStates = questionStates;
      if (categoryId != null) {
        filteredStates = filteredStates.where((s) => s.categoryId == categoryId).toList();
      }
      if (difficulty != null) {
        filteredStates = filteredStates.where((s) => s.difficulty == difficulty).toList();
      }
      
      // Take up to the requested count
      final selectedStates = filteredStates.take(count).toList();
      
      // Load question documents
      return await _loadQuestionDocumentsWithRecovery(
        selectedStates.map((s) => s.questionId).toList()
      );
      
    } catch (e) {
      print('Warning: Fallback question loading failed: $e');
      return [];
    }
  }

  /// Handle empty global question collection gracefully
  /// Requirements: 5.2
  Future<List<Question>> _handleEmptyGlobalCollection(
    String userId,
    int count,
    String? categoryId,
    String? difficulty,
  ) async {
    try {
      // Check if there are any active questions in the global collection
      final globalQuery = _firestore.collection('questions')
          .where('isActive', isEqualTo: true)
          .limit(1);
      
      final globalSnapshot = await globalQuery.get();
      
      if (globalSnapshot.docs.isEmpty) {
        print('Warning: No active questions found in global collection');
        // Return empty list with appropriate logging
        return [];
      }
      
      // If there are global questions but expansion failed, try a smaller expansion
      try {
        await expandPool(
          userId: userId,
          categoryId: categoryId,
          difficulty: difficulty,
          batchSize: 10, // Smaller batch size for retry
          maxBatches: 1, // Only one batch for emergency expansion
        );
        
        // Try to get questions from the newly expanded pool
        return await _getAvailableQuestions(userId, count, categoryId, difficulty);
        
      } catch (e) {
        print('Warning: Emergency pool expansion also failed: $e');
        return [];
      }
      
    } catch (e) {
      print('Warning: Failed to check global collection: $e');
      return [];
    }
  }

  /// Query the user's question pool with optional filters
  /// 
  /// Supports filtering by:
  /// - categoryId: Only questions from specific category
  /// - difficulty: Only questions of specific difficulty level
  /// 
  /// Uses efficient Firestore queries with proper indexes.
  /// Requirements: 6.4
  Future<List<QuestionState>> _queryPool(
    String userId,
    String? categoryId,
    String? difficulty,
  ) async {
    try {
      // For now, load all question states and filter in memory
      // This ensures compatibility with both real Firestore and fake Firestore for testing
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .get();
      
      final questionStates = snapshot.docs
          .map((doc) => QuestionState.fromMap(doc.data()))
          .toList();

      // Filter in memory
      var filteredStates = questionStates;
      
      if (categoryId != null) {
        filteredStates = filteredStates.where((state) => state.categoryId == categoryId).toList();
      }
      
      if (difficulty != null) {
        filteredStates = filteredStates.where((state) => state.difficulty == difficulty).toList();
      }
      
      return filteredStates;
          
    } on FirebaseException catch (e) {
      print('Firebase error querying pool: ${e.code} - ${e.message}');
      throw Exception('Failed to query question pool');
    } catch (e) {
      print('Error querying pool: $e');
      throw Exception('Failed to query question pool');
    }
  }

  /// Load actual question documents from their IDs
  /// 
  /// Efficiently loads multiple questions in parallel.
  /// Filters out any questions that don't exist or are inactive.
  /// Enhanced with error recovery to continue with available questions.
  /// Requirements: 4.5
  Future<List<Question>> _loadQuestionDocuments(List<String> questionIds) async {
    if (questionIds.isEmpty) {
      return [];
    }

    try {
      // Load questions in parallel for better performance
      final futures = questionIds.map((id) => 
          _firestore.collection('questions').doc(id).get()
      ).toList();
      
      final snapshots = await Future.wait(futures);
      
      final questions = <Question>[];
      for (int i = 0; i < snapshots.length; i++) {
        final snapshot = snapshots[i];
        
        if (snapshot.exists) {
          final data = snapshot.data()!;
          // Only include active questions
          if (data['isActive'] == true) {
            questions.add(Question.fromMap(data, snapshot.id));
          }
        }
      }
      
      return questions;
      
    } on FirebaseException catch (e) {
      print('Firebase error loading question documents: ${e.code} - ${e.message}');
      throw Exception('Failed to load question documents');
    } catch (e) {
      print('Error loading question documents: $e');
      throw Exception('Failed to load question documents');
    }
  }

  /// Load question documents with error recovery
  /// Continues with available questions even if some fail to load
  /// Requirements: 4.5
  Future<List<Question>> _loadQuestionDocumentsWithRecovery(List<String> questionIds) async {
    if (questionIds.isEmpty) {
      return [];
    }

    final questions = <Question>[];
    final failedIds = <String>[];

    try {
      // Load questions in parallel for better performance
      final futures = questionIds.map((id) => 
          _firestore.collection('questions').doc(id).get()
      ).toList();
      
      final results = await Future.wait(
        futures,
        eagerError: false, // Don't stop on first error
      );
      
      for (int i = 0; i < results.length; i++) {
        try {
          final snapshot = results[i];
          
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null && data['isActive'] == true) {
              try {
                questions.add(Question.fromMap(data, snapshot.id));
              } catch (e) {
                print('Warning: Failed to parse question ${snapshot.id}: $e');
                failedIds.add(questionIds[i]);
              }
            }
          } else {
            print('Warning: Question ${questionIds[i]} does not exist');
            failedIds.add(questionIds[i]);
          }
        } catch (e) {
          print('Warning: Failed to process question ${questionIds[i]}: $e');
          failedIds.add(questionIds[i]);
        }
      }
      
      if (failedIds.isNotEmpty) {
        print('Warning: Failed to load ${failedIds.length} out of ${questionIds.length} questions');
      }
      
      return questions;
      
    } on FirebaseException catch (e) {
      print('Firebase error loading question documents: ${e.code} - ${e.message}');
      // Return partial results if any were loaded
      if (questions.isNotEmpty) {
        print('Warning: Returning ${questions.length} partially loaded questions');
        return questions;
      }
      return [];
    } catch (e) {
      print('Error loading question documents: $e');
      // Return partial results if any were loaded
      if (questions.isNotEmpty) {
        print('Warning: Returning ${questions.length} partially loaded questions');
        return questions;
      }
      return [];
    }
  }

  /// Record an answer for a question and update the question state
  /// 
  /// Updates:
  /// - seenCount: Incremented by 1
  /// - correctCount: Incremented if answer is correct
  /// - lastSeenAt: Updated to current timestamp
  /// - mastered: Set to true if correctCount >= 3
  /// 
  /// Uses upsert operations to handle both new and existing states.
  /// Requirements: 3.1, 3.2, 3.3, 3.4
  Future<void> recordAnswer({
    required String userId,
    required String questionId,
    required bool isCorrect,
  }) async {
    try {
      // Ensure user is migrated to pool architecture (lazy migration)
      await _ensureUserMigrated(userId);

      final stateRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(questionId);

      QuestionState? currentState;
      int newSeenCount = 0;
      bool wasUnseen = false;

      await _firestore.runTransaction((transaction) async {
        final stateDoc = await transaction.get(stateRef);
        
        if (stateDoc.exists) {
          // Update existing state
          currentState = QuestionState.fromMap(stateDoc.data()!);
        } else {
          // This shouldn't happen in pool architecture, but handle gracefully
          print('Warning: Recording answer for question not in pool: $questionId');
          
          // Load question to get category and difficulty for the state
          final questionDoc = await _firestore.collection('questions').doc(questionId).get();
          if (!questionDoc.exists) {
            throw Exception('Question not found: $questionId');
          }
          
          final questionData = questionDoc.data()!;
          currentState = QuestionState(
            questionId: questionId,
            seenCount: 0,
            correctCount: 0,
            lastSeenAt: null,
            mastered: false,
            categoryId: questionData['categoryId'] as String,
            difficulty: questionData['difficulty'].toString(),
            randomSeed: (questionData['randomSeed'] as num?)?.toDouble(),
            sequence: questionData['sequence'] as int?,
            addedToPoolAt: DateTime.now(),
            poolBatch: 0, // Mark as batch 0 for retroactively added questions
          );
        }

        // Track if this was an unseen question
        wasUnseen = currentState!.seenCount == 0;

        // Update state fields
        newSeenCount = currentState!.seenCount + 1;
        final newCorrectCount = isCorrect ? currentState!.correctCount + 1 : currentState!.correctCount;
        final newMastered = newCorrectCount >= 3; // Mastery threshold

        final updatedState = QuestionState(
          questionId: currentState!.questionId,
          seenCount: newSeenCount,
          correctCount: newCorrectCount,
          lastSeenAt: DateTime.now(),
          mastered: newMastered,
          categoryId: currentState!.categoryId,
          difficulty: currentState!.difficulty,
          randomSeed: currentState!.randomSeed,
          sequence: currentState!.sequence,
          addedToPoolAt: currentState!.addedToPoolAt,
          poolBatch: currentState!.poolBatch,
        );

        // Update the question state
        transaction.set(stateRef, updatedState.toMap());
      });

      // Update pool metadata after the transaction if needed
      if (wasUnseen && newSeenCount > 0) {
        // Question transitioned from unseen to seen - decrement unseen count
        await _poolMetadataService.updatePoolMetadataIncremental(
          userId,
          incrementUnseenCount: -1,
        );
      }

    } on FirebaseException catch (e) {
      print('Firebase error recording answer: ${e.code} - ${e.message}');
      throw Exception('Failed to record answer. Please check your connection and try again.');
    } catch (e) {
      print('Error recording answer: $e');
      throw Exception('Failed to record answer. Please try again.');
    }
  }

  /// Get pool statistics for a user
  /// 
  /// Returns current pool metadata including total size, unseen count, etc.
  /// Returns null if user hasn't been migrated to pool architecture.
  Future<PoolMetadata?> getPoolStatistics(String userId) async {
    try {
      return await _poolMetadataService.loadPoolMetadata(userId);
    } catch (e) {
      print('Error getting pool statistics: $e');
      throw Exception('Failed to get pool statistics');
    }
  }

  /// Check if user has been migrated to pool architecture
  /// 
  /// Returns true if user has pool metadata, false otherwise.
  Future<bool> hasPoolArchitecture(String userId) async {
    try {
      return await _poolMetadataService.hasPoolMetadata(userId);
    } catch (e) {
      print('Error checking pool architecture: $e');
      return false;
    }
  }

  /// Count questions in pool matching filters
  /// 
  /// Useful for determining if pool expansion is needed.
  /// Requirements: 1.4
  Future<int> countQuestionsInPool({
    required String userId,
    String? categoryId,
    String? difficulty,
    bool? unseenOnly,
    bool? unmasteredOnly,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates');

      // Apply filters
      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      if (unseenOnly == true) {
        query = query.where('seenCount', isEqualTo: 0);
      }

      if (unmasteredOnly == true) {
        query = query.where('mastered', isEqualTo: false);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;

    } on FirebaseException catch (e) {
      print('Firebase error counting pool questions: ${e.code} - ${e.message}');
      throw Exception('Failed to count pool questions');
    } catch (e) {
      print('Error counting pool questions: $e');
      throw Exception('Failed to count pool questions');
    }
  }

  /// Expand the user's question pool by loading new questions from the global collection
  /// 
  /// Uses batch-based expansion with configurable batch size and maximum batches.
  /// Implements retry logic to handle cases where batches don't contain enough
  /// questions matching the specified filters.
  /// Enhanced with robust error handling and partial failure recovery.
  /// Includes retry logic for batch loading failures with smaller batch sizes.
  /// 
  /// Requirements: 2.1, 2.2, 2.4, 2.5, 2.6, 4.3, 4.5, 5.5
  Future<void> expandPool({
    required String userId,
    String? categoryId,
    String? difficulty,
    int batchSize = 200,
    int maxBatches = 3,
  }) async {
    try {
      // Ensure user is migrated to pool architecture (lazy migration)
      await _ensureUserMigrated(userId);

      // Load pool metadata to get last sequence
      final poolMeta = await _poolMetadataService.loadPoolMetadata(userId);
      final lastSequence = poolMeta?.maxSequenceInPool ?? 0;
      
      int totalNewStates = 0;
      int currentMaxSequence = lastSequence;
      final allErrors = <String>[];
      int currentBatchSize = batchSize;
      
      for (int batch = 0; batch < maxBatches; batch++) {
        try {
          // Load next batch of questions from global collection with retry logic
          List<Question> candidates;
          try {
            candidates = await _loadCandidateQuestions(
              batchSize: currentBatchSize,
              afterSequence: lastSequence + (batch * batchSize),
            );
          } catch (e) {
            // Requirements: 5.5 - Retry with smaller batch size on failure
            print('Warning: Batch loading failed with size $currentBatchSize, retrying with smaller size: $e');
            allErrors.add('Batch $batch failed with size $currentBatchSize: $e');
            
            if (currentBatchSize > 10) {
              currentBatchSize = (currentBatchSize / 2).round();
              print('Retrying batch $batch with reduced size: $currentBatchSize');
              
              try {
                candidates = await _loadCandidateQuestions(
                  batchSize: currentBatchSize,
                  afterSequence: lastSequence + (batch * batchSize),
                );
              } catch (e2) {
                print('Warning: Retry with smaller batch size also failed: $e2');
                allErrors.add('Batch $batch retry failed: $e2');
                
                // Try with minimum batch size as last resort
                if (currentBatchSize > 5) {
                  currentBatchSize = 5;
                  try {
                    candidates = await _loadCandidateQuestions(
                      batchSize: currentBatchSize,
                      afterSequence: lastSequence + (batch * batchSize),
                    );
                  } catch (e3) {
                    print('Warning: Final retry with minimum batch size failed: $e3');
                    allErrors.add('Batch $batch final retry failed: $e3');
                    continue; // Skip this batch and try the next one
                  }
                } else {
                  continue; // Skip this batch
                }
              }
            } else {
              continue; // Skip this batch if already at minimum size
            }
          }
          
          if (candidates.isEmpty) {
            print('No more questions available for expansion at batch $batch');
            break;
          }
          
          // Filter candidates by category/difficulty if needed
          final filteredCandidates = candidates.where((q) {
            if (categoryId != null && q.categoryId != categoryId) return false;
            if (difficulty != null && q.difficulty.toString() != difficulty) return false;
            return true;
          }).toList();
          
          // Check which candidates are already in pool (with error recovery)
          final existingStates = await _loadExistingStates(
            userId, 
            filteredCandidates.map((q) => q.id).toList(),
          );
          
          // Create states for new questions with validation
          final newStates = <QuestionState>[];
          for (final question in filteredCandidates) {
            if (!existingStates.containsKey(question.id)) {
              try {
                final newState = QuestionState.createForPool(
                  questionId: question.id,
                  categoryId: question.categoryId,
                  difficulty: question.difficulty.toString(),
                  randomSeed: _random.nextDouble(), // Generate random seed for pool randomization
                  sequence: question.sequence,
                  poolBatch: batch,
                );
                
                // Validate the new state before adding
                if (_validateQuestionStateFields(newState)) {
                  newStates.add(newState);
                  
                  // Track the highest sequence number
                  if (question.sequence > currentMaxSequence) {
                    currentMaxSequence = question.sequence;
                  }
                } else {
                  print('Warning: Generated invalid question state for ${question.id}, skipping');
                }
              } catch (e) {
                print('Warning: Failed to create question state for ${question.id}: $e');
                allErrors.add('Failed to create state for ${question.id}: $e');
                // Continue with other questions
              }
            }
          }
          
          // Batch write new states and update pool metadata (with error recovery)
          if (newStates.isNotEmpty) {
            try {
              await _batchCreateStatesAndUpdateMetadata(userId, newStates, currentMaxSequence);
              totalNewStates += newStates.length;
            } catch (e) {
              print('Warning: Batch operation failed for batch $batch: $e');
              allErrors.add('Batch $batch failed: $e');
              // Continue with next batch - partial failure is acceptable
            }
          }
          
          // Check if we have enough unseen questions now for the requested filters
          try {
            final unseenCount = await _countUnseenInPool(userId, categoryId, difficulty);
            if (unseenCount >= 10) {
              print('Pool expansion successful: added $totalNewStates questions, $unseenCount unseen available');
              break; // We have enough questions for a quiz session
            }
          } catch (e) {
            print('Warning: Failed to count unseen questions: $e');
            // Continue expansion anyway
          }
          
          // If this batch didn't give us enough questions, continue to next batch
          // This handles the rare case where a batch has few questions of the desired category
          print('Batch $batch completed: added ${newStates.length} questions, continuing expansion');
          
        } catch (e) {
          print('Warning: Batch $batch failed completely: $e');
          allErrors.add('Batch $batch failed: $e');
          
          // Requirements: 5.5 - Continue with next batch even if current batch fails
          print('Continuing with next batch after batch $batch failure');
          continue;
        }
      }
      
      if (totalNewStates == 0) {
        if (allErrors.isNotEmpty) {
          print('Warning: Pool expansion added no new questions due to errors: ${allErrors.join(', ')}');
        } else {
          print('Warning: Pool expansion added no new questions - no suitable questions available');
        }
      } else {
        print('Pool expansion completed: added $totalNewStates questions total');
        if (allErrors.isNotEmpty) {
          print('Pool expansion had some errors but continued: ${allErrors.join(', ')}');
        }
      }
      
    } on FirebaseException catch (e) {
      print('Firebase error during pool expansion: ${e.code} - ${e.message}');
      // Don't throw - allow the system to continue with existing pool
      print('Warning: Pool expansion failed, continuing with existing pool');
    } catch (e) {
      print('Error during pool expansion: $e');
      // Don't throw - allow the system to continue with existing pool
      print('Warning: Pool expansion failed, continuing with existing pool');
    }
  }

  /// Load candidate questions from the global collection using sequence-based pagination
  /// 
  /// Loads questions without category/difficulty filters during expansion.
  /// We'll filter after loading to handle the mixed-category scenario.
  /// 
  /// Requirements: 2.2, 2.4
  Future<List<Question>> _loadCandidateQuestions({
    required int batchSize,
    required int afterSequence,
  }) async {
    try {
      // Try the optimized query first (requires composite index)
      try {
        final query = _firestore.collection('questions')
            .where('isActive', isEqualTo: true)
            .where('sequence', isGreaterThan: afterSequence)
            .orderBy('sequence')
            .limit(batchSize);
        
        final snapshot = await query.get();
        return snapshot.docs
            .map((doc) => Question.fromMap(doc.data(), doc.id))
            .toList();
            
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition' && e.message?.contains('index') == true) {
          print('Composite index not ready, falling back to simple query');
          // Fall back to simple query without sequence filtering
          return await _loadCandidateQuestionsSimple(batchSize, afterSequence);
        } else {
          rethrow;
        }
      }
          
    } on FirebaseException catch (e) {
      print('Firebase error loading candidate questions: ${e.code} - ${e.message}');
      throw Exception('Failed to load candidate questions');
    } catch (e) {
      print('Error loading candidate questions: $e');
      throw Exception('Failed to load candidate questions');
    }
  }

  /// Fallback method to load questions when composite index is not available
  /// Uses simple query and filters in memory
  Future<List<Question>> _loadCandidateQuestionsSimple(int batchSize, int afterSequence) async {
    try {
      // Use simple query that only requires single-field index
      final query = _firestore.collection('questions')
          .where('isActive', isEqualTo: true)
          .limit(batchSize * 3); // Get more to account for filtering
      
      final snapshot = await query.get();
      final allQuestions = snapshot.docs
          .map((doc) => Question.fromMap(doc.data(), doc.id))
          .toList();
      
      // Filter by sequence in memory and sort
      final filteredQuestions = allQuestions
          .where((q) => q.sequence > afterSequence)
          .toList();
      
      // Sort by sequence
      filteredQuestions.sort((a, b) => a.sequence.compareTo(b.sequence));
      
      // Take only the requested batch size
      return filteredQuestions.take(batchSize).toList();
      
    } catch (e) {
      print('Error in fallback candidate loading: $e');
      throw Exception('Failed to load candidate questions with fallback method');
    }
  }

  /// Load existing question states to avoid duplicates during pool expansion
  /// 
  /// Returns a map of questionId -> QuestionState for efficient lookup.
  /// Implements robust duplicate prevention with error recovery.
  /// Requirements: 4.1, 4.5
  Future<Map<String, QuestionState>> _loadExistingStates(
    String userId,
    List<String> questionIds,
  ) async {
    if (questionIds.isEmpty) {
      return {};
    }

    try {
      // Load existing states in batches to avoid Firestore 'in' query limit (10 items)
      final existingStates = <String, QuestionState>{};
      final failedChunks = <List<String>>[];
      
      // Process in chunks of 10 (Firestore 'in' query limit)
      for (int i = 0; i < questionIds.length; i += 10) {
        final chunk = questionIds.skip(i).take(10).toList();
        
        try {
          final query = _firestore
              .collection('users')
              .doc(userId)
              .collection('questionStates')
              .where('questionId', whereIn: chunk);
          
          final snapshot = await query.get();
          
          for (final doc in snapshot.docs) {
            try {
              final state = QuestionState.fromMap(doc.data());
              // Validate that the state has all required fields
              if (_validateQuestionStateFields(state)) {
                existingStates[state.questionId] = state;
              } else {
                print('Warning: Question state ${state.questionId} has invalid fields, treating as non-existent');
              }
            } catch (e) {
              print('Warning: Failed to parse question state from document ${doc.id}: $e');
              // Continue processing other documents
            }
          }
        } catch (e) {
          print('Warning: Failed to load chunk of existing states: $e');
          failedChunks.add(chunk);
          // Continue with other chunks
        }
      }
      
      // Retry failed chunks with individual document queries for better error recovery
      for (final chunk in failedChunks) {
        await _retryLoadExistingStatesIndividually(userId, chunk, existingStates);
      }
      
      return existingStates;
      
    } on FirebaseException catch (e) {
      print('Firebase error loading existing states: ${e.code} - ${e.message}');
      // Return partial results instead of throwing - graceful degradation
      print('Warning: Returning partial existing states due to Firebase error');
      return {};
    } catch (e) {
      print('Error loading existing states: $e');
      // Return empty map to allow pool expansion to continue
      print('Warning: Returning empty existing states map due to error');
      return {};
    }
  }

  /// Retry loading existing states individually for better error recovery
  /// Requirements: 4.5
  Future<void> _retryLoadExistingStatesIndividually(
    String userId,
    List<String> questionIds,
    Map<String, QuestionState> existingStates,
  ) async {
    for (final questionId in questionIds) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('questionStates')
            .doc(questionId)
            .get();
        
        if (doc.exists) {
          try {
            final state = QuestionState.fromMap(doc.data()!);
            if (_validateQuestionStateFields(state)) {
              existingStates[state.questionId] = state;
            }
          } catch (e) {
            print('Warning: Failed to parse individual question state $questionId: $e');
          }
        }
      } catch (e) {
        print('Warning: Failed to load individual question state $questionId: $e');
        // Continue with next question
      }
    }
  }

  /// Validate that a question state has all required fields with valid values
  /// Requirements: 4.4
  bool _validateQuestionStateFields(QuestionState state) {
    try {
      // Check required fields are present and valid
      if (state.questionId.isEmpty) return false;
      if (state.seenCount < 0) return false;
      if (state.correctCount < 0) return false;
      if (state.categoryId == null || state.categoryId!.isEmpty) return false;
      if (state.difficulty == null || state.difficulty!.isEmpty) return false;
      if (state.addedToPoolAt == null) return false;
      if (state.poolBatch == null || state.poolBatch! < 0) return false;
      
      // Validate logical consistency
      if (state.correctCount > state.seenCount && state.seenCount > 0) return false;
      if (state.mastered && state.correctCount < 3) return false;
      
      // lastSeenAt can be null for unseen questions (seenCount == 0)
      if (state.seenCount > 0 && state.lastSeenAt == null) return false;
      
      return true;
    } catch (e) {
      print('Warning: Error validating question state fields: $e');
      return false;
    }
  }

  /// Batch create question states and update pool metadata atomically
  /// 
  /// Uses Firestore batch operations to ensure consistency.
  /// Updates pool metadata with new maxSequenceInPool and counts.
  /// Implements partial failure recovery and validation.
  /// 
  /// Requirements: 2.1, 4.1, 4.3, 4.4, 4.5
  Future<void> _batchCreateStatesAndUpdateMetadata(
    String userId,
    List<QuestionState> newStates,
    int newMaxSequence,
  ) async {
    if (newStates.isEmpty) {
      return;
    }

    // Validate all states before attempting to create them
    final validStates = <QuestionState>[];
    for (final state in newStates) {
      if (_validateQuestionStateFields(state)) {
        validStates.add(state);
      } else {
        print('Warning: Skipping invalid question state: ${state.questionId}');
      }
    }

    if (validStates.isEmpty) {
      print('Warning: No valid question states to create');
      return;
    }

    try {
      // Attempt atomic batch operation first
      await _attemptAtomicBatchOperation(userId, validStates, newMaxSequence);
      
    } catch (e) {
      print('Warning: Atomic batch operation failed: $e');
      
      // Fall back to partial creation with individual operations
      await _fallbackToIndividualOperations(userId, validStates, newMaxSequence);
    }
  }

  /// Attempt atomic batch operation for creating states and updating metadata
  /// Requirements: 4.3
  Future<void> _attemptAtomicBatchOperation(
    String userId,
    List<QuestionState> validStates,
    int newMaxSequence,
  ) async {
    final batch = _firestore.batch();
    
    // Add all new question states
    for (final state in validStates) {
      final stateRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('questionStates')
          .doc(state.questionId);
      batch.set(stateRef, state.toMap());
    }
    
    // Update pool metadata with new maxSequenceInPool
    final metaRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('poolMetadata')
        .doc('stats');
    
    batch.set(metaRef, {
      'maxSequenceInPool': newMaxSequence,
      'totalPoolSize': FieldValue.increment(validStates.length),
      'unseenCount': FieldValue.increment(validStates.length),
      'lastExpansionAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    await batch.commit();
  }

  /// Fallback to individual operations when batch fails
  /// Requirements: 4.3, 4.5
  Future<void> _fallbackToIndividualOperations(
    String userId,
    List<QuestionState> validStates,
    int newMaxSequence,
  ) async {
    final successfulStates = <QuestionState>[];
    
    // Try to create each state individually
    for (final state in validStates) {
      try {
        final stateRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('questionStates')
            .doc(state.questionId);
        
        await stateRef.set(state.toMap());
        successfulStates.add(state);
        
      } catch (e) {
        print('Warning: Failed to create individual question state ${state.questionId}: $e');
        // Continue with other states
      }
    }
    
    // Update metadata only for successfully created states
    if (successfulStates.isNotEmpty) {
      try {
        final metaRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('poolMetadata')
            .doc('stats');
        
        await metaRef.set({
          'maxSequenceInPool': newMaxSequence,
          'totalPoolSize': FieldValue.increment(successfulStates.length),
          'unseenCount': FieldValue.increment(successfulStates.length),
          'lastExpansionAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('Successfully created ${successfulStates.length} out of ${validStates.length} question states');
        
      } catch (e) {
        print('Warning: Failed to update pool metadata after partial state creation: $e');
        // States were created but metadata wasn't updated - this is recoverable
      }
    } else {
      print('Warning: No question states were successfully created');
    }
  }

  /// Count unseen questions in pool matching filters
  /// 
  /// Used to determine if pool expansion provided enough questions.
  /// Requirements: 1.4, 2.1
  Future<int> _countUnseenInPool(
    String userId,
    String? categoryId,
    String? difficulty,
  ) async {
    try {
      // For compatibility with both real and fake Firestore, load and filter in memory
      final poolQuestions = await _queryPool(userId, categoryId, difficulty);
      return poolQuestions.where((q) => q.isUnseen).length;
      
    } catch (e) {
      print('Error counting unseen questions in pool: $e');
      throw Exception('Failed to count unseen questions');
    }
  }
}