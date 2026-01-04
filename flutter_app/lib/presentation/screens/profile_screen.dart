/// Profile Screen
/// 
/// Displays user profile details with edit and photo upload functionality.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../core/services/audio_service.dart';
import '../../data/models/user_profile.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final profile = ref.read(userProfileProvider).profile;
    if (profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      await ref.read(userProfileProvider.notifier).uploadProfilePhoto(file);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final success = await ref.read(userProfileProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  void _testSiren(BuildContext context) {
    bool isPlaying = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              Icon(
                isPlaying ? Icons.volume_up : Icons.volume_off,
                color: isPlaying ? const Color(0xFFFF4444) : Colors.grey,
              ),
              const SizedBox(width: 12),
              const Text('Siren Test', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isPlaying 
                      ? const Color(0xFFFF4444).withOpacity(0.1) 
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPlaying 
                        ? const Color(0xFFFF4444) 
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.notifications_active,
                  size: 64,
                  color: isPlaying ? const Color(0xFFFF4444) : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPlaying 
                    ? '🔊 Siren is playing...\nTap STOP to end the test'
                    : 'Tap PLAY to test the siren alert sound and vibration',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isPlaying ? const Color(0xFFFF4444) : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            if (!isPlaying)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
              ),
            ElevatedButton.icon(
              onPressed: () {
                if (isPlaying) {
                  AudioService.instance.stopSiren();
                  setDialogState(() => isPlaying = false);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Siren test completed!')),
                  );
                } else {
                  AudioService.instance.playSiren();
                  setDialogState(() => isPlaying = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaying 
                    ? Colors.grey[700] 
                    : const Color(0xFFFF4444),
              ),
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(isPlaying ? 'STOP' : 'PLAY SIREN'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Ensure siren is stopped when dialog is dismissed
      AudioService.instance.stopSiren();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          if (profile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _initControllers();
                setState(() => _isEditing = false);
              },
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? _buildNoProfileState()
              : _buildProfileContent(profile, profileState),
    );
  }

  Widget _buildProfileContent(UserProfile profile, UserProfileState profileState) {
    final isOwner = profile.isOwner;
    final roleColor = isOwner ? const Color(0xFF00C853) : const Color(0xFF2196F3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile avatar with edit button
          Stack(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: profile.photoUrl == null
                        ? LinearGradient(
                            colors: isOwner
                                ? [const Color(0xFF00C853), const Color(0xFF00897B)]
                                : [const Color(0xFF2196F3), const Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profile.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: profile.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildAvatarPlaceholder(profile, isOwner),
                            errorWidget: (_, __, ___) => _buildAvatarPlaceholder(profile, isOwner),
                          )
                        : _buildAvatarPlaceholder(profile, isOwner),
                  ),
                ),
              ),
              // Upload indicator
              if (profileState.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              // Camera icon
              if (!profileState.isUploading)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0D0D0D), width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOwner ? Icons.agriculture : Icons.security,
                  color: roleColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  profile.role.displayName,
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Profile details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _isEditing
                    ? _buildEditableField(
                        controller: _nameController,
                        icon: Icons.person_outline,
                        label: 'Full Name',
                      )
                    : _buildDetailRow(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: profile.name,
                      ),
                const Divider(color: Color(0xFF2A2A2A), height: 24),
                _buildDetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.email,
                ),
                const Divider(color: Color(0xFF2A2A2A), height: 24),
                _isEditing
                    ? _buildEditableField(
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                      )
                    : _buildDetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: profile.phone,
                      ),
                const Divider(color: Color(0xFF2A2A2A), height: 24),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member Since',
                  value: _formatDate(profile.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button (when editing)
          if (_isEditing)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: profileState.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: profileState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

          if (!_isEditing) ...[
            const SizedBox(height: 8),
            // Test Siren button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _testSiren(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.volume_up),
                label: const Text(
                  'Test Siren Alert',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Logout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Color(0xFFFF4444)),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFFF4444),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // App version
          Text(
            'Predator Alert v1.0.0',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(UserProfile profile, bool isOwner) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOwner
              ? [const Color(0xFF00C853), const Color(0xFF00897B)]
              : [const Color(0xFF2196F3), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[800]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[400], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00C853)),
                  ),
                ),
                inputFormatters: keyboardType == TextInputType.phone
                    ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))]
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[800]!.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[400], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoProfileState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Profile not found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
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

    if (confirmed == true && context.mounted) {
      ref.read(userProfileProvider.notifier).clearProfile();
      await ref.read(authProvider.notifier).signOut();
      
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
