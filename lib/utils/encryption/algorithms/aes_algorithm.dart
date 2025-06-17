import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// AES encryption algorithm implementation
class AESAlgorithm {
  // Generate a random AES key (256-bits/32-bytes)
  static Key generateKey() {
    // Generate 32 bytes (256 bits) for the key
    final keyBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return Key(Uint8List.fromList(keyBytes));
  }

  // Generate a random IV
  static IV generateIV() {
    // AES needs a 16-byte IV
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return IV(Uint8List.fromList(ivBytes));
  }

  // Encrypt data using AES/CBC/PKCS7
  static Map<String, String> encrypt(String plainText, {Key? key, IV? iv}) {
    final aesKey = key ?? generateKey();
    final aesIv = iv ?? generateIV();
    final encrypter = Encrypter(AES(aesKey));
    
    final encrypted = encrypter.encrypt(plainText, iv: aesIv);
    
    return {
      'cipherText': encrypted.base64,
      'iv': aesIv.base64,
      'key': base64.encode(aesKey.bytes),
    };
  }

  // Decrypt data using AES
  static String? decrypt(String cipherText, String ivString, String keyString) {
    try {
      // Make sure the key is valid (must be 16, 24, or 32 bytes)
      final rawKey = base64.decode(keyString);
      
      Key key;
      if (rawKey.length == 16 || rawKey.length == 24 || rawKey.length == 32) {
        key = Key(rawKey);
      } else {
        // If the key length is invalid, pad or trim to 32 bytes (256 bits)
        final adjustedKey = _adjustKeyLength(rawKey);
        key = Key(adjustedKey);
      }
      
      final iv = IV.fromBase64(ivString);
      final encrypter = Encrypter(AES(key));
      
      try {
        final decrypted = encrypter.decrypt64(cipherText, iv: iv);
        return decrypted;
      } catch (e) {
        print('AES Decryption error (inner): $e');
        
        // Try again with a different key length if the first attempt failed
        // This helps with compatibility issues between different encryption implementations
        if (rawKey.length != 16) {
          final adjustedKey16 = _adjustKeyLength(rawKey, targetLength: 16);
          final key16 = Key(adjustedKey16);
          try {
            final encrypter16 = Encrypter(AES(key16));
            final decrypted = encrypter16.decrypt64(cipherText, iv: iv);
            return decrypted;
          } catch (e2) {
            print('Second decryption attempt failed: $e2');
          }
        }
        
        if (rawKey.length != 24 && rawKey.length != 16) {
          final adjustedKey24 = _adjustKeyLength(rawKey, targetLength: 24);
          final key24 = Key(adjustedKey24);
          try {
            final encrypter24 = Encrypter(AES(key24));
            final decrypted = encrypter24.decrypt64(cipherText, iv: iv);
            return decrypted;
          } catch (e3) {
            print('Third decryption attempt failed: $e3');
          }
        }
        
        return null;
      }
    } catch (e) {
      print('AES Decryption error (outer): $e');
      return null;
    }
  }
  
  // Adjust key length to be 16, 24, or 32 bytes (128, 192, or 256 bits)
  static Uint8List _adjustKeyLength(List<int> key, {int targetLength = 32}) {
    if (targetLength != 16 && targetLength != 24 && targetLength != 32) {
      targetLength = 32; // Default to 256 bits if invalid target length
    }
    
    if (key.length == targetLength) {
      return Uint8List.fromList(key);
    }
    
    final adjustedKey = Uint8List(targetLength);
    
    if (key.length < targetLength) {
      // If key is too short, pad it
      for (int i = 0; i < targetLength; i++) {
        adjustedKey[i] = i < key.length ? key[i] : 0;
      }
    } else {
      // If key is too long, truncate it
      for (int i = 0; i < targetLength; i++) {
        adjustedKey[i] = key[i];
      }
    }
    
    return adjustedKey;
  }

  // Hash function to verify message integrity (simple version)
  static String hashMessage(String message) {
    final bytes = utf8.encode(message);
    var hash = 0;
    for (var i = 0; i < bytes.length; i++) {
      hash = (hash + ((i + 1) * bytes[i])) % 65536;
    }
    return hash.toString();
  }
} 