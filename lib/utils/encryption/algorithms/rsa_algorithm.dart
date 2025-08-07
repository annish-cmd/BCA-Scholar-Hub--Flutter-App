import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:logger/logger.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A simplified RSA algorithm implementation for demo purposes
class RSAAlgorithm {
  static const String _privateKeyTag = 'user_rsa_private_key';
  static const String _publicKeyTag = 'user_rsa_public_key';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final Logger _logger = Logger();

  // Generate a new RSA key pair
  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>
  generateKeyPair() async {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGen = RSAKeyGenerator();
    final keyParams = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // public exponent
      2048, // key length - using a standard length
      64, // certainty
    );

    keyGen.init(ParametersWithRandom(keyParams, secureRandom));

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      publicKey,
      privateKey,
    );
  }

  // Get public key from private key
  RSAPublicKey extractPublicKey(RSAPrivateKey privateKey) {
    return RSAPublicKey(privateKey.modulus!, privateKey.publicExponent!);
  }

  // Encode private key to PEM format
  String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final topLevel = ASN1Sequence();

    topLevel.add(ASN1Integer(BigInt.zero)); // Version
    topLevel.add(ASN1Integer(privateKey.n!));
    topLevel.add(ASN1Integer(privateKey.publicExponent!));
    topLevel.add(ASN1Integer(privateKey.privateExponent!));
    topLevel.add(ASN1Integer(privateKey.p!));
    topLevel.add(ASN1Integer(privateKey.q!));
    topLevel.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)),
    );
    topLevel.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)),
    );
    topLevel.add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

    final dataBase64 = base64.encode(topLevel.encodedBytes);
    return """-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----""";
  }

  // Encode public key to PEM format
  String encodePublicKeyToPem(RSAPublicKey publicKey) {
    final topLevel = ASN1Sequence();

    topLevel.add(ASN1Integer(publicKey.modulus!));
    topLevel.add(ASN1Integer(publicKey.exponent!));

    final dataBase64 = base64.encode(topLevel.encodedBytes);
    return """-----BEGIN RSA PUBLIC KEY-----\n$dataBase64\n-----END RSA PUBLIC KEY-----""";
  }

  // Parse private key from PEM format
  RSAPrivateKey parsePrivateKeyFromPem(String pemString) {
    try {
      final lines =
          pemString
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();

      if (lines.length < 3 ||
          !lines.first.startsWith('-----BEGIN RSA PRIVATE KEY-----') ||
          !lines.last.startsWith('-----END RSA PRIVATE KEY-----')) {
        throw Exception('Invalid PEM format');
      }

      final keyString = lines.sublist(1, lines.length - 1).join('');
      final keyBytes = base64.decode(keyString);
      final asn1Parser = ASN1Parser(keyBytes);
      final topLevel = asn1Parser.nextObject() as ASN1Sequence;

      final values =
          topLevel.elements!
              .map((obj) => (obj as ASN1Integer).valueAsBigInteger)
              .toList();

      return RSAPrivateKey(
        values[1]!, // modulus
        values[3]!, // privateExponent
        values[4]!, // p
        values[5]!, // q
      );
    } catch (e) {
      _logger.e('Error parsing private key from PEM: $e');
      rethrow;
    }
  }

  // Parse public key from PEM format
  RSAPublicKey parsePublicKeyFromPem(String pemString) {
    try {
      final lines =
          pemString
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();

      if (lines.length < 3 ||
          !lines.first.startsWith('-----BEGIN RSA PUBLIC KEY-----') ||
          !lines.last.startsWith('-----END RSA PUBLIC KEY-----')) {
        throw Exception('Invalid PEM format');
      }

      final keyString = lines.sublist(1, lines.length - 1).join('');
      final keyBytes = base64.decode(keyString);
      final asn1Parser = ASN1Parser(keyBytes);
      final topLevel = asn1Parser.nextObject() as ASN1Sequence;

      final modulus = (topLevel.elements![0] as ASN1Integer).valueAsBigInteger;
      final exponent = (topLevel.elements![1] as ASN1Integer).valueAsBigInteger;

      return RSAPublicKey(modulus!, exponent!);
    } catch (e) {
      _logger.e('Error parsing public key from PEM: $e');
      rethrow;
    }
  }

  // Encrypt data using RSA public key
  Uint8List encrypt(Uint8List data, RSAPublicKey publicKey) {
    try {
      final cipher =
          RSAEngine()..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      return _processInBlocks(cipher, data);
    } catch (e) {
      _logger.e('RSA encryption error: $e');
      rethrow;
    }
  }

  // Decrypt data using RSA private key
  Uint8List decrypt(Uint8List data, RSAPrivateKey privateKey) {
    try {
      final cipher =
          RSAEngine()
            ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      return _processInBlocks(cipher, data);
    } catch (e) {
      _logger.e('RSA decryption error: $e');
      rethrow;
    }
  }

  // Process data in blocks (helper method)
  Uint8List _processInBlocks(RSAEngine cipher, Uint8List input) {
    try {
      final blockSize = cipher.inputBlockSize;
      final outputBlockSize = cipher.outputBlockSize;
      final numBlocks = (input.length + blockSize - 1) ~/ blockSize;
      final output = Uint8List(numBlocks * outputBlockSize);
      var inputOffset = 0;
      var outputOffset = 0;

      while (inputOffset < input.length) {
        final chunkSize =
            (inputOffset + blockSize <= input.length)
                ? blockSize
                : input.length - inputOffset;
        final inputChunk = input.sublist(inputOffset, inputOffset + chunkSize);

        try {
          final outputChunk = cipher.process(inputChunk);
          output.setRange(
            outputOffset,
            outputOffset + outputChunk.length,
            outputChunk,
          );
          inputOffset += chunkSize;
          outputOffset += outputChunk.length;
        } catch (e) {
          _logger.e('Error processing RSA block: $e');
          // If one block fails, try to continue with the next block
          inputOffset += chunkSize;
        }
      }

      return output.sublist(0, outputOffset);
    } catch (e) {
      _logger.e('Error in _processInBlocks: $e');
      rethrow;
    }
  }

  // Get stored public key
  static Future<String?> getPublicKey() async {
    return await _secureStorage.read(key: _publicKeyTag);
  }

  // Save public key to secure storage
  static Future<void> savePublicKey(String publicKeyPem) async {
    await _secureStorage.write(key: _publicKeyTag, value: publicKeyPem);
  }

  // Check if keys are already stored
  static Future<bool> hasKeys() async {
    final privateKey = await _secureStorage.read(key: _privateKeyTag);
    return privateKey != null;
  }
}
