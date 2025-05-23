import 'package:flutter/material.dart';
import 'home-page.dart';
import 'userProfile.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SpecialPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SpecialPage extends StatefulWidget {
  const SpecialPage({super.key});

  @override
  State<SpecialPage> createState() => _SpecialPageState();
}

class _SpecialPageState extends State<SpecialPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String fullText = 'a Wall of Symphony';
  String displayedText = '';
  int currentIndex = 0;

  bool typingDone = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(_fadeController);

    Future.delayed(const Duration(milliseconds: 1200), startTyping);
  }

  void startTyping() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 80));
      if (currentIndex < fullText.length) {
        setState(() {
          displayedText += fullText[currentIndex];
          currentIndex++;
        });
        return true;
      } else {
        typingDone = true;
        await _fadeController.forward(); // منتظر تموم شدن انیمیشن باش

        await Future.delayed(const Duration(seconds: 1)); // یک ثانیه صبر کن

        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
        }
        return false;
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'SymWall',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFFACF5A),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              displayedText,
              style: GoogleFonts.dancingScript(
                fontSize: 27,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: const Color(0xFFFACF5A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}