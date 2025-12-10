import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Migration script to transition from XP-based gamification to streak-based system
/// 
/// This script:
/// - Preserves existing streak data (streakCurrent, streakLongest)
/// - Preserves question state data (in questionStates subcollection)
/// - Removes XP-related fields (totalXp, currentLevel, weeklyXpCurrent, weeklyXpWeekStart)
/// - Initializes new fields with defaults (streakPoints, dailyGoal, etc.)
/// - Updates duel statistics (duelsPlayed → duelsCompleted, removes duelsLost, duelPoints)
/// 
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5

Future<void> main() async {
  print('=== Simplified Gamification Migration Script ===\n');
  
  // Initialize Firebase
  print('Initializing Firebase...');
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  // Confirm before proceeding
  print('\nThis script will migrate all user documents to the new schema.');
  print('Make sure you have backed up your database before proceeding!');
  print('\nDo you want to continue? (yes/no): ');
  
  final input = stdin.readLineSync();
  if (input?.toLowerCase() != 'yes') {
    print('Migration cancelled.');
    exit(0);
  }
  
  print('\nStarting migration...\n');
  
  try {
    // Get all users
    final usersSnapshot = await firestore.collection('users').get();
    final totalUsers = usersSnapshot.docs.length;
    
    print('Found $totalUsers users to migrate.\n');
    
    int successCount = 0;
    int errorCount = 0;
    final errors = <String, String>{};
    
    for (var i = 0; i < usersSnapshot.docs.length; i++) {
      final doc = usersSnapshot.docs[i];
      final userId = doc.id;
      final data = doc.data();
      
      print('[${ i + 1}/$totalUsers] Migrating user: $userId (${data['displayName']})');
      
      try {
        await _migrateUser(firestore, doc);
        successCount++;
        print('  ✓ Success\n');
      } catch (e) {
        errorCount++;
        errors[userId] = e.toString();
        print('  ✗ Error: $e\n');
      }
    }
    
    // Print summary
    print('\n=== Migration Summary ===');
    print('Total users: $totalUsers');
    print('Successful: $successCount');
    print('Errors: $errorCount');
    
    if (errors.isNotEmpty) {
      print('\nErrors encountered:');
      errors.forEach((userId, error) {
        print('  - $userId: $error');
      });
    }
    
    print('\nMigration complete!');
    
  } catch (e) {
    print('Fatal error during migration: $e');
    exit(1);
  }
  
  exit(0);
}

Future<void> _migrateUser(
  FirebaseFirestore firestore,
  DocumentSnapshot doc,
) async {
  final userId = doc.id;
  final data = doc.data() as Map<String, dynamic>;
  
  // Prepare updates for new fields
  final updates = <String, dynamic>{};
  
  // 1. Preserve existing streak data (Requirements 8.1)
  updates['streakCurrent'] = data['streakCurrent'] ?? 0;
  updates['streakLongest'] = data['streakLongest'] ?? 0;
  
  // 2. Initialize streak points to 0 (Requirements 8.4)
  updates['streakPoints'] = 0;
  
  // 3. Initialize daily goal system (Requirements 8.5)
  updates['dailyGoal'] = 10; // Default value
  updates['questionsAnsweredToday'] = 0;
  updates['lastDailyReset'] = Timestamp.now();
  
  // 4. Initialize question statistics
  updates['totalQuestionsAnswered'] = 0;
  updates['totalCorrectAnswers'] = 0;
  updates['totalMasteredQuestions'] = 0;
  
  // 5. Update duel statistics (Requirements 8.3)
  // duelsPlayed → duelsCompleted
  updates['duelsCompleted'] = data['duelsPlayed'] ?? 0;
  updates['duelsWon'] = data['duelsWon'] ?? 0;
  
  // Apply updates
  await doc.reference.update(updates);
  
  // 6. Remove XP-related fields (Requirements 8.3)
  final fieldsToDelete = <String, dynamic>{
    'totalXp': FieldValue.delete(),
    'currentLevel': FieldValue.delete(),
    'weeklyXpCurrent': FieldValue.delete(),
    'weeklyXpWeekStart': FieldValue.delete(),
    'duelPoints': FieldValue.delete(),
    'duelsPlayed': FieldValue.delete(),
    'duelsLost': FieldValue.delete(),
  };
  
  await doc.reference.update(fieldsToDelete);
  
  // 7. Question states are preserved automatically (Requirements 8.2)
  // They exist in the questionStates subcollection and are not modified
  
  // 8. Calculate totalMasteredQuestions from questionStates
  final questionStatesSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('questionStates')
      .where('mastered', isEqualTo: true)
      .get();
  
  final masteredCount = questionStatesSnapshot.docs.length;
  await doc.reference.update({'totalMasteredQuestions': masteredCount});
}
