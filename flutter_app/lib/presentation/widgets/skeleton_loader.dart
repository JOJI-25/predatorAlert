/// Skeleton loader widget for loading states

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for detection card loading state
class DetectionCardSkeleton extends StatelessWidget {
  const DetectionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail skeleton
            const SkeletonLoader(
              width: 64,
              height: 64,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            
            // Content skeletons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: SkeletonLoader(height: 20),
                      ),
                      const SizedBox(width: 8),
                      SkeletonLoader(
                        width: 70,
                        height: 24,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SkeletonLoader(
                    width: 120,
                    height: 14,
                  ),
                  const SizedBox(height: 6),
                  const SkeletonLoader(
                    width: 180,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of skeleton cards for loading state
class DetectionListSkeleton extends StatelessWidget {
  final int count;

  const DetectionListSkeleton({
    super.key,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (context, index) => const DetectionCardSkeleton(),
    );
  }
}
