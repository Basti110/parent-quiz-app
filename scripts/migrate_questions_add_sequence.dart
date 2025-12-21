#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

/// Migration script to add sequence field to existing questions
/// 
/// This script:
/// 1. Loads all existing questions from Firestore
/// 2. Assigns monotonically increasing sequence numbers (1, 2, 3, ...)
/// 3. Adds randomSeed field if missing
/// 4. Updates questions in batches to avoid timeout
/// 
/// Usage: dart scripts/migrate_questions_add_sequence.dart

Future<void> main() async {
  print('🚀 Starting question sequence migration...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;
    
    // Run migration
    await migrateQuestionsAddSequence(firestore);
    
    print('✅ Migration completed successfully!');
    exit(0);
  } catch (e, stackTrace) {
    print('❌ Migration failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> migrateQuestionsAddSequence(FirebaseFirestore firestore) async {
  print('📊 Loading existing questions...');
  
  // Load all questions ordered by createdAt to maintain some consistency
  final questionsQuery = firestore
      .collection('questions')
      .orderBy('createdAt', descending: false);
  
  final questionsSnapshot = await questionsQuery.get();
  final totalQuestions = questionsSnapshot.docs.length;
  
  print('📝 Found $totalQuestions questions to migrate');
  
  if (totalQuestions == 0) {
    print('ℹ️ No questions found, nothing to migrate');
    return;
  }
  
  // Process questions in batches of 500 (Firestore batch limit)
  const batchSize = 500;
  final random = Random();
  int currentSequence = 1;
  int processedCount = 0;
  
  for (int i = 0; i < questionsSnapshot.docs.length; i += batchSize) {
    final batch = firestore.batch();
    final endIndex = (i + batchSize < questionsSnapshot.docs.length) 
        ? i + batchSize 
        : questionsSnapshot.docs.length;
    
    print('🔄 Processing batch ${(i ~/ batchSize) + 1}/${(totalQuestions / batchSize).ceil()} (questions ${i + 1}-$endIndex)');
    
    for (int j = i; j < endIndex; j++) {
      final doc = questionsSnapshot.docs[j];
      final data = doc.data();
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'sequence': currentSequence++,
      };
      
      // Add randomSeed if missing
      if (!data.containsKey('randomSeed')) {
        updateData['randomSeed'] = random.nextDouble();
      }
      
      // Add to batch
      batch.update(doc.reference, updateData);
      processedCount++;
    }
    
    // Commit batch
    await batch.commit();
    print('✅ Batch completed. Processed $processedCount/$totalQuestions questions');
    
    // Small delay to avoid overwhelming Firestore
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  print('🎉 Successfully migrated $processedCount questions with sequence numbers 1-${currentSequence - 1}');
  
  // Verify migration
  await verifyMigration(firestore, totalQuestions);
}

Future<void> verifyMigration(FirebaseFirestore firestore, int expectedCount) async {
  print('🔍 Verifying migration...');
  
  // Count questions with sequence field
  final questionsWithSequence = await firestore
      .collection('questions')
      .where('sequence', isGreaterThan: 0)
      .count()
      .get();
  
  final migratedCount = questionsWithSequence.count ?? 0;
  
  if (migratedCount == expectedCount) {
    print('✅ Verification successful: $migratedCount/$expectedCount questions have sequence field');
  } else {
    print('⚠️ Verification warning: Only $migratedCount/$expectedCount questions have sequence field');
  }
  
  // Check for duplicate sequences
  final allSequences = await firestore
      .collection('questions')
      .orderBy('sequence')
      .get();
  
  final sequences = allSequences.docs
      .map((doc) => doc.data()['sequence'] as int?)
      .where((seq) => seq != null)
      .cast<int>()
      .toList();
  
  final uniqueSequences = sequences.toSet();
  
  if (sequences.length == uniqueSequences.length) {
    print('✅ No duplicate sequences found');
  } else {
    print('⚠️ Warning: Found ${sequences.length - uniqueSequences.length} duplicate sequences');
  }
  
  // Show sequence range
  if (sequences.isNotEmpty) {
    print('📈 Sequence range: ${sequences.first} - ${sequences.last}');
  }
}