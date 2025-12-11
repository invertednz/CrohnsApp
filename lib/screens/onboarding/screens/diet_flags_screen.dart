import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../onboarding_controller.dart';
import '../widgets/staggered_animation.dart';

class DietFlagItem {
  final String name;
  final String description;
  final IconData icon;

  const DietFlagItem({
    required this.name,
    required this.description,
    required this.icon,
  });
}

class DietFlagsScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const DietFlagsScreen({
    Key? key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<DietFlagsScreen> createState() => _DietFlagsScreenState();
}

class _DietFlagsScreenState extends State<DietFlagsScreen> {
  final TextEditingController _customController = TextEditingController();
  
  final List<DietFlagItem> _commonDietFlags = const [
    DietFlagItem(
      name: 'Dairy',
      description: 'Milk, cheese, yogurt, and dairy products',
      icon: Icons.local_cafe_outlined,
    ),
    DietFlagItem(
      name: 'Gluten',
      description: 'Wheat, barley, rye, and related grains',
      icon: Icons.breakfast_dining_outlined,
    ),
    DietFlagItem(
      name: 'Lactose',
      description: 'Lactose-containing foods and beverages',
      icon: Icons.water_drop_outlined,
    ),
    DietFlagItem(
      name: 'Spicy Foods',
      description: 'Hot peppers, chili, and spicy dishes',
      icon: Icons.local_fire_department_outlined,
    ),
    DietFlagItem(
      name: 'High Fiber',
      description: 'Whole grains, beans, and fibrous vegetables',
      icon: Icons.grass_outlined,
    ),
    DietFlagItem(
      name: 'Caffeine',
      description: 'Coffee, tea, energy drinks, and chocolate',
      icon: Icons.coffee_outlined,
    ),
    DietFlagItem(
      name: 'Alcohol',
      description: 'Beer, wine, spirits, and alcoholic beverages',
      icon: Icons.wine_bar_outlined,
    ),
    DietFlagItem(
      name: 'Artificial Sweeteners',
      description: 'Sugar substitutes and diet products',
      icon: Icons.science_outlined,
    ),
    DietFlagItem(
      name: 'Red Meat',
      description: 'Beef, pork, lamb, and processed meats',
      icon: Icons.restaurant_outlined,
    ),
    DietFlagItem(
      name: 'Fried Foods',
      description: 'Deep-fried and oil-heavy dishes',
      icon: Icons.fastfood_outlined,
    ),
    DietFlagItem(
      name: 'Raw Vegetables',
      description: 'Uncooked vegetables and salads',
      icon: Icons.eco_outlined,
    ),
    DietFlagItem(
      name: 'Nuts & Seeds',
      description: 'Tree nuts, peanuts, and various seeds',
      icon: Icons.spa_outlined,
    ),
  ];

  // Track custom items separately (items not in predefined list)
  List<String> get _customItems {
    return widget.controller.data.dietFlags
        .where((flag) => !_commonDietFlags.any((item) => item.name == flag))
        .toList();
  }
  
  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? OnboardingTheme.accentIndigo.withOpacity(0.3)
                    : OnboardingTheme.accentIndigo.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : OnboardingTheme.lightIndigo,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator or delete button
            if (isCustom && onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              )
            else if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: OnboardingTheme.accentIndigo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: OnboardingTheme.primaryGradient,
        ),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      
                      Text(
                        'Diet Considerations',
                        style: OnboardingTheme.headingTextStyle(fontSize: 32),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Select foods or ingredients that affect you',
                        style: OnboardingTheme.subheadingStyle,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Add Custom Item section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                color: OnboardingTheme.lightIndigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _customController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Add custom item (e.g., Tomatoes)',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    setState(() {
                                      widget.controller.addDietFlag(value.trim());
                                      _customController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_customController.text.trim().isNotEmpty) {
                                  setState(() {
                                    widget.controller.addDietFlag(_customController.text.trim());
                                    _customController.clear();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.accentIndigo,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Custom Items section
                      if (_customItems.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Your Custom Items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_customItems.length, (index) {
                          final item = _customItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StaggeredAnimation(
                              index: index,
                              child: _buildOptionCard(
                                title: item,
                                description: 'Custom diet consideration',
                                icon: Icons.restaurant_menu_outlined,
                                isSelected: true,
                                isCustom: true,
                                onTap: () {},
                                onDelete: () {
                                  setState(() {
                                    widget.controller.removeDietFlag(item);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Common Triggers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Common diet flags as cards
                      ...List.generate(_commonDietFlags.length, (index) {
                        final item = _commonDietFlags[index];
                        final isSelected = widget.controller.data.dietFlags.contains(item.name);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StaggeredAnimation(
                            index: index,
                            child: _buildOptionCard(
                              title: item.name,
                              description: item.description,
                              icon: item.icon,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  widget.controller.toggleDietFlag(item.name);
                                });
                              },
                            ),
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 16),
                      
                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OnboardingTheme.accentIndigo.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OnboardingTheme.accentIndigo.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: OnboardingTheme.lightIndigo,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can always update these later in settings',
                                style: OnboardingTheme.bodyStyle.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: OnboardingTheme.primaryButtonStyle().copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
