#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Verification script for question sequence migration
/// 
/// This script verifies that:
/// 1. All questions have a sequence field
/// 2. All sequences are unique
/// 3. Sequences are consecutive starting from 1
/// 4. All questions have randomSeed field
/// 
/// Usage: dart scripts/verify_question_sequence_migration.dart

Future<void> main() async {
  print('🔍 Starting question sequence migration verification...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;
    
    // Run verification
    final result = await verifyQuestionSequenceMigration(firestore);
    
    if (result) {
      print('✅ All verifications passed!');
      exit(0);
    } else {
      print('❌ Some verifications failed!');
      exit(1);
    }
  } catch (e, stackTrace) {
    print('❌ Verification failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<bool> verifyQuestionSequenceMigration(FirebaseFirestore firestore) async {
  bool allPassed = true;
  
  print('📊 Loading all questions...');
  
  // Load all questions
  final questionsSnapshot = await firestore
      .collection('questions')
      .orderBy('sequence')
      .get();
  
  final totalQuestions = questionsSnapshot.docs.length;
  print('📝 Found $totalQuestions questions');
  
  if (totalQuestions == 0) {
    print('ℹ️ No questions found');
    return true;
  }
  
  // Test 1: Check that all questions have sequence field
  print('\n🧪 Test 1: Checking sequence field presence...');
  int questionsWithSequence = 0;
  int questionsWithoutSequence = 0;
  
  for (final doc in questionsSnapshot.docs) {
    final data = doc.data();
    if (data.containsKey('sequence') && data['sequence'] != null) {
      questionsWithSequence++;
    } else {
      questionsWithoutSequence++;
      print('⚠️ Question ${doc.id} missing sequence field');
    }
  }
  
  if (questionsWithoutSequence == 0) {
    print('✅ All $questionsWithSequence questions have sequence field');
  } else {
    print('❌ $questionsWithoutSequence questions missing sequence field');
    allPassed = false;
  }
  
  // Test 2: Check for duplicate sequences
  print('\n🧪 Test 2: Checking for duplicate sequences...');
  final sequences = questionsSnapshot.docs
      .map((doc) => doc.data()['sequence'] as int?)
      .where((seq) => seq != null)
      .cast<int>()
      .toList();
  
  final uniqueSequences = sequences.toSet();
  
  if (sequences.length == uniqueSequences.length) {
    print('✅ No duplicate sequences found');
  } else {
    print('❌ Found ${sequences.length - uniqueSequences.length} duplicate sequences');
    allPassed = false;
    
    // Find and report duplicates
    final sequenceCounts = <int, int>{};
    for (final seq in sequences) {
      sequenceCounts[seq] = (sequenceCounts[seq] ?? 0) + 1;
    }
    
    final duplicates = sequenceCounts.entries
        .where((entry) => entry.value > 1)
        .toList();
    
    for (final duplicate in duplicates) {
      print('⚠️ Sequence ${duplicate.key} appears ${duplicate.value} times');
    }
  }
  
  // Test 3: Check sequence range and consecutiveness
  print('\n🧪 Test 3: Checking sequence range and consecutiveness...');
  if (sequences.isNotEmpty) {
    sequences.sort();
    final minSequence = sequences.first;
    final maxSequence = sequences.last;
    
    print('📈 Sequence range: $minSequence - $maxSequence');
    
    if (minSequence == 1) {
      print('✅ Sequences start from 1');
    } else {
      print('❌ Sequences start from $minSequence (should be 1)');
      allPassed = false;
    }
    
    if (maxSequence == sequences.length) {
      print('✅ Sequences are consecutive (1 to ${sequences.length})');
    } else {
      print('❌ Sequences are not consecutive (max: $maxSequence, count: ${sequences.length})');
      allPassed = false;
    }
    
    // Check for gaps
    final expectedSequences = List.generate(sequences.length, (i) => i + 1);
    final missingSequences = expectedSequences.toSet().difference(sequences.toSet());
    
    if (missingSequences.isEmpty) {
      print('✅ No gaps in sequence');
    } else {
      print('❌ Missing sequences: ${missingSequences.toList()..sort()}');
      allPassed = false;
    }
  }
  
  // Test 4: Check randomSeed field
  print('\n🧪 Test 4: Checking randomSeed field presence...');
  int questionsWithRandomSeed = 0;
  int questionsWithoutRandomSeed = 0;
  
  for (final doc in questionsSnapshot.docs) {
    final data = doc.data();
    if (data.containsKey('randomSeed') && data['randomSeed'] != null) {
      questionsWithRandomSeed++;
    } else {
      questionsWithoutRandomSeed++;
      print('⚠️ Question ${doc.id} missing randomSeed field');
    }
  }
  
  if (questionsWithoutRandomSeed == 0) {
    print('✅ All $questionsWithRandomSeed questions have randomSeed field');
  } else {
    print('❌ $questionsWithoutRandomSeed questions missing randomSeed field');
    allPassed = false;
  }
  
  // Test 5: Sample data validation
  print('\n🧪 Test 5: Sample data validation...');
  if (questionsSnapshot.docs.isNotEmpty) {
    final sampleDoc = questionsSnapshot.docs.first;
    final sampleData = sampleDoc.data();
    
    print('📋 Sample question data:');
    print('   ID: ${sampleDoc.id}');
    print('   sequence: ${sampleData['sequence']}');
    print('   randomSeed: ${sampleData['randomSeed']}');
    print('   categoryId: ${sampleData['categoryId']}');
    print('   difficulty: ${sampleData['difficulty']}');
    print('   isActive: ${sampleData['isActive']}');
    
    // Validate randomSeed range
    final randomSeed = sampleData['randomSeed'] as double?;
    if (randomSeed != null && randomSeed >= 0.0 && randomSeed <= 1.0) {
      print('✅ Sample randomSeed is in valid range [0.0, 1.0]');
    } else {
      print('❌ Sample randomSeed is out of range: $randomSeed');
      allPassed = false;
    }
  }
  
  // Summary
  print('\n📊 Migration Verification Summary:');
  print('   Total questions: $totalQuestions');
  print('   Questions with sequence: $questionsWithSequence');
  print('   Questions with randomSeed: $questionsWithRandomSeed');
  print('   Unique sequences: ${uniqueSequences.length}');
  
  return allPassed;
}