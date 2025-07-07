import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signify_project/services/userProfile.dart';
import 'package:signify_project/config/network_config.dart';

class ViewProfileScreen extends ConsumerWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'LeagueSpartan',
                ),
              ),
            ),
        data: (user) {
          final String? profileImageUrl =
              (user.profileImage.isNotEmpty)
                  ? (user.profileImage.startsWith('http')
                      ? user.profileImage
                      : user.profileImage.startsWith('/')
                      ? '${NetworkConfig.baseUrl}${user.profileImage}'
                      : '${NetworkConfig.baseUrl}/${user.profileImage}')
                  : null;

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFE3F1FB),
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          'assets/images/back.png',
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, top: 8),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          icon: Image.asset(
                            'assets/images/logout.png',
                            height: 40,
                            width: 40,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 24),
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage:
                                profileImageUrl != null
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                            child:
                                (user.profileImage.isEmpty)
                                    ? const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.blue,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.fullname,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.black,
                              fontFamily: 'LeagueSpartan',
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              text: 'User Type: ',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontFamily: 'LeagueSpartan',
                              ),
                              children: [
                                TextSpan(
                                  text: user.role,
                                  style: const TextStyle(
                                    color: Color(0xFF3B8EDB),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    fontFamily: 'LeagueSpartan',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Text(
                      'PROFILE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 1.2,
                        fontFamily: 'LeagueSpartan',
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/edit_profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6EBFF),
                        foregroundColor: Colors.black,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          fontFamily: 'LeagueSpartan',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 3, color: Colors.black87, height: 0),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  children: [
                    const SizedBox(height: 18),
                    _ProfileRow(
                      imagePath: 'assets/images/b_user.png',
                      label: 'Username',
                      value: user.username,
                    ),
                    const SizedBox(height: 18),
                    _ProfileRow(
                      imagePath: 'assets/images/b_email.png',
                      label: 'Email',
                      value: user.email,
                      imageWidth: 45,
                      imageHeight: 60,
                    ),
                    const SizedBox(height: 18),
                    _ProfileRow(
                      imagePath: 'assets/images/b_calendar.png',
                      label: 'Date of Birth',
                      value: user.dateOfBirth,
                    ),
                    const SizedBox(height: 18),
                    _ProfileRow(
                      imagePath: 'assets/images/b_setting.png',
                      label: 'User Role',
                      value: '',
                      trailing: Image.asset(
                        user.role == 'normal user'
                            ? 'assets/images/radioUser.png'
                            : user.role == 'hearing-impaired'
                            ? 'assets/images/radioUnhear.png'
                            : user.role == 'speech-impaired'
                            ? 'assets/images/radioNospeech.png'
                            : 'assets/images/radioUser.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF005FCE),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: Image.asset(
                  'assets/images/home.png',
                  width: 59,
                  height: 52,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                child: Image.asset(
                  'assets/images/settings.png',
                  width: 56,
                  height: 60,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Image.asset(
                  'assets/images/user.png',
                  width: 58,
                  height: 58,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String imagePath;
  final String label;
  final String value;
  final double imageWidth;
  final double imageHeight;
  final Widget? trailing;

  const _ProfileRow({
    required this.imagePath,
    required this.label,
    required this.value,
    this.imageWidth = 40,
    this.imageHeight = 40,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: imageWidth, height: imageHeight),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 20,
                fontFamily: 'LeagueSpartan',
                color: Colors.black87,
              ),
            ),
          ),
          if (value.isNotEmpty)
            Expanded(
              flex: 4,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF3B8EDB),
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
