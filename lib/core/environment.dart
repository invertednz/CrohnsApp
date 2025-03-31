import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  static String get llmApiKey => dotenv.env['LLM_API_KEY'] ?? '';
  static String get llmModel => dotenv.env['LLM_MODEL'] ?? '';
  static String get llmEndpoint => dotenv.env['LLM_ENDPOINT'] ?? '';
  
  static Future<void> initialize() async {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'development');
    final envFile = flavor == 'production' ? '.env.production' : '.env';
    
    await dotenv.load(fileName: envFile);
  }
}