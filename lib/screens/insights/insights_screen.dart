import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gut_md/core/theme/app_theme.dart';
import 'package:gut_md/core/backend_service_provider.dart';
import 'package:gut_md/screens/diet/diet_screen.dart';
import 'package:gut_md/screens/tracking/tracking_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;
  Map<String, dynamic> _insightsData = {};

  String get _userId => BackendServiceProvider.instance.auth.currentUser?.id ?? '';

  /// Insights built from no tracked data at all get the getting-started view.
  bool get _hasNoData {
    if (_insightsData.isEmpty) return true;
    final dataPoints = _insightsData['data_points'];
    return dataPoints is num && dataPoints <= 0;
  }

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final insightsService = BackendServiceProvider.instance.insights;
      var insights = await insightsService.getUserInsights(_userId);
      // Insights saved before anything was logged go stale as soon as the
      // user tracks something, so rebuild them rather than show "no data".
      final dataPoints = insights?['data_points'];
      final generatedAt = DateTime.tryParse('${insights?['generated_at'] ?? ''}');
      final justGenerated =
          generatedAt != null && DateTime.now().difference(generatedAt).inSeconds.abs() < 10;
      if (dataPoints is num && dataPoints <= 0 && !justGenerated) {
        await insightsService.generateInsights(_userId);
        insights = await insightsService.getUserInsights(_userId);
      }
      if (!mounted) return;
      setState(() {
        _insightsData = insights ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'We couldn\'t load your insights. Check your connection and try again.';
      });
    }
  }

  /// Rebuilds insights from the latest tracked data.
  Future<void> _refreshInsights({bool announce = true}) async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });

    try {
      final insightsService = BackendServiceProvider.instance.insights;
      await insightsService.generateInsights(_userId);
      final insights = await insightsService.getUserInsights(_userId);
      if (!mounted) return;
      setState(() {
        _insightsData = insights ?? {};
        _loadError = null;
      });
      if (announce) _showSnack('Insights refreshed');
    } catch (e) {
      if (mounted) {
        _showSnack('Couldn\'t refresh insights. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Opens a logging screen, then rebuilds insights with whatever was logged.
  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _refreshInsights(announce: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(12, 52, 12, 24),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Insights',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isRefreshing)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            semanticsLabel: 'Refreshing insights',
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Refresh insights',
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        onPressed: _isLoading ? null : () => _refreshInsights(),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'Patterns found in the data you have tracked',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content with scrolling
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? _buildErrorState()
                    : _hasNoData
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _refreshInsights(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSourceLine(),
                                  const SizedBox(height: 16),
                                  _buildHealthSummary(),
                                  const SizedBox(height: 24),
                                  _buildFoodTriggers(),
                                  const SizedBox(height: 24),
                                  _buildBeneficialFoods(),
                                  const SizedBox(height: 24),
                                  _buildSupplementEffectiveness(),
                                  const SizedBox(height: 24),
                                  _buildRecommendations(),
                                  const SizedBox(height: 24),
                                  _buildDisclaimer(),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AppTheme.lightTextColor),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInsights,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppTheme.lightTextColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'No insights yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log how you feel and what you eat for a few days. '
            'Insights are built only from your own data, so the more you track, '
            'the more useful they become.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.lightTextColor.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openAndRefresh(const TrackingScreen()),
              icon: const Icon(Icons.mood),
              label: const Text('Log how you feel'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAndRefresh(const DietScreen()),
              icon: const Icon(Icons.restaurant_outlined),
              label: const Text('Log meals'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLine() {
    final isGemini = _insightsData['source'] == 'gemini';
    final generatedAt = DateTime.tryParse('${_insightsData['generated_at'] ?? ''}');
    final updated = generatedAt == null
        ? ''
        : ' · Updated ${DateFormat('MMM d, h:mm a').format(generatedAt.toLocal())}';
    return Row(
      children: [
        Icon(
          isGemini ? Icons.auto_awesome : Icons.phone_android,
          size: 16,
          color: AppTheme.lightIndigo,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${isGemini ? 'Analysed by Gemini from your logs' : 'Calculated on your device from your logs'}$updated',
            style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, String? subtitle, required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppTheme.lightTextColor),
    );
  }

  List<Map<String, dynamic>> _items(String key) {
    final value = _insightsData[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// One named row with an optional 0-1 bar and the evidence behind it.
  Widget _buildMetricRow({
    required String name,
    required double? value,
    required String? note,
    required String fallbackCaption,
    required Color color,
  }) {
    final clamped = value?.clamp(0.0, 1.0);
    final caption = (note != null && note.trim().isNotEmpty)
        ? note
        : clamped == null
            ? ''
            : '${(clamped * 100).round()}% $fallbackCaption';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (clamped != null && clamped > 0) ...[
                  ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: clamped,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummary() {
    final healthSummary = _insightsData['health_summary'] is Map
        ? Map<String, dynamic>.from(_insightsData['health_summary'] as Map)
        : <String, dynamic>{};
    final trend = healthSummary['trend'] as String? ?? 'unknown';
    final score = (healthSummary['score'] as num?)?.round().clamp(0, 100);

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (trend) {
      case 'improving':
        trendIcon = Icons.trending_up;
        trendColor = Colors.greenAccent;
        trendText = 'Improving';
        break;
      case 'worsening':
        trendIcon = Icons.trending_down;
        trendColor = Colors.redAccent;
        trendText = 'Worsening';
        break;
      case 'stable':
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orangeAccent;
        trendText = 'Stable';
        break;
      default:
        trendIcon = Icons.timeline;
        trendColor = AppTheme.lightTextColor;
        trendText = 'Trend: not enough data yet';
    }

    return _sectionCard(
      title: 'Health Summary',
      subtitle: 'Wellbeing score out of 100, from how you felt and your pain levels',
      child: Row(
        children: [
          Semantics(
            label: score == null ? 'Wellbeing score not available yet' : 'Wellbeing score $score out of 100',
            excludeSemantics: true,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accentIndigo.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentIndigo.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text(
                  score == null ? '–' : '$score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        trendText,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${healthSummary['description'] ?? ''}'.trim().isEmpty
                      ? 'No summary available'
                      : '${healthSummary['description']}',
                  style: const TextStyle(
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTriggers() {
    final foodTriggers = _items('food_triggers');
    return _sectionCard(
      title: 'Possible Food Triggers',
      subtitle: 'Foods that showed up more on your tough days',
      child: foodTriggers.isEmpty
          ? _emptyText('No likely triggers yet. Log your meals on rough days as well as good ones so patterns can show up.')
          : Column(
              children: foodTriggers
                  .map((trigger) => _buildMetricRow(
                        name: '${trigger['food'] ?? ''}',
                        value: (trigger['correlation'] as num?)?.toDouble(),
                        note: trigger['note'] as String?,
                        fallbackCaption: 'link to tough days',
                        color: Colors.redAccent,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildBeneficialFoods() {
    final beneficialFoods = _items('beneficial_foods');
    return _sectionCard(
      title: 'Foods on Your Good Days',
      subtitle: 'Foods that showed up more when you felt good',
      child: beneficialFoods.isEmpty
          ? _emptyText('Nothing stands out yet. Log meals on your good days too.')
          : Column(
              children: beneficialFoods
                  .map((food) => _buildMetricRow(
                        name: '${food['food'] ?? ''}',
                        value: (food['impact'] as num?)?.toDouble(),
                        note: food['note'] as String?,
                        fallbackCaption: 'link to good days',
                        color: Colors.greenAccent,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildSupplementEffectiveness() {
    final supplements = _items('supplement_effectiveness');
    return _sectionCard(
      title: 'Supplements and Your Days',
      subtitle: 'How often you felt good on days you took each supplement',
      child: supplements.isEmpty
          ? _emptyText('Mark supplements as taken on the Supps tab and rate your days to compare them.')
          : Column(
              children: supplements
                  .map((supplement) => _buildMetricRow(
                        name: '${supplement['name'] ?? ''}',
                        value: (supplement['effectiveness'] as num?)?.toDouble(),
                        note: supplement['note'] as String?,
                        fallbackCaption: 'good days while taking',
                        color: AppTheme.lightIndigo,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _items('recommendations');
    return _sectionCard(
      title: 'Personalized Recommendations',
      child: recommendations.isEmpty
          ? _emptyText('Keep logging to get suggestions based on your data.')
          : Column(
              children: recommendations.map((recommendation) {
                final title = '${recommendation['title'] ?? ''}';
                final description = '${recommendation['description'] ?? ''}';
                final category = recommendation['category'] as String? ?? 'general';

                IconData categoryIcon;
                switch (category) {
                  case 'diet':
                    categoryIcon = Icons.restaurant_outlined;
                    break;
                  case 'supplements':
                    categoryIcon = Icons.medication_outlined;
                    break;
                  case 'lifestyle':
                    categoryIcon = Icons.self_improvement_outlined;
                    break;
                  case 'medical':
                    categoryIcon = Icons.local_hospital_outlined;
                    break;
                  default:
                    categoryIcon = Icons.lightbulb_outline;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accentIndigo.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: AppTheme.lightIndigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: const TextStyle(
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDisclaimer() {
    return Text(
      'Insights only reflect what you have logged and are not medical advice. '
      'Talk to your care team before changing your treatment or diet.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppTheme.lightTextColor.withValues(alpha: 0.8),
      ),
    );
  }
}
