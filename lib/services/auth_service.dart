import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user with email and password
  Future<User?> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Generate unique friend code
      final friendCode = await _generateUniqueFriendCode();

      // Get current Monday for weekly XP tracking
      final now = DateTime.now();
      final currentMonday = _getMondayOfWeek(now);

      // Create user document in Firestore
      final userModel = UserModel(
        id: user.uid,
        displayName: name,
        email: email,
        avatarUrl: null,
        createdAt: now,
        lastActiveAt: now,
        friendCode: friendCode,
        totalXp: 0,
        currentLevel: 1,
        weeklyXpCurrent: 0,
        weeklyXpWeekStart: currentMonday,
        streakCurrent: 0,
        streakLongest: 0,
        duelsPlayed: 0,
        duelsWon: 0,
        duelsLost: 0,
        duelPoints: 0,
      );

      await _firestore.collection('user').doc(user.uid).set(userModel.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in an existing user with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Update lastActiveAt timestamp
      await _firestore.collection('user').doc(user.uid).update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Generate a unique 6-8 character alphanumeric friend code
  String generateFriendCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars
    final random = Random();
    final length = 6 + random.nextInt(3); // 6, 7, or 8 characters

    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generate a unique friend code by checking Firestore for duplicates
  Future<String> _generateUniqueFriendCode() async {
    String code;
    bool isUnique = false;

    do {
      code = generateFriendCode();

      // Check if code already exists
      final querySnapshot = await _firestore
          .collection('user')
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();

      isUnique = querySnapshot.docs.isEmpty;
    } while (!isUnique);

    return code;
  }

  /// Get the Monday of the current week
  DateTime _getMondayOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Handle Firebase Auth exceptions and convert to user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }
}
