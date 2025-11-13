import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../environment.dart';

class MixpanelService {
  MixpanelService._();

  static Mixpanel? _instance;
  static Future<Mixpanel?> initialize() async {
    if (kIsWeb) {
      return null;
    }

    if (_instance != null) {
      return _instance;
    }

    final token = Environment.mixpanelToken;
    if (token.isEmpty) {
      debugPrint('Mixpanel token not provided. Skipping Mixpanel initialization.');
      return null;
    }

    try {
      _instance = await Mixpanel.init(token, trackAutomaticEvents: true);
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize Mixpanel: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return _instance;
  }

  static Mixpanel? get instance => _instance;

  static Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (_instance == null) {
      await initialize();
    }

    final client = _instance;
    if (client == null) {
      debugPrint('Mixpanel is not initialized. Event "$eventName" was not tracked.');
      return;
    }

    try {
      await client.track(eventName, properties: properties);
    } catch (error, stackTrace) {
      debugPrint('Failed to track event "$eventName". Error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> identifyUser(String distinctId, {Map<String, dynamic>? properties}) async {
    if (_instance == null) {
      await initialize();
    }

    final client = _instance;
    if (client == null) {
      debugPrint('Mixpanel is not initialized. Identify call was skipped.');
      return;
    }

    try {
      client.identify(distinctId);
      if (properties != null && properties.isNotEmpty) {
        final people = client.getPeople();
        for (final entry in properties.entries) {
          people.set(entry.key, entry.value);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to identify user in Mixpanel. Error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
