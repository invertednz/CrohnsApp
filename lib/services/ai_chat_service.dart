import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:gut_md/services/gemini_client.dart';

/// Model for a chat message
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    text: (json['text'] ?? json['message'] ?? '').toString(),
    isUser: json['isUser'] == true || json['role'] == 'user',
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}

/// Feeling scale used by the daily log (0 = Terrible .. 4 = Great).
const List<String> _feelingLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Great'];

int? _asInt(dynamic value) {
  if (value is num) return value.round();
  return value == null ? null : int.tryParse(value.toString());
}

double? _asNum(dynamic value) {
  if (value is num) return value.toDouble();
  return value == null ? null : double.tryParse(value.toString());
}

/// Free-text fields may be stored as a string or a list of strings.
String _asText(dynamic value) {
  if (value == null) return '';
  if (value is Iterable) {
    return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(', ');
  }
  return value.toString().trim();
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

String _feelingLabel(dynamic feeling) {
  final value = _asInt(feeling);
  if (value == null || value < 0 || value >= _feelingLabels.length) return 'Unknown';
  return _feelingLabels[value];
}

String _formatNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

String _joinNatural(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

/// User health context for AI chat
class UserHealthContext {
  /// Onboarding answers (conditions, goal, diet flags, lifestyle...), if saved.
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> recentDailyTracking;
  final List<Map<String, dynamic>> recentSymptoms;
  final List<Map<String, dynamic>> recentSupplements;
  final List<Map<String, dynamic>> recentMedications;
  final List<Map<String, dynamic>> recentDiet;

  /// Free-text diary days from Home: `{date, entries: [{time, text, ...}]}`.
  final List<Map<String, dynamic>> recentLogs;
  final List<String> foodTriggers;
  final List<String> safeFoods;
  final List<ChatMessage> chatHistory;

  UserHealthContext({
    this.profile,
    this.recentDailyTracking = const [],
    this.recentSymptoms = const [],
    this.recentSupplements = const [],
    this.recentMedications = const [],
    this.recentDiet = const [],
    this.recentLogs = const [],
    this.foodTriggers = const [],
    this.safeFoods = const [],
    this.chatHistory = const [],
  });

  bool get hasTrackedData =>
      recentDailyTracking.isNotEmpty ||
      recentSymptoms.isNotEmpty ||
      recentSupplements.isNotEmpty ||
      recentMedications.isNotEmpty ||
      recentDiet.isNotEmpty ||
      recentLogs.isNotEmpty ||
      foodTriggers.isNotEmpty ||
      safeFoods.isNotEmpty;

  int? feelingOn(Map<String, dynamic> day) => _asInt(day['feeling']);

  List<Map<String, dynamic>> get goodDays =>
      recentDailyTracking.where((d) => (feelingOn(d) ?? 2) >= 3).toList();

  List<Map<String, dynamic>> get toughDays =>
      recentDailyTracking.where((d) => (feelingOn(d) ?? 2) <= 1).toList();

  /// Foods logged on [date] across diet entries and analysed meals.
  List<String> foodsOn(dynamic date) {
    final foods = <String>[];
    for (final entry in recentDiet.where((d) => d['date'] == date)) {
      for (final meal in _maps(entry['meals'])) {
        final items = meal['foods'];
        if (items is Iterable) {
          foods.addAll(items.map((f) => f.toString()).where((f) => f.trim().isNotEmpty));
        }
      }
    }
    return foods.toSet().toList();
  }

  /// Distinct symptom names from the most recent [entries] symptom logs,
  /// with the highest severity seen for each.
  Map<String, int> recentSymptomSeverity({int entries = 3}) {
    final result = <String, int>{};
    for (final entry in recentSymptoms.take(entries)) {
      for (final symptom in _maps(entry['active_symptoms'])) {
        final name = _asText(symptom['name']);
        if (name.isEmpty) continue;
        final severity = _asInt(symptom['severity']) ?? 0;
        result[name] = severity > (result[name] ?? 0) ? severity : (result[name] ?? severity);
      }
    }
    return result;
  }

  /// Latest logged list for supplements/medications as `name dosage (taken)`.
  static List<Map<String, dynamic>> latestItems(List<Map<String, dynamic>> log, String key) {
    if (log.isEmpty) return const [];
    return _maps(log.first[key]).where((i) => _asText(i['name']).isNotEmpty).toList();
  }

  /// Build a summary string of the user's health context for the AI
  String buildContextSummary() {
    final buffer = StringBuffer();
    buffer.writeln("Today's date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}");
    buffer.writeln();
    _writeProfile(buffer);

    if (!hasTrackedData) {
      buffer.writeln('The user has not tracked any health data in the app yet.');
      return buffer.toString();
    }

    if (recentDailyTracking.isNotEmpty) {
      buffer.writeln('=== Daily Check-ins (newest first) ===');
      for (final entry in recentDailyTracking.take(14)) {
        final parts = <String>['Feeling ${_feelingLabel(entry['feeling'])}'];
        final pain = _asNum(entry['pain_level']);
        if (pain != null) parts.add('pain ${_formatNumber(pain)}/10');
        final energy = _asNum(entry['energy_level']);
        if (energy != null) parts.add('energy ${_formatNumber(energy)}/10');
        final bowel = _asInt(entry['bowel_movements']);
        if (bowel != null) parts.add('bowel movements $bowel');
        void flag(String key, String label) {
          final value = entry[key];
          if (value is bool) parts.add('$label: ${value ? 'yes' : 'no'}');
        }
        flag('supplements_followed', 'took all supplements');
        flag('medications_followed', 'took all medications');
        flag('diet_followed', 'stuck to usual diet');
        buffer.writeln('- ${entry['date'] ?? 'Unknown date'}: ${parts.join(', ')}');
        final good = _asText(entry['feel_good_factors']);
        final bad = _asText(entry['feel_bad_factors']);
        final notes = _asText(entry['notes']);
        if (good.isNotEmpty) buffer.writeln('    Helped: $good');
        if (bad.isNotEmpty) buffer.writeln('    Made it worse: $bad');
        if (notes.isNotEmpty) buffer.writeln('    Notes: $notes');
      }
      buffer.writeln();
    }

    if (recentSymptoms.isNotEmpty) {
      buffer.writeln('=== Symptom Logs ===');
      for (final entry in recentSymptoms.take(14)) {
        final symptoms = _maps(entry['active_symptoms'])
            .where((s) => _asText(s['name']).isNotEmpty)
            .map((s) => '${_asText(s['name'])} (severity ${_asInt(s['severity']) ?? '?'}/5)')
            .toList();
        if (symptoms.isNotEmpty) {
          buffer.writeln('- ${entry['date'] ?? 'Unknown date'}: ${symptoms.join(', ')}');
        }
      }
      buffer.writeln();
    }

    void writeItems(String title, List<Map<String, dynamic>> items) {
      if (items.isEmpty) return;
      buffer.writeln('=== $title ===');
      for (final item in items) {
        final dosage = _asText(item['dosage']);
        final time = _asText(item['time']);
        final details = [if (dosage.isNotEmpty) dosage, if (time.isNotEmpty) time].join(', ');
        final taken = item['taken'] == true ? 'taken' : 'not marked as taken';
        buffer.writeln('- ${_asText(item['name'])}${details.isEmpty ? '' : ' ($details)'}: $taken');
      }
      buffer.writeln();
    }

    writeItems('Supplements (latest log)', latestItems(recentSupplements, 'supplements'));
    writeItems('Medications (latest log)', latestItems(recentMedications, 'medications'));

    if (recentDiet.isNotEmpty) {
      buffer.writeln('=== Recent Meals ===');
      for (final entry in recentDiet.take(10)) {
        for (final meal in _maps(entry['meals'])) {
          final foods = _asText(meal['foods']);
          if (foods.isEmpty) continue;
          buffer.writeln('- ${entry['date'] ?? 'Unknown date'} ${_asText(meal['name'])}: $foods');
        }
      }
      buffer.writeln();
    }

    if (recentLogs.isNotEmpty) {
      buffer.writeln('=== Diary Entries (free text, newest day first) ===');
      for (final day in recentLogs) {
        for (final entry in _maps(day['entries'])) {
          final text = _asText(entry['text'] ?? entry['description']);
          if (text.isEmpty) continue;
          buffer.writeln('- ${day['date'] ?? 'Unknown date'} ${_asText(entry['time'])}: $text');
        }
      }
      buffer.writeln();
    }

    if (foodTriggers.isNotEmpty) {
      buffer.writeln('=== Food Triggers (marked by the user) ===');
      buffer.writeln(foodTriggers.join(', '));
      buffer.writeln();
    }

    if (safeFoods.isNotEmpty) {
      buffer.writeln('=== Safe Foods (marked by the user) ===');
      buffer.writeln(safeFoods.join(', '));
      buffer.writeln();
    }

    buffer.write(_analyzePatterns());
    return buffer.toString();
  }

  void _writeProfile(StringBuffer buffer) {
    final p = profile;
    if (p == null) return;
    String list(Object? v) => v is Iterable ? v.map((e) => e is Map ? e['name'] : e).join(', ') : '';
    final lines = <String>[
      if (_asText(p['condition_display']).isNotEmpty) 'Conditions: ${_asText(p['condition_display'])}',
      if (_asText(p['goal']).isNotEmpty) 'Main goal: ${_asText(p['goal']).replaceAll('_', ' ')}',
      if (list(p['dietFlags']).isNotEmpty) 'Diet notes: ${list(p['dietFlags'])}',
      if (list(p['lifestyle']).isNotEmpty) 'Lifestyle: ${list(p['lifestyle'])}',
      if (list(p['currentSymptoms']).isNotEmpty) 'Symptoms at sign-up: ${list(p['currentSymptoms'])}',
    ];
    if (lines.isEmpty) return;
    buffer.writeln('=== About the User (from onboarding) ===');
    lines.forEach(buffer.writeln);
    buffer.writeln();
  }

  String _analyzePatterns() {
    if (recentDailyTracking.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('=== Pattern Summary ===');
    buffer.writeln(
      '${recentDailyTracking.length} check-in(s): ${goodDays.length} good/great, '
      '${toughDays.length} bad/terrible.',
    );
    for (final day in toughDays.take(3)) {
      final foods = foodsOn(day['date']);
      if (foods.isNotEmpty) {
        buffer.writeln('- Foods on tough day ${day['date']}: ${foods.join(', ')}');
      }
    }
    for (final day in goodDays.take(3)) {
      final foods = foodsOn(day['date']);
      if (foods.isNotEmpty) {
        buffer.writeln('- Foods on good day ${day['date']}: ${foods.join(', ')}');
      }
    }
    return buffer.toString();
  }
}

/// AI chat assistant backed by Gemini (Firebase AI Logic).
///
/// Falls back to deterministic, data-aware responses when Gemini is
/// unavailable (offline mock mode or a transient API failure).
class AIChatService {
  const AIChatService();

  /// Generate a response using Gemini with the user's health context.
  Future<String> generateResponse({
    required String userMessage,
    required UserHealthContext context,
  }) async {
    if (!GeminiClient.isAvailable) {
      return _generateFallbackResponse(userMessage, context);
    }

    try {
      final reply = await GeminiClient.chat(
        systemInstruction: _buildSystemPrompt(context),
        history: recentHistory(context.chatHistory, userMessage),
        message: userMessage,
      );
      return toPlainText(reply);
    } catch (e) {
      debugPrint('AIChatService: Gemini request failed: $e');
      return _generateFallbackResponse(userMessage, context);
    }
  }

  /// Last 12 turns of history, excluding the message being sent now.
  ///
  /// Gemini expects alternating turns starting with the user, so consecutive
  /// turns from the same side (e.g. after a failed reply) are merged.
  @visibleForTesting
  List<GeminiTurn> recentHistory(List<ChatMessage> history, String userMessage) {
    final turns = <GeminiTurn>[];
    for (final message in history) {
      final text = message.text.trim();
      if (text.isEmpty) continue;
      if (turns.isNotEmpty && turns.last.isUser == message.isUser) {
        final previous = turns.removeLast();
        turns.add(GeminiTurn(isUser: message.isUser, text: '${previous.text}\n\n$text'));
      } else {
        turns.add(GeminiTurn(isUser: message.isUser, text: text));
      }
    }
    if (turns.isNotEmpty && turns.last.isUser && turns.last.text == userMessage.trim()) {
      turns.removeLast();
    }
    // The new message is sent as a user turn, so history must end on a model turn.
    if (turns.isNotEmpty && turns.last.isUser) {
      turns.removeLast();
    }
    var recent = turns.length > 12 ? turns.sublist(turns.length - 12) : turns;
    while (recent.isNotEmpty && !recent.first.isUser) {
      recent = recent.sublist(1);
    }
    return recent;
  }

  /// Chat bubbles render plain text, so strip common Markdown from replies.
  @visibleForTesting
  static String toPlainText(String reply) {
    final lines = reply.replaceAll('\r\n', '\n').split('\n').map((line) {
      var out = line;
      out = out.replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s+'), '');
      out = out.replaceFirstMapped(
        RegExp(r'^(\s*)[*\-+]\s+'),
        (m) => '${m.group(1)}• ',
      );
      out = out.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);
      out = out.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1)!);
      out = out.replaceAllMapped(RegExp(r'(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])'), (m) => m.group(1)!);
      out = out.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
      return out;
    });
    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String _buildSystemPrompt(UserHealthContext context) {
    return '''You are the GutMD Assistant, a caring, knowledgeable companion inside GutMD, an app people use to track Crohn's disease, ulcerative colitis, IBS and other digestive conditions.

What you do:
1. Help the user understand their own tracked symptoms, meals, supplements, medications and daily check-ins.
2. Point out possible links between food, stress, sleep, supplements and how they feel, but only when the data below supports it. Say how much data a pattern is based on, and call it a possible link, not a cause.
3. Share general, evidence-based self-care information for digestive conditions.
4. Offer emotional support and encourage consistent tracking.

Safety rules (always follow):
- You are not a doctor. Never diagnose, and never tell the user to start, stop or change the dose of a prescribed medication; suggest they discuss it with their doctor or IBD team.
- If the user mentions red-flag symptoms (blood in stool, black or tarry stool, severe or worsening abdominal pain, fever, persistent vomiting, signs of dehydration, fainting, or no bowel movement with a swollen belly), tell them clearly to contact their doctor urgently or seek emergency care.
- If the user mentions self-harm or suicidal thoughts, respond with compassion and urge them to contact local emergency services or a crisis line (for example 988 in the US, or Samaritans on 116 123 in the UK).
- Never invent data. If something has not been tracked, say so and suggest what to log.

Style:
- Plain text only: no Markdown, no headings, no asterisks. Use short paragraphs, and "• " for lists.
- Be warm and concise: usually under 150 words.
- Refer to specific dates, foods and symptoms from the data when they are relevant.

USER'S TRACKED DATA:
${context.buildContextSummary()}''';
  }

  /// True when any keyword starts a word in [text] (so "eat" does not match
  /// "great" and "iron" does not match "environment").
  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => RegExp('\\b${RegExp.escape(k)}').hasMatch(text));

  /// Fallback response when Gemini is not available
  String _generateFallbackResponse(String userMessage, UserHealthContext context) {
    final message = userMessage.toLowerCase().replaceAll('’', "'");

    if (_containsAny(message, const [
      'suicid', 'kill myself', 'end my life', 'self harm', 'self-harm', 'hurt myself',
    ])) {
      return "I'm really sorry you're feeling this way, and I'm glad you told me. You deserve support right now. "
          'Please contact your local emergency number or a crisis line straight away '
          '(for example 988 in the US, or Samaritans on 116 123 in the UK), or reach out to someone you trust.';
    }

    if (_containsAny(message, const [
      'blood in', 'bloody', 'bleeding', 'black stool', 'tarry', 'fever', 'vomiting blood',
      "can't keep", 'cannot keep', 'dehydrat', 'faint', 'passed out', 'emergency', 'severe pain',
      'severe abdominal', 'severe stomach', 'worst pain', 'unbearable',
    ])) {
      return 'What you describe can need urgent medical attention. Please contact your doctor or IBD team today, '
          'or call emergency services if symptoms are severe or getting worse. Warning signs include blood in your stool, '
          'severe or worsening abdominal pain, a fever, being unable to keep fluids down, or feeling faint. '
          'Log what you are experiencing in the Symptoms tab so you can share it with your care team.';
    }

    if (_containsAny(message, const ['stress', 'anxious', 'anxiety', 'worried', 'overwhelm'])) {
      final stressDays = context.recentDailyTracking
          .where((d) => _asText(d['feel_bad_factors']).toLowerCase().contains('stress'))
          .length;
      return 'Stress is commonly linked to digestive symptom flares, especially in IBS, and many people with IBD notice it too, '
          'because the gut and brain are closely connected. '
          '${stressDays > 0 ? 'You noted stress as a factor on $stressDays tough day${stressDays == 1 ? '' : 's'} in your log. ' : ''}'
          'Things that help many people: slow breathing (in for 4, out for 6), a short daily walk, regular sleep, and '
          'gut-directed relaxation or CBT, which your care team can refer you to. '
          'Managing a chronic condition is hard, and your feelings are valid.';
    }

    if (_containsAny(message, const ['medication', 'medicine', 'meds', 'prescription', 'dose'])) {
      final meds = UserHealthContext.latestItems(context.recentMedications, 'medications');
      if (meds.isNotEmpty) {
        final taken = meds.where((m) => m['taken'] == true).map((m) => _asText(m['name'])).toList();
        final missed = meds.where((m) => m['taken'] != true).map((m) => _asText(m['name'])).toList();
        return 'Your latest medication log lists ${_joinNatural(meds.map((m) => _asText(m['name'])).toList())}. '
            '${taken.isNotEmpty ? 'Marked as taken: ${taken.join(', ')}. ' : ''}'
            '${missed.isNotEmpty ? 'Not marked as taken yet: ${missed.join(', ')}. ' : ''}'
            'Taking medication consistently, as prescribed, is one of the most important parts of staying in remission. '
            'Never stop or change a dose without talking to your doctor, and ask them or your pharmacist about side effects or interactions.';
      }
      return "You haven't logged any medications in GutMD yet. Add them in the Meds tab so you can track doses each day. "
          'Take medication exactly as prescribed, and talk to your doctor or pharmacist before stopping or changing anything.';
    }

    if (_containsAny(message, const ['supplement', 'vitamin', 'probiotic', 'iron', 'b12', 'omega'])) {
      final supplements = UserHealthContext.latestItems(context.recentSupplements, 'supplements');
      final tracked = supplements.isEmpty
          ? ''
          : "You're currently tracking ${_joinNatural(supplements.map((s) => _asText(s['name'])).toList())}. ";
      return '$tracked'
          'People with IBD are more likely to be low in vitamin D, vitamin B12, iron and folate, so these are the supplements '
          'most often recommended, ideally after a blood test shows you need them. Evidence for probiotics is mixed and varies by condition. '
          'Check any new supplement with your doctor or pharmacist, as some can interact with medications.';
    }

    if (_containsAny(message, const ['pattern', 'trigger', 'why', 'caus', 'insight', 'correlat'])) {
      if (context.recentDailyTracking.isEmpty) {
        return "I don't have enough data to spot patterns yet. Log how you feel each day, plus your meals and symptoms, "
            'for at least a week and I can start comparing your good and tough days.'
            '${context.foodTriggers.isNotEmpty ? ' So far you have marked these food triggers: ${context.foodTriggers.join(', ')}.' : ''}';
      }
      final toughFoods = <String>{};
      for (final day in context.toughDays) {
        toughFoods.addAll(context.foodsOn(day['date']));
      }
      return 'Across ${context.recentDailyTracking.length} check-in${context.recentDailyTracking.length == 1 ? '' : 's'} '
          'you had ${context.goodDays.length} good day${context.goodDays.length == 1 ? '' : 's'} and '
          '${context.toughDays.length} tough day${context.toughDays.length == 1 ? '' : 's'}. '
          '${toughFoods.isNotEmpty ? 'Foods logged on tough days: ${toughFoods.join(', ')}. ' : ''}'
          '${context.foodTriggers.isNotEmpty ? 'Your marked food triggers: ${context.foodTriggers.join(', ')}. ' : ''}'
          'These are possible links, not proof. Keep logging meals and how you feel, and share the patterns with your care team.';
    }

    if (_containsAny(message, const [
      'food', 'eat', 'diet', 'meal', 'avoid', 'drink', 'breakfast', 'lunch', 'dinner', 'snack',
      'dairy', 'gluten', 'lactose', 'fibre', 'fiber', 'coffee', 'alcohol', 'spicy',
    ])) {
      final parts = <String>[];
      if (context.foodTriggers.isNotEmpty) {
        parts.add("You've marked these food triggers to avoid: ${context.foodTriggers.join(', ')}.");
      }
      if (context.safeFoods.isNotEmpty) {
        parts.add('Foods you have marked as safe: ${context.safeFoods.join(', ')}.');
      }
      if (parts.isEmpty) {
        parts.add("You haven't marked any food triggers or safe foods yet. Add them from Home, then Meals & triggers, "
            'and log your meals so patterns can show up.');
      }
      parts.add('Trigger foods differ from person to person. During a flare many people find low-fibre, lower-fat foods '
          'such as white rice, bananas, eggs and lean protein easier to tolerate. '
          'Talk to your doctor or a dietitian before cutting out whole food groups.');
      return parts.join(' ');
    }

    if (_containsAny(message, const ['symptom', 'pain', 'hurt', 'flare', 'cramp', 'diarr', 'bloat', 'nause'])) {
      final symptoms = context.recentSymptomSeverity();
      final logged = symptoms.isEmpty
          ? ''
          : 'Recently you logged ${symptoms.entries.map((e) => '${e.key} (severity ${e.value}/5)').join(', ')}. ';
      return '$logged'
          'During a flare, things that often help are resting, a heat pad on your abdomen, small low-fibre meals and plenty of fluids. '
          'Avoid anti-inflammatory painkillers such as ibuprofen unless your doctor has approved them, as they can worsen IBD. '
          'If pain is severe or comes with fever, blood in your stool or vomiting, contact your doctor or IBD team promptly.';
    }

    if (_containsAny(message, const ['feel', 'how am i', 'how have i', 'lately', 'this week', 'today', 'progress', 'doing'])) {
      final days = context.recentDailyTracking;
      if (days.isEmpty) {
        return "You haven't logged how you're feeling yet. Tap a mood on the Home screen each day, "
            'and use Add details for pain and energy, so I can show you how you are trending.';
      }
      final latest = days.first;
      final pains = days.take(7).map((d) => _asNum(d['pain_level'])).whereType<double>().toList();
      final avgPain = pains.isEmpty ? null : pains.reduce((a, b) => a + b) / pains.length;
      final okayDays = days.length - context.goodDays.length - context.toughDays.length;
      return 'Your most recent check-in (${latest['date'] ?? 'latest'}) was "${_feelingLabel(latest['feeling'])}". '
          'Across ${days.length} check-in${days.length == 1 ? '' : 's'}: ${context.goodDays.length} good, '
          '$okayDays okay and ${context.toughDays.length} tough. '
          '${avgPain != null ? 'Average pain in your recent logs: ${_formatNumber(double.parse(avgPain.toStringAsFixed(1)))}/10. ' : ''}'
          '${context.toughDays.isNotEmpty ? 'On tough days, rest, fluids and gentle food can help, and contact your care team if things get worse. ' : 'Keep doing what is working for you. '}'
          'Consistent tracking makes these trends more reliable.';
    }

    return "Hi, I'm the GutMD Assistant. "
        '${context.hasTrackedData ? "I can see what you've been tracking and can help you make sense of it. " : 'Start tracking your symptoms, meals and how you feel, and I can help you spot patterns. '}'
        'You can ask me about:\n'
        '• Your symptoms and flares\n'
        '• Foods to avoid and your safe foods\n'
        '• Supplements and medications\n'
        '• Stress and the gut\n'
        '• How you have been feeling lately\n\n'
        'I give general information, not medical advice.';
  }
}
