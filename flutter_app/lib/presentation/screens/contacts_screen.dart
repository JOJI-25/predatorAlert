/// Contacts screen displaying role-based contacts from Firestore
/// 
/// - Owners see: Authority contacts (to call for help)
/// - Authorities see: Owner contacts (to contact affected farmers)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/providers/user_profile_provider.dart';
import '../../data/models/user_profile.dart';
import 'chat_screen.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final currentUserRole = profileState.profile?.role;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.contacts),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          if (profileState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (currentUserRole == null) {
            return _buildNoRoleState();
          }
          
          // Determine which contacts to show based on role
          final targetRole = currentUserRole == UserRole.owner 
              ? UserRole.authority 
              : UserRole.owner;
          
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: targetRole.name)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              
              final users = snapshot.data?.docs
                  .map((doc) => UserProfile.fromFirestore(doc))
                  .toList() ?? [];
              
              if (users.isEmpty) {
                return _buildEmptyState(targetRole);
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role info card
                    _buildRoleInfoCard(currentUserRole, targetRole),
                    const SizedBox(height: 24),
                    
                    // Section header
                    _buildSectionHeader(
                      icon: targetRole == UserRole.authority 
                          ? Icons.security 
                          : Icons.agriculture,
                      title: targetRole == UserRole.authority 
                          ? 'Authority Contacts'
                          : 'Owner Contacts',
                      color: targetRole == UserRole.authority 
                          ? const Color(0xFF2196F3) 
                          : const Color(0xFF00C853),
                      count: users.length,
                    ),
                    const SizedBox(height: 12),
                    
                    // Contact cards
                    ...users.map((user) => _buildContactCard(
                      context,
                      user,
                      isAuthority: user.isAuthority,
                    )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoleInfoCard(UserRole currentRole, UserRole targetRole) {
    final isOwner = currentRole == UserRole.owner;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOwner 
              ? [const Color(0xFF00C853), const Color(0xFF00897B)]
              : [const Color(0xFF2196F3), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOwner ? Icons.agriculture : Icons.security,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are ${isOwner ? "a Farm Owner" : "an Authority"}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOwner 
                      ? 'Contact authorities for help during emergencies'
                      : 'Contact farm owners when predators are detected',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context, UserProfile user, {required bool isAuthority}) {
    final color = isAuthority ? const Color(0xFF2196F3) : const Color(0xFF00C853);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(contact: user),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Name and phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: color.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to chat',
                        style: TextStyle(
                          fontSize: 13,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Chat arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRoleState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'Profile not set up',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please complete your profile to view contacts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UserRole targetRole) {
    final isAuthority = targetRole == UserRole.authority;
    
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
            child: Icon(
              isAuthority ? Icons.security_outlined : Icons.agriculture_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAuthority ? 'No authorities registered' : 'No farm owners registered',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              isAuthority 
                  ? 'Authority contacts will appear here when they register'
                  : 'Farm owner contacts will appear here when they register',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
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
            'Error loading contacts',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
