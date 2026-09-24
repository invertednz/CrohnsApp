import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:gut_md/core/environment.dart';

/// A single prior turn in a conversation sent to Gemini.
class GeminiTurn {
  final bool isUser;
  final String text;
  const GeminiTurn({required this.isUser, required this.text});
}

/// Thin wrapper around Firebase AI Logic (Gemini Developer API).
///
/// Requests are proxied by Firebase, so no Gemini API key exists in the client.
/// Every call is bounded by [requestTimeout] so callers can fall back instead
/// of leaving the UI waiting on a stalled network request.
class GeminiClient {
  GeminiClient._();

  /// Upper bound for a single chat reply.
  static const Duration requestTimeout = Duration(seconds: 45);

  /// Upper bound for structured output, which may include an image or a long
  /// tracking history.
  static const Duration structuredRequestTimeout = Duration(seconds: 60);

  /// Gemini is usable when Firebase is initialised and the app is not in
  /// offline mock mode.
  static bool get isAvailable =>
      !Environment.useMockData && Firebase.apps.isNotEmpty;

  static GenerativeModel _model({
    String? systemInstruction,
    GenerationConfig? config,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: Environment.geminiModel,
      systemInstruction:
          systemInstruction == null ? null : Content.system(systemInstruction),
      generationConfig: config,
    );
  }

  /// Low-latency thinking settings for conversational replies.
  ///
  /// Gemini 3+ models take a thinking level; 2.x models keep their default
  /// budget (a level would be rejected by the API).
  static ThinkingConfig? chatThinkingConfig(String model) {
    final match = RegExp(r'^gemini-(\d+)').firstMatch(model);
    final major = match == null ? null : int.tryParse(match.group(1)!);
    if (major == null || major < 3) return null;
    return ThinkingConfig.withThinkingLevel(ThinkingLevel.low);
  }

  /// Multi-turn text reply.
  static Future<String> chat({
    required String systemInstruction,
    required List<GeminiTurn> history,
    required String message,
  }) async {
    final model = _model(
      systemInstruction: systemInstruction,
      config: GenerationConfig(
        temperature: 0.7,
        // Thinking tokens share this budget on thinking models, so leave room
        // for the visible answer as well.
        maxOutputTokens: 2048,
        thinkingConfig: chatThinkingConfig(Environment.geminiModel),
      ),
    );
    final session = model.startChat(
      history: history
          .map((t) => t.isUser
              ? Content.text(t.text)
              : Content.model([TextPart(t.text)]))
          .toList(),
    );
    final response = await session
        .sendMessage(Content.text(message))
        .timeout(requestTimeout);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      final reason = response.candidates.isEmpty
          ? 'no candidates'
          : response.candidates.first.finishReason?.name ?? 'unknown';
      throw StateError('Gemini returned an empty response ($reason)');
    }
    return text;
  }

  /// Structured JSON output constrained by [schema], optionally with an image.
  static Future<Map<String, dynamic>> json({
    required String prompt,
    required Schema schema,
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
    String? systemInstruction,
  }) async {
    final model = _model(
      systemInstruction: systemInstruction,
      config: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
    final content = imageBytes == null
        ? Content.text(prompt)
        : Content.multi([
            TextPart(prompt),
            InlineDataPart(imageMimeType, imageBytes),
          ]);
    final response =
        await model.generateContent([content]).timeout(structuredRequestTimeout);
    final text = response.text ?? '';
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Gemini JSON response was not an object');
    }
    debugPrint('GeminiClient: structured response received');
    return decoded;
  }
}
