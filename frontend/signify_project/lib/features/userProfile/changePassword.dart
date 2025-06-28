import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signify_project/services/change_pass.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();
  bool oldObscure = true;
  bool newObscure = true;
  bool confirmObscure = true;

  @override
  void dispose() {
    oldPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final changePasswordState = ref.watch(changePasswordProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 8, right: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset('assets/images/back.png', height: 36, width: 36),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Image.asset(
                'assets/images/change-pass.png', 
                height: 240, 
                width: 240,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _PasswordField(
                        controller: oldPassController,
                        obscureText: oldObscure,
                        onToggle: () => setState(() => oldObscure = !oldObscure),
                        hintText: 'Current Password',
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'New Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _PasswordField(
                        controller: newPassController,
                        obscureText: newObscure,
                        onToggle: () => setState(() => newObscure = !newObscure),
                        hintText: 'New Password',
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Confirm New Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _PasswordField(
                        controller: confirmPassController,
                        obscureText: confirmObscure,
                        onToggle: () => setState(() => confirmObscure = !confirmObscure),
                        hintText: 'Confirm New Password',
                      ),
                      const SizedBox(height: 32),
                      changePasswordState.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            e.toString(),
                            style: const TextStyle(color: Colors.red, fontFamily: 'LeagueSpartan'),
                          ),
                        ),
                        data: (msg) => msg.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  msg,
                                  style: const TextStyle(color: Colors.green, fontFamily: 'LeagueSpartan'),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: changePasswordState.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (newPassController.text != confirmPassController.text) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('New passwords do not match')),
                                      );
                                      return;
                                    }
                                    await ref.read(changePasswordProvider.notifier).changePassword(
                                          oldPassword: oldPassController.text,
                                          newPassword: newPassController.text,
                                        );
                                    
                                    final state = ref.read(changePasswordProvider);
                                    if (state is AsyncData && state.value != null && state.value!.contains('success')) {
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Password changed successfully!')),
                                      );
                                      Navigator.pushReplacementNamed(context, '/edit_profile');
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005FCE),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          child: changePasswordState.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Change Password',
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
        ),
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final String hintText;

  const _PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromRGBO(114, 196, 244, 0.28), 
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
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        hintText: hintText,
        hintStyle: const TextStyle(fontFamily: 'LeagueSpartan', color: Colors.black87),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.black,
          ),
          onPressed: onToggle,
        ),
      ),
      style: const TextStyle(fontFamily: 'LeagueSpartan', fontSize: 18, color: Colors.black),
    );
  }
}