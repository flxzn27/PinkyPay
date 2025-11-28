import 'package:flutter/material.dart';
import '../config/colors.dart';

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.primaryPink,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primaryPink)
                      .withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.white,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.darkPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}