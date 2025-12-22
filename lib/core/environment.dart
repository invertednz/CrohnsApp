import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  static String get llmApiKey => dotenv.env['LLM_API_KEY'] ?? '';
  static String get llmModel => dotenv.env['LLM_MODEL'] ?? '';
  static String get llmEndpoint => dotenv.env['LLM_ENDPOINT'] ?? '';
  static String get mixpanelToken => dotenv.env['MIXPANEL_TOKEN'] ?? '';
  static String get mixpanelProjectId => dotenv.env['MIXPANEL_PROJECT_ID'] ?? '';
  
  // Gemini API
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Firebase Configuration
  static bool get useFirebase => dotenv.env['USE_FIREBASE']?.toLowerCase() == 'true';
  static bool get useMockData => dotenv.env['USE_MOCK_DATA']?.toLowerCase() == 'true';

  static Future<void> initialize() async {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
    final envFile = flavor == 'production' ? '.env.production' : '.env';

    try {
      await dotenv.load(fileName: envFile);
    } catch (error, stackTrace) {
      debugPrint('Environment: failed to load $envFile. Using fallback values. Error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}