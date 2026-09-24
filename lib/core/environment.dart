/// Build-time configuration, supplied with `--dart-define-from-file=config/<env>.json`.
///
/// Only public values belong here: anything compiled into the app can be read
/// by anyone who downloads it. AI calls go through Firebase AI Logic, so no
/// model API key is ever shipped to the client.
class Environment {
  static const String mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');

  /// Gemini model used for chat, meal photo analysis and insights.
  static const String geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.5-flash');

  /// When true the app runs fully offline against the in-memory mock backend
  /// with deterministic AI responses (used by the E2E test build).
  static const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA');
}
