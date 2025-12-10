import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Verification script to check migration success
/// 
/// This script verifies that:
/// - No XP-related fields remain
/// - New fields are present
/// - Data integrity is maintained

Future<void> main() async {
  print('=== Migration Verification Script ===\n');
  
  // Initialize Firebase
  print('Initializing Firebase...');
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  print('Running verification checks...\n');
  
  // Check 1: Verify no XP fields remain
  print('Check 1: Verifying XP fields removed...');
  final xpFieldChecks = await _checkForXpFields(firestore);
  
  // Check 2: Verify new fields present
  print('\nCheck 2: Verifying new fields present...');
  final newFieldsCheck = await _checkForNewFields(firestore);
  
  // Check 3: Verify streak data preserved
  print('\nCheck 3: Verifying streak data...');
  final streakCheck = await _checkStreakData(firestore);
  
  // Check 4: Verify question states intact
  print('\nCheck 4: Verifying question states...');
  final questionStatesCheck = await _checkQuestionStates(firestore);
  
  // Check 5: Verify duel statistics updated
  print('\nCheck 5: Verifying duel statistics...');
  final duelCheck = await _checkDuelStatistics(firestore);
  
  // Print summary
  print('\n=== Verification Summary ===');
  print('XP fields removed: ${xpFieldChecks ? "✓" : "✗"}');
  print('New fields present: ${newFieldsCheck ? "✓" : "✗"}');
  print('Streak data preserved: ${streakCheck ? "✓" : "✗"}');
  print('Question states intact: ${questionStatesCheck ? "✓" : "✗"}');
  print('Duel statistics updated: ${duelCheck ? "✓" : "✗"}');
  
  final allPassed = xpFieldChecks && 
                    newFieldsCheck && 
                    streakCheck && 
                    questionStatesCheck && 
                    duelCheck;
  
  if (allPassed) {
    print('\n✓ All verification checks passed!');
    print('Migration appears successful.');
  } else {
    print('\n✗ Some verification checks failed.');
    print('Please investigate the issues above.');
  }
}

Future<bool> _checkForXpFields(FirebaseFirestore firestore) async {
  final fieldsToCheck = [
    'totalXp',
    'currentLevel',
    'weeklyXpCurrent',
    'weeklyXpWeekStart',
    'duelPoints',
    'duelsPlayed',
    'duelsLost',
  ];
  
  bool allRemoved = true;
  
  for (final field in fieldsToCheck) {
    final snapshot = await firestore
        .collection('users')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      if (data.containsKey(field)) {
        print('  ✗ Found remaining field: $field');
        allRemoved = false;
      }
    }
  }
  
  if (allRemoved) {
    print('  ✓ All XP-related fields removed');
  }
  
  return allRemoved;
}

Future<bool> _checkForNewFields(FirebaseFirestore firestore) async {
  final requiredFields = [
    'streakPoints',
    'dailyGoal',
    'questionsAnsweredToday',
    'lastDailyReset',
    'totalQuestionsAnswered',
    'totalCorrectAnswers',
    'totalMasteredQuestions',
    'duelsCompleted',
  ];
  
  final snapshot = await firestore
      .collection('users')
      .limit(10)
      .get();
  
  if (snapshot.docs.isEmpty) {
    print('  ⚠ No users found in database');
    return false;
  }
  
  int usersWithAllFields = 0;
  
  for (final doc in snapshot.docs) {
    final data = doc.data();
    bool hasAllFields = true;
    
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        print('  ✗ User ${doc.id} missing field: $field');
        hasAllFields = false;
      }
    }
    
    if (hasAllFields) {
      usersWithAllFields++;
    }
  }
  
  print('  Users with all new fields: $usersWithAllFields/${snapshot.docs.length}');
  
  return usersWithAllFields == snapshot.docs.length;
}

