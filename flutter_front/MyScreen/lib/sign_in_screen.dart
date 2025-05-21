import 'package:flutter/material.dart';
import 'sign_up_screen.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'special_page.dart';
import 'theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.darkTheme;

    final colorScheme = AppTheme.darkTheme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Icon.png', width: 220, height: 220),
              _buildTextField(
                context: context,
                hintText: 'Username',
                obscureText: false,
                prefixIconData: Icons.person,
              ),
              _buildTextField(
                context: context,
                hintText: 'Password',
                obscureText: !_isPasswordVisible,
                prefixIconData: Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(right: 20.0),
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 60,
                margin: EdgeInsets.all(10),
                child: AnimatedButton(
                  height: 60,
                  width: double.infinity,
                  text: 'Sign In',
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
                  onPress: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SpecialPage()),
                    );
                  },
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
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
    required BuildContext context,
    required String hintText,
    required bool obscureText,
    IconData? prefixIconData,
    Widget? suffixIcon,
  }) {
    final theme = AppTheme.darkTheme;
    final colorScheme = AppTheme.darkTheme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: theme.colorScheme.surface,
      ),
      margin: EdgeInsets.all(10.0),
      child: TextField(
        obscureText: obscureText,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color(0xFF2C2C2C), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color(0xFF2C2C2C), width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Color(0xFF2C2C2C), width: 2.0),
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          contentPadding: EdgeInsets.all(25.0),
          prefixIcon:
              prefixIconData == null
                  ? null
                  : Icon(prefixIconData, color: colorScheme.primary),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
