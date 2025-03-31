import 'package:flutter/material.dart';
import 'package:crohns_companion/core/theme/app_theme.dart';
import 'package:crohns_companion/core/backend_service_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic> _insightsData = {};

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final insightsService = BackendServiceProvider.instance.insights;
      final userId = BackendServiceProvider.instance.auth.currentUser?.id ?? '';
      
      final insights = await insightsService.getUserInsights(userId);
      
      if (mounted) {
        setState(() {
          _insightsData = insights ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load insights: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _refreshInsights() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final insightsService = BackendServiceProvider.instance.insights;
      final userId = BackendServiceProvider.instance.auth.currentUser?.id ?? '';
      
      // Generate new insights
      await insightsService.generateInsights(userId);
      
      // Fetch the newly generated insights
      final insights = await insightsService.getUserInsights(userId);
      
      if (mounted) {
        setState(() {
          _insightsData = insights ?? {};
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insights refreshed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh insights: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: _isRefreshing ? null : _refreshInsights,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI-powered analysis of your health data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Main content with scrolling
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _insightsData.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshInsights,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Health Summary
                              _buildHealthSummary(),
                              const SizedBox(height: 24),
                              // Food Triggers
                              _buildFoodTriggers(),
                              const SizedBox(height: 24),
                              // Beneficial Foods
                              _buildBeneficialFoods(),
                              const SizedBox(height: 24),
                              // Supplement Effectiveness
                              _buildSupplementEffectiveness(),
                              const SizedBox(height: 24),
                              // Recommendations
                              _buildRecommendations(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppTheme.lightTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No insights available yet',
            style: TextStyle(
              color: AppTheme.lightTextColor.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your symptoms, diet, and supplements\nto generate personalized insights',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.lightTextColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshInsights,
            child: const Text('Generate Insights'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummary() {
    final healthSummary = _insightsData['health_summary'] as Map<String, dynamic>? ?? {};
    final trend = healthSummary['trend'] as String? ?? 'stable';
    final score = healthSummary['score'] as int? ?? 0;
    
    IconData trendIcon;
    Color trendColor;
    String trendText;
    
    switch (trend) {
      case 'improving':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Improving';
        break;
      case 'worsening':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Worsening';
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orange;
        trendText = 'Stable';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                          Icon(trendIcon, color: trendColor),
                          const SizedBox(width: 8),
                          Text(
                            trendText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: trendColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthSummary['description'] as String? ?? 'No summary available',
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTriggers() {
    final foodTriggers = _insightsData['food_triggers'] as List<dynamic>? ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Food Triggers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            foodTriggers.isEmpty
                ? const Text(
                    'No food triggers identified yet',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  )
                : Column(
                    children: foodTriggers.map((trigger) {
                      final food = trigger['food'] as String? ?? '';
                      final correlation = trigger['correlation'] as double? ?? 0.0;
                      final correlationPercent = (correlation * 100).toInt();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                food,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: correlation,
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$correlationPercent% correlation with symptoms',
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
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficialFoods() {
    final beneficialFoods = _insightsData['beneficial_foods'] as List<dynamic>? ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beneficial Foods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            beneficialFoods.isEmpty
                ? const Text(
                    'No beneficial foods identified yet',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  )
                : Column(
                    children: beneficialFoods.map((food) {
                      final name = food['food'] as String? ?? '';
                      final impact = food['impact'] as double? ?? 0.0;
                      final impactPercent = (impact * 100).toInt();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: impact,
                                    backgroundColor: Colors.green.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$impactPercent% positive impact',
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
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementEffectiveness() {
    final supplements = _insightsData['supplement_effectiveness'] as List<dynamic>? ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supplement Effectiveness',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            supplements.isEmpty
                ? const Text(
                    'No supplement data available yet',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  )
                : Column(
                    children: supplements.map((supplement) {
                      final name = supplement['name'] as String? ?? '';
                      final effectiveness = supplement['effectiveness'] as double? ?? 0.0;
                      final effectivenessPercent = (effectiveness * 100).toInt();
                      
                      Color effectivenessColor;
                      if (effectiveness > 0.7) {
                        effectivenessColor = Colors.green;
                      } else if (effectiveness > 0.4) {
                        effectivenessColor = Colors.orange;
                      } else {
                        effectivenessColor = Colors.red;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: effectiveness,
                                    backgroundColor: effectivenessColor.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(effectivenessColor),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$effectivenessPercent% effectiveness',
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
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _insightsData['recommendations'] as List<dynamic>? ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            recommendations.isEmpty
                ? const Text(
                    'No recommendations available yet',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  )
                : Column(
                    children: recommendations.map((recommendation) {
                      final title = recommendation['title'] as String? ?? '';
                      final description = recommendation['description'] as String? ?? '';
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
                                color: AppTheme.neutralColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                categoryIcon,
                                color: AppTheme.primaryColor,
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
          ],
        ),
      ),
    );
  }
}