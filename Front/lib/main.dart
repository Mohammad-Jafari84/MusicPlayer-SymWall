import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'theme.dart';
import 'sign_up_screen.dart';
import 'home-page.dart';
import 'userProfile.dart';
import 'paymentPage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: SignUpScreen(),
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