Future<bool> _checkStreakData(FirebaseFirestore firestore) async {
  final snapshot = await firestore
      .collection('users')
      .limit(10)
      .get();
  
  if (snapshot.docs.isEmpty) {
    print('  ⚠ No users found in database');
    return false;
  }
  
  bool allValid = true;
  
  for (final doc in snapshot.docs) {
    final data = doc.data();
    
    // Check that streak fields are numbers
    if (data['streakCurrent'] is! int) {
      print('  ✗ User ${doc.id}: streakCurrent is not an integer');
      allValid = false;
    }
    
    if (data['streakLongest'] is! int) {
      print('  ✗ User ${doc.id}: streakLongest is not an integer');
      allValid = false;
    }
    
    // Check that streakLongest >= streakCurrent
    final current = data['streakCurrent'] as int? ?? 0;
    final longest = data['streakLongest'] as int? ?? 0;
    
    if (longest < current) {
      print('  ✗ User ${doc.id}: streakLongest ($longest) < streakCurrent ($current)');
      allValid = false;
    }
  }
  
  if (allValid) {
    print('  ✓ Streak data valid for all sampled users');
  }
  
  return allValid;
}

Future<bool> _checkQuestionStates(FirebaseFirestore firestore) async {
  final usersSnapshot = await firestore
      .collection('users')
      .limit(5)
      .get();
  
  if (usersSnapshot.docs.isEmpty) {
    print('  ⚠ No users found in database');
    return true; // Not a failure, just no data
  }
  
  bool allValid = true;
  int totalUsers = 0;
  int usersWithQuestionStates = 0;
  
  for (final userDoc in usersSnapshot.docs) {
    totalUsers++;
    
    final questionStates = await firestore
        .collection('users')
        .doc(userDoc.id)
        .collection('questionStates')
        .limit(1)
        .get();
    
    if (questionStates.docs.isNotEmpty) {
      usersWithQuestionStates++;
      
      // Verify structure of question state
      final data = questionStates.docs.first.data();
      final requiredFields = ['questionId', 'seenCount', 'correctCount', 'lastSeenAt', 'mastered'];
      
      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          print('  ✗ User ${userDoc.id}: questionState missing field: $field');
          allValid = false;
        }
      }
    }
  }
  
  print('  Users with question states: $usersWithQuestionStates/$totalUsers');
  
  if (allValid) {
    print('  ✓ Question states structure valid');
  }
  
  return allValid;
}

Future<bool> _checkDuelStatistics(FirebaseFirestore firestore) async {
  final snapshot = await firestore
      .collection('users')
      .limit(10)
      .get();
  
  if (snapshot.docs.isEmpty) {
    print('  ⚠ No users found in database');
    return false;
  }
  
  bool allValid = true;
  
  for (final doc in snapshot.docs) {
    final data = doc.data();
    
    // Check that duelsCompleted exists and is a number
    if (!data.containsKey('duelsCompleted')) {
      print('  ✗ User ${doc.id}: missing duelsCompleted field');
      allValid = false;
    } else if (data['duelsCompleted'] is! int) {
      print('  ✗ User ${doc.id}: duelsCompleted is not an integer');
      allValid = false;
    }
    
    // Check that duelsWon exists and is a number
    if (!data.containsKey('duelsWon')) {
      print('  ✗ User ${doc.id}: missing duelsWon field');
      allValid = false;
    } else if (data['duelsWon'] is! int) {
      print('  ✗ User ${doc.id}: duelsWon is not an integer');
      allValid = false;
    }
    
    // Check that old duel fields are removed
    if (data.containsKey('duelsPlayed')) {
      print('  ✗ User ${doc.id}: old field duelsPlayed still exists');
      allValid = false;
    }
    
    if (data.containsKey('duelsLost')) {
      print('  ✗ User ${doc.id}: old field duelsLost still exists');
      allValid = false;
    }
    
    if (data.containsKey('duelPoints')) {
      print('  ✗ User ${doc.id}: old field duelPoints still exists');
      allValid = false;
    }
    
    // Check that duelsWon <= duelsCompleted
    final completed = data['duelsCompleted'] as int? ?? 0;
    final won = data['duelsWon'] as int? ?? 0;
    
    if (won > completed) {
      print('  ✗ User ${doc.id}: duelsWon ($won) > duelsCompleted ($completed)');
      allValid = false;
    }
  }
  
  if (allValid) {
    print('  ✓ Duel statistics valid for all sampled users');
  }
  
  return allValid;
}
