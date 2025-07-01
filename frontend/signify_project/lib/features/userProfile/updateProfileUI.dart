import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signify_project/services/userProfile.dart';
import 'package:signify_project/services/updateProfile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController fullnameController;
  late TextEditingController emailController;
  late TextEditingController dateController;
  File? imageFile;
  String? role;
  bool isLoading = false;
  String? error;
  bool removePhoto = false;

  @override
  void initState() {
    super.initState();
    fullnameController = TextEditingController();
    emailController = TextEditingController();
    dateController = TextEditingController();
  }

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        removePhoto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(fontFamily: 'LeagueSpartan'),
              ),
            ),
        data: (user) {
          fullnameController.text = user.fullname;
          emailController.text = user.email;
          dateController.text = user.dateOfBirth;
          role ??= user.role;

          final String baseUrl = 'http://192.168.1.3:5000';
          final String? profileImageUrl =
              (user.profileImage.isNotEmpty)
                  ? (user.profileImage.startsWith('http')
                      ? user.profileImage
                      : user.profileImage.startsWith('/')
                      ? '$baseUrl${user.profileImage}'
                      : '$baseUrl/${user.profileImage}')
                  : null;

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFE3F1FB),
                padding: const EdgeInsets.only(top: 40, bottom: 16),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          'assets/images/back.png',
                          height: 36,
                          width: 36,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, top: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/changePassword');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3F1FB),
                            foregroundColor: Colors.black,
                            elevation: 9,
                            shadowColor: Colors.black.withOpacity(0.18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Change Password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LeagueSpartan',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage:
                                  imageFile != null
                                      ? FileImage(imageFile!)
                                      : (profileImageUrl != null && !removePhoto
                                          ? NetworkImage(profileImageUrl)
                                          : null),
                              child:
                                  ((user.profileImage.isEmpty &&
                                              imageFile == null) ||
                                          removePhoto)
                                      ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.blue,
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if ((imageFile != null ||
                                (user.profileImage.isNotEmpty && !removePhoto)))
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      imageFile = null;
                                      removePhoto = true;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Full name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LeagueSpartan',
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StyledTextField(
                          controller: fullnameController,
                          hintText: 'Full name',
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Enter full name'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Username',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LeagueSpartan',
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StyledTextField(
                          initialValue: user.username,
                          enabled: false,
                          hintText: 'Username',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LeagueSpartan',
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StyledTextField(
                          controller: emailController,
                          hintText: 'Email',
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LeagueSpartan',
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StyledTextField(
                          controller: dateController,
                          hintText: 'YYYY-MM-DD',
                          readOnly: true,
                          enabled: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/images/DOB.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.tryParse(user.dateOfBirth) ??
                                  DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              dateController.text =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'User Role',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LeagueSpartan',
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _RoleOption(
                              value: 'normal user',
                              groupValue: role,
                              image: Image.asset(
                                'assets/images/radioUser.png',
                                height: 90,
                                width: 90,
                              ),
                              onChanged: (val) => setState(() => role = val),
                            ),
                            _RoleOption(
                              value: 'hearing-impaired',
                              groupValue: role,
                              image: Image.asset(
                                'assets/images/radioUnhear.png',
                                height: 90,
                                width: 90,
                              ),
                              onChanged: (val) => setState(() => role = val),
                            ),
                            _RoleOption(
                              value: 'speech-impaired',
                              groupValue: role,
                              image: Image.asset(
                                'assets/images/radioNospeech.png',
                                height: 90,
                                width: 90,
                              ),
                              onChanged: (val) => setState(() => role = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (error != null)
                          Center(
                            child: Text(
                              error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: 'LeagueSpartan',
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (!_formKey.currentState!.validate())
                                        return;
                                      setState(() {
                                        isLoading = true;
                                        error = null;
                                      });
                                      final data = {
                                        'fullname': fullnameController.text,
                                        'email': emailController.text,
                                        'role': role,
                                        'dateofbirth': dateController.text,
                                        if (imageFile != null)
                                          'profile_image': imageFile!,
                                        if (removePhoto) 'profile_image': '',
                                      };
                                      try {
                                        await ref.read(
                                          updateProfileProvider(data).future,
                                        );
                                        ref.invalidate(userProfileProvider);
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Profile updated successfully',
                                              ),
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        setState(() {
                                          error = e.toString();
                                        });
                                      } finally {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005FCE),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Update Profile',
                                      style: TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'LeagueSpartan',
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
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

class _StyledTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;

  const _StyledTextField({
    this.controller,
    this.initialValue,
    required this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.validator,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFBEE3FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
        ),
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 16,
        ),
        suffixIcon:
            enabled
                ? IconButton(
                  icon: Image.asset(
                    'assets/images/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed:
                      controller != null ? () => controller!.clear() : null,
                )
                : null,
        hintStyle: const TextStyle(
          fontFamily: 'LeagueSpartan',
          color: Colors.black87,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'LeagueSpartan',
          color: Colors.black87,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 18,
        color: Colors.black,
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String value;
  final String? groupValue;
  final Image image;
  final ValueChanged<String> onChanged;

  const _RoleOption({
    required this.value,
    required this.groupValue,
    required this.image,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 90, width: 90, child: image),
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          activeColor: Color(0xFF005FCE),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
