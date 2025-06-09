import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final Logger _logger = Logger();
  final DatabaseService _databaseService = DatabaseService();

  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  User? get currentUser => _auth.currentUser;

  AuthProvider() {
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      _logger.d('Auth state changed: ${user?.email}');
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<UserCredential> login(String email, String password) async {
    try {
      _logger.d('Attempting to login with email: $email');

      // Validate email format
      if (!_isValidEmail(email)) {
        _logger.w('Invalid email format: $email');
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is not valid.',
        );
      }

      // Validate password
      if (password.isEmpty) {
        _logger.w('Empty password provided');
        throw FirebaseAuthException(
          code: 'invalid-password',
          message: 'Password cannot be empty.',
        );
      }

      // Log the attempt
      _logger.d('Attempting Firebase signInWithEmailAndPassword');
      _logger.d('Email: ${email.trim()}');
      _logger.d('Password length: ${password.length}');

      // Attempt Firebase authentication
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      // Save user data to Realtime Database
      if (userCredential.user != null) {
        await _databaseService.saveUserData(userCredential.user!);
      }

      _logger.i('Login successful for user: ${userCredential.user?.email}');
      notifyListeners();
      return userCredential;
    } catch (e) {
      _logger.e('Login error details:', error: e);
      if (e is FirebaseAuthException) {
        _logger.e('Firebase Auth Error Code: ${e.code}');
        _logger.e('Firebase Auth Error Message: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // Create a new user with email and password
  Future<UserCredential> signup(
    String email,
    String password,
    String name,
  ) async {
    try {
      _logger.d('Attempting to signup with email: $email');

      // Validate email format
      if (!_isValidEmail(email)) {
        _logger.w('Invalid email format: $email');
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is not valid.',
        );
      }

      // Validate password
      if (password.length < 6) {
        _logger.w('Password too short: ${password.length} characters');
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters 😀 .',
        );
      }

      // Log the attempt
      _logger.d('Attempting Firebase createUserWithEmailAndPassword');
      _logger.d('Email: ${email.trim()}');
      _logger.d('Password length: ${password.length}');

      // Create user in Firebase
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Update user profile with name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        _logger.i('Updated display name for user: $name');
        // Reload user to get updated profile
        await userCredential.user!.reload();
        _logger.i('Reloaded user profile');

        // Save user data to Realtime Database
        await _databaseService.saveUserData(userCredential.user!, name: name);
      }

      _logger.i('Signup successful for user: ${userCredential.user?.email}');
      notifyListeners();
      return userCredential;
    } catch (e) {
      _logger.e('Signup error details:', error: e);
      if (e is FirebaseAuthException) {
        _logger.e('Firebase Auth Error Code: ${e.code}');
        _logger.e('Firebase Auth Error Message: ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // Helper method to validate email
  bool _isValidEmail(String email) {
    // Simple email validation regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      // For web platform
      if (kIsWeb) {
        // Create a Google auth provider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Sign in with popup
        userCredential = await _auth.signInWithPopup(googleProvider);
      }
      // For mobile platforms
      else {
        // Begin interactive sign-in process
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        // If the user canceled the sign-in flow, return early
        if (googleUser == null) {
          throw Exception('Sign in was canceled by the user 🥲');
        }

        // Obtain auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Save user data to Realtime Database
      if (userCredential.user != null) {
        await _databaseService.saveUserData(userCredential.user!);
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      _logger.e('Google sign-in error: $e');
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> logout() async {
    try {
      // Sign out from Google if signed in with Google and not on web
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      // Sign out from Firebase
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      _logger.e('Logout error: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is not valid 😭.',
        );
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      _logger.e('Password reset error: $e');
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions and return user-friendly error messages
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Please create an account first to login 😇 ';
        case 'wrong-password 😡 ':
          return 'Incorrect password 🥵';
        case 'email-already-in-use 😤':
          return 'Email is already in use 🤨';
        case 'weak-password 😡':
          return 'Password should be at least 6 characters 🤨';
        case 'invalid-email 😡':
          return 'Please enter a valid email address 😏';
        case 'invalid-password 😡':
          return 'Please enter a valid password 😏';
        case 'user-disabled 😡':
          return 'This account has been disabled 😏';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later 😭';
        case 'operation-not-allowed':
          return 'Email/password sign in is not enabled';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email';
        case 'invalid-credential':
          return 'Please create an account first to login';
        case 'network-request-failed':
          return 'Network error. Please check your connection 🥱 ';
        case 'popup-closed-by-user':
          return 'Sign-in popup was closed';
        case 'cancelled-popup-request':
          return 'Another sign-in is in progress🙄';
        default:
          return 'Authentication failed: ${e.message} 😭';
      }
    }
    return 'An unexpected error occurred 😭';
  }
}
