import 'package:flutter/material.dart';
import '../app_theme.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking GPS')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gps_fixed_rounded,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Tracking GPS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fitur ini akan segera hadir',
              style: TextStyle(fontSize: 13, color: context.textMutedColor),
            ),
          ],
        ),
      ),
    );
  }
}