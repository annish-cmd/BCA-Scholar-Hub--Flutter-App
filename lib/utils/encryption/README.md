# Encryption in BCA Library App

This directory contains the implementation of a hybrid encryption system for securing messages in the global chat. The system uses two complementary encryption algorithms:

## Hybrid Encryption Architecture

The application implements a hybrid cryptography approach that combines the strengths of both symmetric and asymmetric encryption:

1. **AES (Advanced Encryption Standard)** - Symmetric encryption for message content
   - Fast and efficient for encrypting large amounts of data
   - Uses a 256-bit key for strong security
   - CBC (Cipher Block Chaining) mode with PKCS7 padding
   - Each message uses a unique randomly generated key

2. **RSA (Rivest-Shamir-Adleman)** - Asymmetric encryption for key exchange
   - 2048-bit key length for strong security
   - Public key is shared with other users via Firebase database
   - Private key is stored securely on the user's device
   - Used to encrypt/decrypt the AES key for each message

## Encryption Flow

When a user sends a message:
1. A random 256-bit AES key is generated
2. The message is encrypted with AES using this key
3. The AES key is encrypted separately for each recipient using their public RSA key
4. The encrypted message and encrypted keys are stored in Firebase

When receiving a message:
1. The system retrieves the encrypted AES key for the current user
2. The user's private RSA key decrypts the AES key
3. The AES key is used to decrypt the message content

## Security Features

- **End-to-End Encryption**: Messages can only be read by intended recipients
- **Perfect Forward Secrecy**: Each message uses a unique AES key
- **Secure Key Storage**: Private RSA keys never leave the user's device
- **Graceful Fallback**: If encryption fails, messages can fall back to plaintext
- **Visual Indicators**: The UI shows encryption status to users

## Implementation Details

### File Structure:
- `algorithms/aes_algorithm.dart` - AES encryption/decryption implementation
- `algorithms/rsa_algorithm.dart` - RSA key generation and encryption/decryption
- `encryption_service.dart` - Main service that orchestrates the encryption process

### Key Storage:
- RSA private keys are stored securely using `flutter_secure_storage`
- Public keys are stored in the Firebase user profile

## Security Considerations

- The system provides strong encryption for messages but does not encrypt metadata
- Message timestamps, user IDs, and other metadata remain visible to database administrators
- This implementation is for educational purposes and may require additional hardening for production use 