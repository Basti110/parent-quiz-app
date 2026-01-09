import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/feedback.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submit common feedback from settings screen
  Future<void> submitCommonFeedback(CommonFeedback feedback) async {
    print('Starting common feedback submission...');
    try {
      print('Converting feedback to map...');
      final feedbackMap = feedback.toMap();
      print('Feedback map created: ${feedbackMap.keys}');
      
      print('Submitting to Firestore...');
      await _firestore.collection('feedbacks').add(feedbackMap);
      print('Common feedback submitted successfully!');
    } on FirebaseException catch (e) {
      print('Firebase error submitting common feedback: ${e.code} - ${e.message}');
      throw Exception('Failed to submit feedback. Please try again.');
    } catch (e) {
      print('Error submitting common feedback: $e');
      throw Exception('Failed to submit feedback. Please try again.');
    }
  }

  /// Submit question-specific feedback
  Future<void> submitQuestionFeedback(QuestionFeedback feedback) async {
    print('Starting question feedback submission...');
    try {
      print('Converting feedback to map...');
      final feedbackMap = feedback.toMap();
      print('Feedback map created: ${feedbackMap.keys}');
      
      print('Submitting to Firestore...');
      await _firestore.collection('feedbacks').add(feedbackMap);
      print('Question feedback submitted successfully!');
    } on FirebaseException catch (e) {
      print('Firebase error submitting question feedback: ${e.code} - ${e.message}');
      throw Exception('Failed to submit feedback. Please try again.');
    } catch (e) {
      print('Error submitting question feedback: $e');
      throw Exception('Failed to submit feedback. Please try again.');
    }
  }

  /// Create app context with current device information
  AppContext createAppContext({String? childAgeGroup}) {
    return AppContext(
      version: '1.0.0', // TODO: Get from package_info_plus
      os: _getOperatingSystem(),
      childAgeGroup: childAgeGroup,
    );
  }

  /// Get current operating system
  String _getOperatingSystem() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  /// Get user's feedback history (optional for admin features)
  Future<List<FeedbackBase>> getUserFeedback(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final type = data['type'] as String;
        
        if (type == 'common') {
          return CommonFeedback.fromMap(data, doc.id);
        } else {
          return QuestionFeedback.fromMap(data, doc.id);
        }
      }).toList();
    } on FirebaseException catch (e) {
      print('Firebase error loading user feedback: ${e.code} - ${e.message}');
      throw Exception('Failed to load feedback history.');
    } catch (e) {
      print('Error loading user feedback: $e');
      throw Exception('Failed to load feedback history.');
    }
  }
}