# API Keys Configuration

This directory contains configuration files for API keys and other sensitive information that should not be committed to Git.

## Setup Instructions

### Option 1: Environment Variables (Recommended)

1. Create a `.env` file in your project root:

   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and add your actual API keys:

   ```env
   OPENROUTER_API_KEY_1=your-actual-api-key-1
   OPENROUTER_API_KEY_2=your-actual-api-key-2
   # Add more keys as needed
   ```

### Option 2: Direct Configuration (Development Only)

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

## Security Notes

- Never commit your API keys to Git.
- Keep your API keys secure and do not share them publicly.
- If you suspect your API keys have been compromised, regenerate them immediately.
- The `.env` file is already added to `.gitignore` to prevent it from being committed.
- For production use, consider using a more secure method for storing API keys, such as environment variables on your build server or a secure key management service.

## Environment Variable Format

The system expects the following environment variables:

- `OPENROUTER_API_KEY_1` through `OPENROUTER_API_KEY_5`
- `OPENROUTER_API_URL` (optional, defaults to OpenRouter endpoint)
- `OPENROUTER_MODEL` (optional, defaults to mistral-small model)
