import 'dart:async';
import 'package:SymWall/service/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'special_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'sign_in_screen.dart';
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
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '52473857706-4psvtglftf1pucv4u4knburjt7fmnjfn.apps.googleusercontent.com',
  );

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  bool validatePassword(String password, String username) {
    List<String> errors = [];
    
    if (password.length < 8) {
      errors.add('At least 8 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('One uppercase letter');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('One lowercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('One number');
    }
    if (password.toLowerCase().contains(username.toLowerCase())) {
      errors.add('Cannot contain username');
    }

    if (errors.isEmpty) return true;
    
    // فقط خطاهایی که هنوز رفع نشده‌اند را نمایش بده
    setState(() {
      _passwordError = 'Password needs: ${errors.join(", ")}';
    });
    return false;
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _showSnack('Google Sign-Up cancelled by user.');
        print('GoogleSignIn: User cancelled sign-up.');
      } else {
        setState(() {
          _emailController.text = account.email;
          _usernameController.text = account.displayName ?? '';
        });
        _showSnack('Google account selected. Please enter password to complete sign up.');
      }
    } catch (error) {
      String errorMsg = error.toString();
      if (errorMsg.contains('ApiException: 10')) {
        errorMsg =
            'Google Sign-Up failed: Error 10.\n'
            'Check SHA1 fingerprint, google-services.json, and package name in Google Console.\n'
            'App must be registered in Google Cloud Console and SHA1 must match your debug/release keystore.';
      }
      _showSnack(errorMsg);
      print('GoogleSignIn Error: $error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSignUpPressed() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (username.isEmpty) {
      setState(() => _usernameError = 'Username is required');
      hasError = true;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!validateEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (!validatePassword(password, username)) {
      hasError = true;
      // خطا قبلاً در متد validatePassword ست شده
    }
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirm your password');
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final connected = await SocketService.initSocket();
      if (!connected) {
        setState(() => _emailError = 'Could not connect to server.');
        return;
      }

      final errorMsg = await SocketService.sendSignupRequest(username, email, password);

      if (errorMsg == null) {
        // ذخیره اطلاعات کاربر
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString('user_name', username);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SpecialPage()),
        );
      } else if (errorMsg.toLowerCase().contains('email') && errorMsg.toLowerCase().contains('exists')) {
        // اگر ایمیل قبلاً ثبت شده باشد، پیام و دکمه ورود نمایش بده
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Email already registered'),
            content: Text('This email is already registered. Would you like to sign in?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                  );
                },
                child: Text('Sign In'),
              ),
            ],
          ),
        );
        setState(() => _emailError = errorMsg);
      } else {
        setState(() => _emailError = errorMsg);
      }
    } catch (e) {
      setState(() => _emailError = 'Connection error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 2),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.darkTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Icon.png', width: 150, height: 150),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    obscureText: false,
                    prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                    errorText: _usernameError,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    obscureText: false,
                    prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                    errorText: _emailError,
                  ),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                    suffixIcon: _buildVisibilityIcon(
                      isObscured: _obscurePassword,
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    errorText: _passwordError,
                  ),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                    suffixIcon: _buildVisibilityIcon(
                      isObscured: _obscureConfirmPassword,
                      onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    errorText: _confirmPasswordError,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: AnimatedButton(
                      height: 60,
                      width: double.infinity,
                      text: _isLoading ? 'Please wait...' : 'Sign Up',
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
                      onPress: _isLoading ? null : _onSignUpPressed,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
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
                      Text('Already have an account?', style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignInScreen()),
                          );
                        },
                        child: Text('Sign In', style: theme.textTheme.bodyMedium!.copyWith(color: colorScheme.primary)),
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
}