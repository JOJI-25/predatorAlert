/// Detection list screen with real-time Firestore stream

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/detection.dart';
import '../widgets/detection_card.dart';
import '../widgets/skeleton_loader.dart';
import 'detection_detail_screen.dart';

class DetectionListScreen extends StatefulWidget {
  const DetectionListScreen({super.key});

  @override
  State<DetectionListScreen> createState() => _DetectionListScreenState();
}

class _DetectionListScreenState extends State<DetectionListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sensors,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Detection list
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseService.instance.getDetectionsStream(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: DetectionListSkeleton(),
                );
              }
              
              // Error state
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _buildErrorState(snapshot.error.toString()),
                );
              }
              
              // Empty state
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }
              
              // Detection list
              return SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final detection = Detection.fromFirestore(docs[index]);
                      return DetectionCard(
                        detection: detection,
                        onTap: () => _openDetail(detection),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openDetail(Detection detection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectionDetailScreen(detection: detection),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No detections yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your area is currently safe',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.errorLoadingData,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
