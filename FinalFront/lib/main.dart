import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'theme.dart';
import 'sign_up_screen.dart';
import 'sign_in_screen.dart';
import 'home-page.dart';
import 'userProfile.dart';
import 'paymentPage.dart';
import 'special_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('user_email');
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp(isLoggedIn: email != null && email.isNotEmpty)),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({required this.isLoggedIn, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: isLoggedIn ? SpecialPage() : SignUpScreen(),
      routes: {
        '/profile': (_) => ProfilePage(),
        '/payment': (_) => PaymentPage(amount: 100.0),
      },
      builder: (context, child) {

        final theme = themeProvider.theme;
        ThemeData selectedTheme;
        if (theme == 'light') {
          selectedTheme = AppTheme.lightTheme;
        } else if (theme == 'green') {
          selectedTheme = AppTheme.greenTheme;
        } else {
          selectedTheme = AppTheme.darkTheme;
        }
        return Theme(
          data: selectedTheme,
          child: child!,
        );
      },
    );
  }
}