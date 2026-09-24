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

  static const List<DietFlagItem> _commonDietFlags = [
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

  // Items the user typed that are not in the predefined list.
  List<String> get _customItems {
    return widget.controller.data.dietFlags
        .where((flag) => !_commonDietFlags.any((item) => item.name == flag))
        .toList();
  }

  bool get _canAddCustom => _customController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Adds the typed item. A case-insensitive match of a common trigger selects
  /// that card instead of creating a duplicate custom entry, and an item that
  /// is already on the list is not added twice.
  void _addCustomItem() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final lower = value.toLowerCase();
    final alreadyAdded =
        widget.controller.data.dietFlags.any((flag) => flag.toLowerCase() == lower);
    String name = value;
    for (final item in _commonDietFlags) {
      if (item.name.toLowerCase() == lower) {
        name = item.name;
        break;
      }
    }
    setState(() {
      if (!alreadyAdded) {
        widget.controller.addDietFlag(name);
      }
      _customController.clear();
    });
  }

  Widget _buildRemoveButton(String itemName, VoidCallback onDelete) {
    return IconButton(
      tooltip: 'Remove $itemName',
      onPressed: onDelete,
      icon: const Icon(Icons.close, color: Colors.red, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: Colors.red.withValues(alpha: 0.2),
        fixedSize: const Size(32, 32),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// A trigger card. With [onTap] it is a checkbox the user can toggle; with
  /// [onDelete] it is a custom entry that can only be removed.
  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? OnboardingTheme.accentIndigo.withValues(alpha: 0.3)
                  : OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : OnboardingTheme.lightIndigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            _buildRemoveButton(title, onDelete)
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
    );

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? OnboardingTheme.accentIndigo
                : OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: onTap == null
            ? Semantics(container: true, child: content)
            : Semantics(
                container: true,
                checked: isSelected,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: content,
                ),
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
                      tooltip: 'Back',
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

                        const Text(
                          'Select foods or ingredients that affect you',
                          style: OnboardingTheme.subheadingStyle,
                        ),

                        const SizedBox(height: 24),

                        // Add Custom Item section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
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
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    hintText: 'Add custom item (e.g., Tomatoes)',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _addCustomItem(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _canAddCustom ? _addCustomItem : null,
                                style: _addButtonStyle,
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_customItems.length, (index) {
                            final item = _customItems[index];
                            return Padding(
                              key: ValueKey('custom-diet-$item'),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StaggeredAnimation(
                                index: index,
                                child: _buildOptionCard(
                                  title: item,
                                  description: 'Custom diet consideration',
                                  icon: Icons.restaurant_menu_outlined,
                                  isSelected: true,
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                            color: OnboardingTheme.accentIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
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
                                  'Not sure yet? You can skip this step and log trigger and safe foods any time in the Diet tracker.',
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

final ButtonStyle _addButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: OnboardingTheme.accentIndigo,
  foregroundColor: Colors.white,
  disabledBackgroundColor: OnboardingTheme.accentIndigo.withValues(alpha: 0.3),
  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  minimumSize: const Size(0, 40),
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);
