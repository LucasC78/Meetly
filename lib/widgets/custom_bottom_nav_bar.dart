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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trait violet au-dessus
        Container(
          height: 1,
          color: const Color(0xFF9F6BFF), // Violet clair
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
                        color: Colors.cyanAccent,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        width: isSelected ? 22 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA78BFA),
                          borderRadius: BorderRadius.circular(1),
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
