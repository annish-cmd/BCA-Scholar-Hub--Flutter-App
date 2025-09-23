import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:typed_data';

class StorageService {
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _encryptionKeyKey = 'encryption_key';
  
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Encrypter _encrypter;
  late IV _iv;

  /// Initialize encryption for secure password storage
  Future<void> _initializeEncryption() async {
    final prefs = await SharedPreferences.getInstance();
    String? keyString = prefs.getString(_encryptionKeyKey);
    
    if (keyString == null) {
      // Generate new key if doesn't exist
      final key = Key.fromSecureRandom(32);
      keyString = base64.encode(key.bytes);
      await prefs.setString(_encryptionKeyKey, keyString);
    }
    
    final key = Key.fromBase64(keyString);
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromSecureRandom(16); // Generate new IV each time for better security
  }

  /// Save remember me preference and credentials
  Future<void> saveRememberMe(bool remember, {String? email, String? password}) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_rememberMeKey, remember);
    
    if (remember && email != null && password != null) {
      // Initialize encryption if not already done
      await _initializeEncryption();
      
      // Save email in plain text (not sensitive)
      await prefs.setString(_savedEmailKey, email);
      
      // Encrypt and save password
      final encrypted = _encrypter.encrypt(password, iv: _iv);
      final encryptedData = {
        'encrypted': encrypted.base64,
        'iv': _iv.base64,
      };
      await prefs.setString(_savedPasswordKey, jsonEncode(encryptedData));
    } else if (!remember) {
      // Clear saved credentials if remember me is disabled
      await clearSavedCredentials();
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Get saved email
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = await getRememberMe();
    
    if (remember) {
      return prefs.getString(_savedEmailKey);
    }
    return null;
  }

  /// Get saved password (decrypted)
  Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = await getRememberMe();
    
    if (!remember) return null;
    
    try {
      final encryptedDataString = prefs.getString(_savedPasswordKey);
      if (encryptedDataString == null) return null;
      
      // Initialize encryption
      await _initializeEncryption();
      
      final encryptedData = jsonDecode(encryptedDataString);
      final encrypted = Encrypted.fromBase64(encryptedData['encrypted']);
      final iv = IV.fromBase64(encryptedData['iv']);
      
      // Create encrypter with stored key
      final keyString = prefs.getString(_encryptionKeyKey)!;
      final key = Key.fromBase64(keyString);
      final decrypter = Encrypter(AES(key));
      
      return decrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // If decryption fails, clear saved data
      await clearSavedCredentials();
      return null;
    }
  }

  /// Check if credentials are saved and valid
  Future<bool> hasSavedCredentials() async {
    final remember = await getRememberMe();
    if (!remember) return false;
    
    final email = await getSavedEmail();
    final password = await getSavedPassword();
    
    return email != null && password != null && email.isNotEmpty && password.isNotEmpty;
  }

  /// Clear all saved credentials
  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
    await prefs.setBool(_rememberMeKey, false);
  }

  /// Clear all remember me data including encryption key
  Future<void> clearAllRememberMeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
    await prefs.remove(_encryptionKeyKey);
  }
}
