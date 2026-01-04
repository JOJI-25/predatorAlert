/// Profile Setup Screen
/// 
/// Screen for new users to set up their profile after signup.
/// Collects role (Owner/Authority), name, and phone number.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../data/models/user_profile.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.owner;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(userProfileProvider.notifier).createProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Header
                _buildHeader(),
                
                const SizedBox(height: 40),
                
                // Error message
                if (profileState.errorMessage != null)
                  _buildErrorBanner(profileState.errorMessage!),
                
                // Role selection
                _buildRoleSelection(),
                
                const SizedBox(height: 24),
                
                // Name field
                _buildNameField(),
                
                const SizedBox(height: 16),
                
                // Phone field
                _buildPhoneField(),
                
                const SizedBox(height: 32),
                
                // Submit button
                _buildSubmitButton(),
                
                const SizedBox(height: 16),
                
                // Info text
                _buildInfoText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about yourself to get started',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                role: UserRole.owner,
                icon: Icons.agriculture,
                title: 'Farm Owner',
                subtitle: 'I own livestock/farm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleOption(
                role: UserRole.authority,
                icon: Icons.security,
                title: 'Authority',
                subtitle: 'Forest/Police dept',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (role == UserRole.owner 
                  ? const Color(0xFF00C853).withOpacity(0.15)
                  : const Color(0xFF2196F3).withOpacity(0.15))
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (role == UserRole.owner 
                    ? const Color(0xFF00C853)
                    : const Color(0xFF2196F3))
                : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected 
                  ? (role == UserRole.owner 
                      ? const Color(0xFF00C853)
                      : const Color(0xFF2196F3))
                  : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _selectedRole == UserRole.owner 
                ? const Color(0xFF00C853)
                : const Color(0xFF2196F3),
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
      ],
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),
        hintText: '+91 XXXXX XXXXX',
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _selectedRole == UserRole.owner 
                ? const Color(0xFF00C853)
                : const Color(0xFF2196F3),
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your phone number';
        }
        if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedRole == UserRole.owner 
              ? const Color(0xFF00C853)
              : const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Complete Setup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedRole == UserRole.owner
                  ? 'As a Farm Owner, you will receive predator alerts and can contact authorities for help.'
                  : 'As an Authority, you will receive predator alerts and can view owner contact details.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
