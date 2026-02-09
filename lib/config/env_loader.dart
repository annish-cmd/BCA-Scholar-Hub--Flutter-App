import 'dart:io';

/// Environment variable loader for secure API key management
/// 
/// This class loads environment variables from .env file during development
/// and provides fallback values for production builds where .env might not be available
class EnvLoader {
  static final EnvLoader _instance = EnvLoader._internal();
  factory EnvLoader() => _instance;
  EnvLoader._internal();

  // Environment variables cache
  final Map<String, String> _envVars = {};

  /// Initialize environment variables
  /// Loads from .env file in development, uses system env in production
  Future<void> init() async {
    // Try to load from .env file first (development)
    await _loadFromEnvFile();
    
    // Load from system environment variables (production/server)
    _loadFromSystemEnv();
  }

  /// Load variables from .env file
  Future<void> _loadFromEnvFile() async {
    try {
      final file = File('.env');
      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.trim().isEmpty || line.startsWith('#')) continue;
          
          final parts = line.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            if (value.isNotEmpty && value != 'your-first-api-key-here') {
              _envVars[key] = value;
            }
          }
        }
      }
    } catch (e) {
      print('Warning: Could not load .env file: $e');
    }
  }

  /// Load from system environment variables
  void _loadFromSystemEnv() {
    // Add system environment variables
    _envVars.addAll(Platform.environment);
  }

  /// Get environment variable with fallback
  String get(String key, [String fallback = '']) {
    return _envVars[key] ?? fallback;
  }

  /// Get API keys as list
  List<String> getApiKeys() {
    final keys = <String>[];
    
    for (int i = 1; i <= 5; i++) {
      final key = get('OPENROUTER_API_KEY_$i');
      if (key.isNotEmpty) {
        keys.add(key);
      }
    }
    
    return keys;
  }

  /// Get API URL
  String get apiUrl => get('OPENROUTER_API_URL', 'https://openrouter.ai/api/v1/chat/completions');

  /// Get model name
  String get model => get('OPENROUTER_MODEL', 'mistralai/mistral-small-3.1-24b-instruct:free');
}

/// Global instance for easy access
final env = EnvLoader();