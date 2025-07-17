import 'package:flutter/material.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:SymWall/service/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_up_screen.dart';
import 'special_page.dart';
import 'theme.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '52473857706-4psvtglftf1pucv4u4knburjt7fmnjfn.apps.googleusercontent.com',
  );

  // Email validation using regex
  bool validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  // Google Sign-In logic
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _showSnack('Google Sign-In cancelled by user.');
        print('GoogleSignIn: User cancelled sign-in.');
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', account.email);
        await prefs.setString('user_name', account.displayName ?? '');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SpecialPage()),
        );
      }
    } catch (error) {
      String errorMsg = error.toString();
      if (errorMsg.contains('ApiException: 10')) {
        errorMsg =
            'Google Sign-In failed: Error 10.\n'
            'Check SHA1 fingerprint, google-services.json, and package name in Google Console.\n'
            'App must be registered in Google Cloud Console and SHA1 must match your debug/release keystore.';
      }
      _showSnack(errorMsg);
      print('GoogleSignIn Error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoggedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SpecialPage()),
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSignInPressed() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (!validateEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final socketReady = await SocketService.initSocket();
      if (!socketReady) {
        _showSnack('Could not connect to server.');
        return;
      }

      final errorMsg = await SocketService.sendLoginRequest(email, password);
      if (errorMsg == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SpecialPage()),
        );
      } else if (errorMsg == 'Email not found.') {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('Account not found'),
                content: Text(
                  'No account found for this email. Would you like to sign up?',
                ),
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
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: Text('Sign Up'),
                  ),
                ],
              ),
        );
      } else {
        _showSnack(errorMsg);
      }
    } catch (e) {
      _showSnack('Connection error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.darkTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Icon.png', width: 220, height: 220),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email',
                obscureText: false,
                prefixIcon: Icons.alternate_email,
                errorText: _emailError,
              ),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: !_isPasswordVisible,
                prefixIcon: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: colorScheme.primary,
                  ),
                  onPressed:
                      () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: AnimatedButton(
                  height: 60,
                  width: double.infinity,
                  text: _isLoading ? 'Please wait...' : 'Sign In',
                  isReverse: true,
                  selectedTextColor: colorScheme.primary,
                  textStyle: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  transitionType: TransitionType.LEFT_TO_RIGHT,
                  backgroundColor: colorScheme.primary,
                  selectedBackgroundColor: colorScheme.onPrimary,
                  borderRadius: 40,
                  borderWidth: 2,
                  onPress: _isLoading ? null : _onSignInPressed,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    final theme = AppTheme.darkTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            color: theme.colorScheme.surface,
          ),
          margin: const EdgeInsets.all(10.0),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(
                  color: Color(0xFF2C2C2C),
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(
                  color: Color(0xFF2C2C2C),
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(
                  color: Color(0xFF2C2C2C),
                  width: 2.0,
                ),
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              contentPadding: const EdgeInsets.all(25.0),
              prefixIcon:
                  prefixIcon != null
                      ? Icon(prefixIcon, color: colorScheme.primary)
                      : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 2),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
