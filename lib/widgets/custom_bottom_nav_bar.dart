import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Trait supérieur (orange thème)
        Container(
          height: 1,
          color: theme.colorScheme.primary.withOpacity(0.4),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                IconData icon;
                switch (index) {
                  case 0:
                    icon = Icons.home_outlined;
                    break;
                  case 1:
                    icon = Icons.search;
                    break;
                  case 2:
                    icon = Icons.add_box_outlined;
                    break;
                  case 3:
                    icon = Icons.person_outline;
                    break;
                  default:
                    icon = Icons.circle;
                }

                final isSelected = index == selectedIndex;

                return GestureDetector(
                  onTap: () => onItemTapped(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 28,
                        color: isSelected
                            ? theme.colorScheme.secondary // 🔥 orange actif
                            : theme.colorScheme.onBackground
                                .withOpacity(0.6), // neutre
                      ),
                      const SizedBox(height: 6),

                      // ✅ Indicateur animé orange
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        width: isSelected ? 22 : 0,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
