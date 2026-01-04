/// Detection card widget for list display

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/detection.dart';

class DetectionCard extends StatelessWidget {
  final Detection detection;
  final VoidCallback? onTap;

  const DetectionCard({
    super.key,
    required this.detection,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal name and badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detection.animalName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _buildBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Confidence
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 14,
                          color: _getConfidenceColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Confidence: ${detection.confidencePercent}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _getConfidenceColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Timestamp and device
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detection.formattedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.devices,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            detection.deviceId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceLight,
        border: Border.all(
          color: detection.isPredator 
              ? AppColors.predatorAlert.withOpacity(0.3) 
              : AppColors.surfaceLight,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: detection.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: detection.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        detection.isPredator ? Icons.warning_rounded : Icons.pets,
        color: detection.isPredator 
            ? AppColors.predatorAlert 
            : AppColors.textMuted,
        size: 28,
      ),
    );
  }

  Widget _buildBadge() {
    if (!detection.isPredator) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.normalDetection.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'SAFE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.normalDetection,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.predatorGradient,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.predatorAlert.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'PREDATOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
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
    return AppColors.textMuted;
  }
}
