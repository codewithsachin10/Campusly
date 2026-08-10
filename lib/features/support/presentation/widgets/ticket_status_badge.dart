import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TicketStatusBadge extends StatelessWidget {
  final String status;
  
  const TicketStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'in progress':
        dotColor = Colors.orange;
        bgColor = const Color(0xFFFFF7E0); // Light yellow
        textColor = const Color(0xFFB58000); // Darker yellow/orange
        break;
      case 'resolved':
      case 'closed':
        dotColor = Colors.green;
        bgColor = const Color(0xFFE8F5E9); // Light green
        textColor = const Color(0xFF2E7D32); // Dark green
        break;
      case 'open':
      default:
        dotColor = AppColors.primary;
        bgColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
