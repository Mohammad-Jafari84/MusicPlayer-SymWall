import 'package:flutter/material.dart';
import 'sign_up_screen.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'special_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1C),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Icon.png', width: 220, height: 220),
            _buildTextField(
              hintText: 'Username',
              obscureText: false,
              prefixIconData: Icons.person,
            ),
            _buildTextField(
              hintText: 'Password',
              obscureText: !_isPasswordVisible,
              prefixIconData: Icons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Color(0xFFE8B923),
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
                  style: TextStyle(color: Color(0xFFB0AFAF)),
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
                selectedTextColor: Color(0xFFFACF5A),
                textStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                transitionType: TransitionType.LEFT_TO_RIGHT,
                backgroundColor: Color(0xFFFACF5A),
                selectedBackgroundColor: Colors.black,
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
                  style: TextStyle(color: Color(0xFFB0AFAF)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return SignUpScreen();
                        },
                      ),
                    );
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(color: Color(0xFFFACF5A)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required bool obscureText,
    IconData? prefixIconData,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        color: Colors.black,
      ),
      margin: EdgeInsets.all(10.0),
      child: TextField(
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
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
          hintStyle: TextStyle(color: Color(0xFFB0AFAF)),
          contentPadding: EdgeInsets.all(25.0),
          prefixIcon:
              prefixIconData == null
                  ? null
                  : Icon(prefixIconData, color: Color(0xFFE8B923)),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
