import 'package:flutter/material.dart';
import 'package:smart_wash/constants/app_colors.dart';

class FeedbackErrorWidget extends StatelessWidget {
  const FeedbackErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          "Couldn't load feedback",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Please check your connection and try again",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            // Add retry logic
          },
          child: Text(
            "Try Again",
            style: TextStyle(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
