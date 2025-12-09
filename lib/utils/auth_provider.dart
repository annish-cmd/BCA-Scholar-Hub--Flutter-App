import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/database_service.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import './user_profile_cache.dart'; // Add this import

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final Logger _logger = Logger();
  final DatabaseService _databaseService = DatabaseService();
  final ChatService _chatService = ChatService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final StorageService _storageService = StorageService();

  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  User? get currentUser => _auth.currentUser;
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;
  
  // Add userJoinedTimestamp property - default to current time when user logs in
  int _userJoinedTimestamp = 0;
  int get userJoinedTimestamp => _userJoinedTimestamp;

  AuthProvider() {
    // Initialize database URL
    _database.databaseURL =
        'https://bcalibraryapp-default-rtdb.asia-southeast1.firebasedatabase.app/';
    
    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      _logger.d('Auth state changed: ${user?.email}');
      if (user != null) {
        // Set user joined timestamp to current time
        _userJoinedTimestamp = DateTime.now().millisecondsSinceEpoch;
        // Initialize encryption when user logs in
        _initializeEncryption();
        // Check admin status
        _checkAdminStatus();
      } else {
        _isAdmin = false;
        _userJoinedTimestamp = 0;
        notifyListeners();
      }
      notifyListeners();
    });
  }

  // Check if current user is an admin
  Future<void> _checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isAdmin = false;
        notifyListeners();
        return;
      }

      final adminRef = _database.ref('admins').child(user.uid);
      final snapshot = await adminRef.get();
      
      _isAdmin = snapshot.exists;
      _logger.i('Admin status for ${user.email}: $_isAdmin');
      notifyListeners();
    } catch (e) {
      _logger.e('Error checking admin status: $e');
      _isAdmin = false;
      notifyListeners();
    }
  }

  // Public method to refresh admin status
  Future<void> refreshAdminStatus() async {
    await _checkAdminStatus();
  }
  
  // Initialize encryption for current user
  Future<void> _initializeEncryption() async {
    try {
      if (_auth.currentUser == null) {
        _logger.w('Cannot initialize encryption: No user is logged in');
        return;
      }
      
      // Wait for a brief moment to allow Firebase to fully authenticate
      await Future.delayed(const Duration(milliseconds: 500));
      
      // The ChatService should handle encryption initialization on its own,
      // but we'll force a state refresh here to ensure the UI updates
      notifyListeners();
      _logger.i('Encryption initialization triggered for user: ${_auth.currentUser?.email}');
    } catch (e) {
      _logger.e('Failed to initialize encryption: $e');
      // Continue even if encryption initialization fails
      // The chat service has fallback to unencrypted messages
    }
  }

  // Method to notify listeners when profile is updated
  void updateProfile() {
    notifyListeners();
  }

  // Sign in with email and password
  Future<UserCredential> login(String email, String password, {bool rememberMe = false}) async {
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
        // Initialize encryption
        await _initializeEncryption();
        
        // Handle remember me functionality
        if (rememberMe) {
          await _storageService.saveRememberMe(true, email: email.trim(), password: password);
          _logger.i('User credentials saved for remember me functionality');
        } else {
          await _storageService.saveRememberMe(false);
        }
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
        
        // Initialize encryption
        await _initializeEncryption();
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
        // Initialize encryption
        await _initializeEncryption();
      }

      notifyListeners();
      return userCredential;
    } catch (e) {
      _logger.e('Google sign-in error: $e');
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> logout({bool clearRememberMe = false}) async {
    try {
      // Sign out from Google if signed in with Google and not on web
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      
      // Clear remember me data if requested
      if (clearRememberMe) {
        await _storageService.clearSavedCredentials();
        _logger.i('Remember me credentials cleared');
      }
      
      // Clear user profile cache on logout
      await UserProfileCache.clearCache();
      
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

  // Reauthenticate user with password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently signed in.',
        );
      }

      if (user.email == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'No email associated with this account.',
        );
      }

      // Create credential
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);
      _logger.i('User reauthenticated successfully');
    } catch (e) {
      _logger.e('Reauthentication error: $e');
      throw _handleAuthException(e);
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently signed in.',
        );
      }

      // Validate password
      if (newPassword.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters.',
        );
      }

      // Update password
      await user.updatePassword(newPassword);
      _logger.i('Password updated successfully');
    } catch (e) {
      _logger.e('Password update error: $e');
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

  // Remember Me functionality methods
  
  /// Check if credentials are saved and valid
  Future<bool> hasSavedCredentials() async {
    return await _storageService.hasSavedCredentials();
  }

  /// Get saved credentials for auto-login
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _storageService.getSavedEmail();
      final password = await _storageService.getSavedPassword();
      
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      _logger.e('Error getting saved credentials: $e');
      return null;
    }
  }

  /// Try auto-login with saved credentials
  Future<bool> tryAutoLogin() async {
    try {
      final savedCredentials = await getSavedCredentials();
      if (savedCredentials != null) {
        _logger.i('Attempting auto-login with saved credentials');
        await login(savedCredentials['email']!, savedCredentials['password']!, rememberMe: true);
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Auto-login failed: $e');
      // Clear invalid credentials
      await _storageService.clearSavedCredentials();
      return false;
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMePreference() async {
    return await _storageService.getRememberMe();
  }

  /// Clear saved credentials only (without signing out)
  Future<void> clearSavedCredentials() async {
    await _storageService.clearSavedCredentials();
  }
}