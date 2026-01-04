/// Detection detail screen with full image and metadata

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/detection.dart';

class DetectionDetailScreen extends StatelessWidget {
  final Detection detection;

  const DetectionDetailScreen({
    super.key,
    required this.detection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSection(),
            ),
          ),
          
          // Detection details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with badge
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Metadata cards
                  _buildMetadataSection(),
                  const SizedBox(height: 24),
                  
                  // Alert status
                  if (detection.isPredator) _buildAlertStatus(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(color: AppColors.surface),
        
        // Image
        if (detection.imageUrl != null)
          CachedNetworkImage(
            imageUrl: detection.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => _buildImagePlaceholder(),
          )
        else
          _buildImagePlaceholder(),
        
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background.withOpacity(0.8),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        
        // Predator border glow
        if (detection.isPredator)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.predatorAlert.withOpacity(0.5),
                width: 3,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          detection.isPredator ? Icons.warning_rounded : Icons.pets,
          size: 80,
          color: detection.isPredator 
              ? AppColors.predatorAlert.withOpacity(0.5) 
              : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animal name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detection.animalName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detection.fullFormattedTime,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Badge
        _buildBadge(),
      ],
    );
  }

  Widget _buildBadge() {
    if (!detection.isPredator) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.normalDetection.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.normalDetection.withOpacity(0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 18,
              color: AppColors.normalDetection,
            ),
            SizedBox(width: 6),
            Text(
              'SAFE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.normalDetection,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.predatorGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.predatorAlert.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 18,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'PREDATOR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      children: [
        // Confidence row
        _buildMetadataCard(
          icon: Icons.analytics,
          label: 'Confidence',
          value: detection.confidencePercent,
          valueColor: _getConfidenceColor(),
        ),
        const SizedBox(height: 12),
        
        // Device row
        _buildMetadataCard(
          icon: Icons.devices,
          label: 'Device ID',
          value: detection.deviceId,
        ),
        const SizedBox(height: 12),
        
        // Detection ID row
        _buildMetadataCard(
          icon: Icons.fingerprint,
          label: 'Detection ID',
          value: detection.id,
          isMonospace: true,
        ),
      ],
    );
  }

  Widget _buildMetadataCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.predatorAlert.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.predatorAlert.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.predatorAlert.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              detection.alertSent 
                  ? Icons.notifications_active 
                  : Icons.notifications_off,
              size: 24,
              color: AppColors.predatorAlert,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alert Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detection.alertSent 
                      ? 'Authorities and owner notified' 
                      : 'Alert not sent',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (detection.alertSent)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (detection.confidence >= 0.8) {
      return detection.isPredator 
          ? AppColors.predatorAlert 
          : AppColors.success;
    } else if (detection.confidence >= 0.5) {
      return AppColors.warning;
    }
    return AppColors.textSecondary;
  }
}
