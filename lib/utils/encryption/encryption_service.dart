import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

import 'algorithms/rsa_algorithm.dart';
import 'algorithms/aes_algorithm.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final RSAAlgorithm _rsaAlgorithm = RSAAlgorithm();

  // Singleton pattern
  factory EncryptionService() => _instance;

  EncryptionService._internal();

  // Reference to public keys in Firebase
  DatabaseReference get _publicKeysRef => _database.ref('public_keys');

  // Initialize user encryption keys
  Future<void> initializeUserKeys() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Check if user already has RSA keys
      final privateKey = await _secureStorage.read(
        key: 'private_key_${user.uid}',
      );
      if (privateKey != null) {
        _logger.i('User already has RSA keys');
        // Upload public key again to ensure it's available
        await _uploadPublicKey();
        return;
      }

      _logger.i('Generating new RSA key pair for user ${user.uid}');

      // Generate new RSA key pair
      final keyPair = await _rsaAlgorithm.generateKeyPair();

      // Store private key securely
      await _secureStorage.write(
        key: 'private_key_${user.uid}',
        value: _rsaAlgorithm.encodePrivateKeyToPem(
          keyPair.privateKey as RSAPrivateKey,
        ),
      );

      // Store public key in memory and upload to Firebase
      await _uploadPublicKey();

      _logger.i('User encryption keys initialized successfully');
    } catch (e) {
      _logger.e('Error initializing encryption keys: $e');
      rethrow;
    }
  }

  // Upload public key to Firebase
  Future<void> _uploadPublicKey() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final publicKey = await _getPublicKey();
      if (publicKey == null) throw Exception('Public key not found');

      await _publicKeysRef.child(user.uid).set({
        'key': _rsaAlgorithm.encodePublicKeyToPem(publicKey),
        'timestamp': ServerValue.timestamp,
      });

      _logger.i('Public key uploaded successfully');
    } catch (e) {
      _logger.e('Error uploading public key: $e');
      rethrow;
    }
  }

  // Get user's public key
  Future<RSAPublicKey?> _getPublicKey() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final privateKeyPem = await _secureStorage.read(
        key: 'private_key_${user.uid}',
      );
      if (privateKeyPem == null) return null;

      final privateKey = _rsaAlgorithm.parsePrivateKeyFromPem(privateKeyPem);
      return _rsaAlgorithm.extractPublicKey(privateKey);
    } catch (e) {
      _logger.e('Error getting public key: $e');
      return null;
    }
  }

  // Get all users' public keys
  Future<Map<String, RSAPublicKey>> getAllUserPublicKeys() async {
    try {
      final snapshot = await _publicKeysRef.get();
      if (!snapshot.exists) return {};

      final data = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, RSAPublicKey> publicKeys = {};

      data.forEach((userId, userData) {
        if (userData is Map && userData['key'] is String) {
          try {
            final publicKey = _rsaAlgorithm.parsePublicKeyFromPem(
              userData['key'],
            );
            publicKeys[userId.toString()] = publicKey;
          } catch (e) {
            _logger.w('Error parsing public key for user $userId: $e');
          }
        }
      });

      // Make sure current user's key is included
      final currentUser = _auth.currentUser;
      if (currentUser != null && !publicKeys.containsKey(currentUser.uid)) {
        try {
          final publicKey = await _getPublicKey();
          if (publicKey != null) {
            publicKeys[currentUser.uid] = publicKey;
            // Also upload it in background
            _uploadPublicKey().catchError(
              (e) => _logger.e('Error uploading public key: $e'),
            );
          }
        } catch (e) {
          _logger.w('Error adding current user public key: $e');
        }
      }

      return publicKeys;
    } catch (e) {
      _logger.e('Error getting all user public keys: $e');
      rethrow;
    }
  }

  // Encrypt a message for global chat
  Future<Map<String, dynamic>> encryptGlobalChatMessage(String message) async {
    try {
      // Use AES algorithm to encrypt the message
      final aesResult = AESAlgorithm.encrypt(message);
      final messageKey = aesResult['key']!;

      // Get all users' public keys
      final publicKeys = await getAllUserPublicKeys();

      // At minimum, we need the current user's key for validation rules
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      if (!publicKeys.containsKey(user.uid)) {
        // Try to initialize the user's keys
        await initializeUserKeys();
        // Get public key directly
        final publicKey = await _getPublicKey();
        if (publicKey != null) {
          publicKeys[user.uid] = publicKey;
        } else {
          throw Exception('Could not get current user public key');
        }
      }

      if (publicKeys.isEmpty) {
        throw Exception('No public keys available for encryption');
      }

      // Encrypt AES key with each user's public key
      final Map<String, String> encryptedKeys = {};
      for (final entry in publicKeys.entries) {
        final userId = entry.key;
        final publicKey = entry.value;

        try {
          final encryptedKey = _rsaAlgorithm.encrypt(
            base64.decode(messageKey),
            publicKey,
          );
          encryptedKeys[userId] = base64.encode(encryptedKey);
        } catch (e) {
          _logger.w('Failed to encrypt key for user $userId: $e');
        }
      }

      // Make sure at least the current user's key is encrypted
      if (!encryptedKeys.containsKey(user.uid)) {
        throw Exception('Failed to encrypt key for current user');
      }

      return {
        'cipherText': aesResult['cipherText'],
        'iv': aesResult['iv'],
        'encryptedKeys': encryptedKeys,
      };
    } catch (e) {
      _logger.e('Error encrypting message: $e');
      rethrow;
    }
  }

  // Decrypt a message from global chat
  Future<String?> decryptGlobalChatMessage(
    String cipherText,
    String iv,
    Map<String, String> encryptedKeys,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Cannot decrypt message: No user logged in');
        return null;
      }

      // Get user's encrypted AES key
      final encryptedKey = encryptedKeys[user.uid];
      if (encryptedKey == null) {
        _logger.w('No encrypted key found for user ${user.uid}');
        return null;
      }

      // Get user's private key
      final privateKeyPem = await _secureStorage.read(
        key: 'private_key_${user.uid}',
      );
      if (privateKeyPem == null) {
        _logger.w('Private key not found for user ${user.uid}');
        return null;
      }

      final privateKey = _rsaAlgorithm.parsePrivateKeyFromPem(privateKeyPem);

      try {
        // Decrypt AES key with user's private key
        final aesKeyBytes = _rsaAlgorithm.decrypt(
          base64.decode(encryptedKey),
          privateKey,
        );

        // Use AES to decrypt the message
        final aesKeyBase64 = base64.encode(aesKeyBytes);
        final decryptedText = AESAlgorithm.decrypt(
          cipherText,
          iv,
          aesKeyBase64,
        );

        if (decryptedText == null) {
          _logger.w('AES decryption failed');
          return null;
        }

        return decryptedText;
      } catch (e) {
        _logger.e('Error decrypting message: $e');
        return null;
      }
    } catch (e) {
      _logger.e('Error decrypting message: $e');
      return null;
    }
  }
}
