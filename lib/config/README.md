# API Keys Configuration

This directory contains configuration files for API keys and other sensitive information that should not be committed to Git.

## Setup Instructions

1. Copy the template file to create your own API keys file:

   ```bash
   cp api_keys.template.dart api_keys.dart
   ```

2. Edit the `api_keys.dart` file and replace the placeholder values with your actual API keys:

   ```dart
   static const List<String> openRouterApiKeys = [
     'your-actual-api-key-1',
     'your-actual-api-key-2',
     // Add more keys as needed
   ];
   ```

3. The `api_keys.dart` file is already added to `.gitignore` to prevent it from being committed to Git.

## Security Notes

- Never commit your API keys to Git.
- Keep your API keys secure and do not share them publicly.
- If you suspect your API keys have been compromised, regenerate them immediately.
- For production use, consider using a more secure method for storing API keys, such as environment variables or a secure key management service.
