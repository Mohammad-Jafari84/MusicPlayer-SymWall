import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'special_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'theme_provider.dart';
import 'theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _deletePressed = false; // example if needed

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool validatePassword(String password, String username) {
    if (password.length < 8) return false;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));

    bool containsUsername = password.toLowerCase().contains(
      username.toLowerCase(),
    );
    if (!hasUppercase || !hasLowercase || !hasNumber || containsUsername)
      return false;
    return true;
  }

  void _handleGoogleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SpecialPage()),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In failed',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.darkTheme;
    final colorScheme = AppTheme.darkTheme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Icon.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    obscureText: false,
                    prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                  ),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    obscureText: false,
                    prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                  ),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                    suffixIcon: _buildVisibilityIcon(
                      isObscured: _obscurePassword,
                      onTap:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                    suffixIcon: _buildVisibilityIcon(
                      isObscured: _obscureConfirmPassword,
                      onTap:
                          () => setState(
                            () =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: AnimatedButton(
                      height: 60,
                      width: double.infinity,
                      text: 'Sign Up',
                      isReverse: true,
                      textStyle: theme.textTheme.bodyMedium!.copyWith(
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      transitionType: TransitionType.LEFT_TO_RIGHT,
                      backgroundColor: colorScheme.primary,
                      selectedBackgroundColor: colorScheme.onPrimary,
                      selectedTextColor: colorScheme.primary,
                      borderRadius: 40,
                      borderWidth: 2,
                      onPress: () {
                        final username = _usernameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirmPassword = _confirmPasswordController.text;
                        if (username.isEmpty ||
                            email.isEmpty ||
                            password.isEmpty ||
                            confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill all fields',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                          return;
                        }
                        // if (!validateUsername(username)) {
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     SnackBar(
                        //       content: Text(
                        //         'Username must be at least 3 characters and contain only letters and numbers.',
                        //         style: theme.textTheme.bodyMedium,
                        //       ),
                        //     ),
                        //   );
                        //   return;
                        // }
                        if (!validateEmail(email)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter a valid email address.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                          return;
                        }
                        if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Passwords do not match',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                          return;
                        }
                        if (!validatePassword(password, username)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password must be at least 8 characters long, include uppercase, lowercase, number, and not contain username.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SpecialPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Icon(Icons.login, color: colorScheme.onPrimary),
                      label: Text(
                        'Sign in with Google',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignInScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Simple email validation using RegExp
  bool validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: AppTheme.darkTheme.colorScheme.surface,
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70),
          contentPadding: EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 25.0,
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityIcon({
    required bool isObscured,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        isObscured ? Icons.visibility_off : Icons.visibility,
        color: Color(0xFFFACF5A),
      ),
      onPressed: onTap,
    );
  }
}
