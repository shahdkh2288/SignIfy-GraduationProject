import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _selectedRole = 1;
  bool _isLoading = false;

  final emailRegex = RegExp(
    r'^[\w\.-]+@(?:gmail\.com|yahoo\.com|outlook\.com|hotmail\.com|icloud\.com)$',
  );
  final passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Image.asset('assets/logo2.png', height: 130),
              ),
              SizedBox(height: 8),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Image.asset(
                    'assets/back.png',
                    height: 50,
                    width: 50,
                  )),
              SizedBox(height: 20),
              Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 20),
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _fullNameController,
                        hint: "Full Name",
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/userIcon.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Full name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      _buildTextField(
                        controller: _usernameController,
                        hint: "Username",
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/userIcon.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username is required';
                          }
                          if (value.contains(' ')) {
                            return 'Username cannot contain spaces';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      _buildTextField(
                        controller: _emailController,
                        hint: "Email",
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/email.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!emailRegex.hasMatch(value)) {
                            return 'Enter a valid Gmail, Yahoo, Outlook, Hotmail, or iCloud email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      _buildPasswordField(
                        controller: _passwordController,
                        hint: "Password",
                        obscure: _obscurePassword,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/passIcon.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        toggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (!passwordRegex.hasMatch(value)) {
                            return 'Password must be at least 8 characters,\ninclude upper, lower, number & special char';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hint: "Confirm Password",
                        obscure: _obscureConfirmPassword,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/passIcon.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        toggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      _buildDOBField(),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose your role',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LeagueSpartan',
                              fontSize: 24,
                              color:  Color(0xFF005FCE)),
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRoleOption(
                            0,
                            Image.asset('assets/radioUser.png'),
                            "",
                          ),
                          _buildRoleOption(
                            1,
                            Image.asset('assets/radioUnhear.png'),
                            "",
                          ),
                          _buildRoleOption(
                            2,
                            Image.asset('assets/radioNospeech.png'),
                            "",
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF005FCE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    
                                    await Future.delayed(Duration(seconds: 2));
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sign up successful!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    
                                    await Future.delayed(Duration(milliseconds: 500));
                                    Navigator.pushReplacementNamed(context, '/home');
                                  }
                                },
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontFamily: 'LeagueSpartan',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color.fromARGB(255, 218, 217, 217),
            fontFamily: 'LeagueSpartan',
          ),
          prefixIcon: prefixIcon,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleVisibility,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color.fromARGB(255, 218, 217, 217),
            fontFamily: 'LeagueSpartan',
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDOBField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            _dobController.text =
                "${pickedDate.toLocal()}".split(' ')[0];
          }
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Select your birth date' : null,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              'assets/DOB.png',
              height: 20,
              width: 20,
              fit: BoxFit.contain,
            ),
          ),
          hintText: "Date of Birth",
          hintStyle: TextStyle(
            color: const Color.fromARGB(255, 218, 217, 217),
            fontFamily: 'LeagueSpartan',
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(int index, Image image, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = index;
        });
      },
      child: Column(
        children: [
          SizedBox(
            height: 90, 
            width: 90,
            child: image,
          ),
          Radio<int>(
            value: index,
            groupValue: _selectedRole,
            onChanged: (int? value) {
              setState(() {
                _selectedRole = value!;
              });
            },
            activeColor: Color(0xFF005FCE),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}


