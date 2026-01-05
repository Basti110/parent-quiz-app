import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
        streakCurrent: 0,
        streakLongest: 0,
        streakPoints: 0,
        dailyGoal: 10,
        questionsAnsweredToday: 0,
        lastDailyReset: now,
        totalQuestionsAnswered: 0,
        totalCorrectAnswers: 0,
        totalMasteredQuestions: 0,
        duelsCompleted: 0,
        duelsWon: 0,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

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

      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final friendCode = await _generateUniqueFriendCode();
        final now = DateTime.now();
        final currentMonday = _getMondayOfWeek(now);

        final userModel = UserModel(
          id: user.uid,
          displayName: user.displayName ?? email.split('@')[0],
          email: email,
          avatarUrl: null,
          createdAt: now,
          lastActiveAt: now,
          friendCode: friendCode,
          streakCurrent: 0,
          streakLongest: 0,
          streakPoints: 0,
          dailyGoal: 10,
          questionsAnsweredToday: 0,
          lastDailyReset: now,
          totalQuestionsAnswered: 0,
          totalCorrectAnswers: 0,
          totalMasteredQuestions: 0,
          duelsCompleted: 0,
          duelsWon: 0,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      } else {
        // Update lastActiveAt timestamp
        await _firestore.collection('users').doc(user.uid).update({
          'lastActiveAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Sign in with Google
  /// Returns the user if successful, null if cancelled
  /// If an account with the same email exists (email/password), it will be linked
  Future<User?> signInWithGoogle() async {
    try {
      print('=== Google Sign-In gestartet ===');
      
      // Trigger the Google Sign-In flow
      print('Starte Google Sign-In Flow...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In abgebrochen vom Benutzer');
        // User cancelled the sign-in
        return null;
      }

      print('Google User erhalten: ${googleUser.email}');

      // Obtain the auth details from the request
      print('Hole Google Auth Details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Access Token erhalten: ${googleAuth.accessToken != null}');
      print('ID Token erhalten: ${googleAuth.idToken != null}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      print('Melde bei Firebase an...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        print('Firebase User ist null');
        return null;
      }

      print('Firebase User erhalten: ${user.uid}');

      // Check if this is a new user (no Firestore document yet)
      print('Prüfe ob Benutzer existiert...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isNewUser = !userDoc.exists;

      if (isNewUser) {
        print('Neuer Benutzer - erstelle Firestore Dokument...');
        // Create user document for new Google users
        final friendCode = await _generateUniqueFriendCode();
        final now = DateTime.now();

        final userModel = UserModel(
          id: user.uid,
          displayName: user.displayName ?? googleUser.displayName ?? 'User',
          email: user.email ?? googleUser.email,
          avatarUrl: null, // Don't use Google photo, let user pick avatar
          createdAt: now,
          lastActiveAt: now,
          friendCode: friendCode,
          streakCurrent: 0,
          streakLongest: 0,
          streakPoints: 0,
          dailyGoal: 10,
          questionsAnsweredToday: 0,
          lastDailyReset: now,
          totalQuestionsAnswered: 0,
          totalCorrectAnswers: 0,
          totalMasteredQuestions: 0,
          duelsCompleted: 0,
          duelsWon: 0,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        print('Firestore Dokument erstellt');
      } else {
        print('Bestehender Benutzer - aktualisiere lastActiveAt...');
        // Update lastActiveAt for existing users
        await _firestore.collection('users').doc(user.uid).update({
          'lastActiveAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      print('=== Google Sign-In erfolgreich ===');
      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('Google Sign-In Fehler: $e');
      print('Stack Trace: $stackTrace');
      throw 'Google Sign-In fehlgeschlagen: $e';
    }
  }

  /// Check if this is a new user (for navigation purposes)
  Future<bool> isNewUser(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return true;

    // Check if user has completed onboarding (has avatar)
    final data = userDoc.data();
    return data?['avatarUrl'] == null;
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
          .collection('users')
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
