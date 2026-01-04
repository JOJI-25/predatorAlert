/// Home screen with bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../data/models/user_profile.dart';
import '../widgets/siren_overlay.dart';
import 'detection_list_screen.dart';
import 'contacts_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _showingSirenOverlay = false;
  Map<String, dynamic>? _currentAlertData;

  final List<Widget> _screens = [
    const DetectionListScreen(),
    const ContactsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupAlertListener();
    _checkProfile(); // Deferred profile check
  }
  
  /// Check if user has a profile, redirect if not
  Future<void> _checkProfile() async {
    final hasProfile = await ref.read(userProfileProvider.notifier).checkUserProfile();
    if (!hasProfile && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    }
  }

  void _setupAlertListener() {
    // Listen for predator alerts from notification service
    NotificationService.instance.onPredatorAlert = (data) {
      if (mounted && !_showingSirenOverlay) {
        setState(() {
          _showingSirenOverlay = true;
          _currentAlertData = data;
        });
      }
    };
  }

  void _dismissAlert() {
    setState(() {
      _showingSirenOverlay = false;
      _currentAlertData = null;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Scaffold(
          appBar: _buildAppBar(),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
        
        // Siren overlay (shows on top when predator detected)
        if (_showingSirenOverlay && _currentAlertData != null)
          SirenOverlay(
            animal: _currentAlertData!['animal'] ?? 'Unknown',
            confidence: double.tryParse(
              _currentAlertData!['confidence']?.toString() ?? '0'
            ) ?? 0.0,
            imageUrl: _currentAlertData!['image_url'],
            onAcknowledge: _dismissAlert,
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;
    
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        'Predator',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Profile icon button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                if (profile != null) ...[
                  Text(
                    profile.name.split(' ').first,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: profile?.isOwner == true
                        ? const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF00897B)],
                          )
                        : profile?.isAuthority == true
                            ? const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                              )
                            : LinearGradient(
                                colors: [Colors.grey[600]!, Colors.grey[800]!],
                              ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: profile != null && profile.name.isNotEmpty
                        ? Text(
                            profile.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.sensors,
                label: AppStrings.detections,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.contacts,
                label: AppStrings.contacts,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

