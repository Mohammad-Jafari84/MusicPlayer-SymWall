import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'dart:math';

class PaymentPage extends StatefulWidget {
  final double amount;
  const PaymentPage({Key? key, required this.amount}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  late String _generatedCode;
  final _cardController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inputCodeController = TextEditingController();

  late AnimationController _payAnimController;
  late Animation<double> _payFillAnimation;
  int _currentCardIndex = 0;
  late PageController _pageController;

  final List<Map<String, String>> _cards = [
    {
      'cardNumber': '6037 9981 4878 4555',
      'holder': 'Mohammad Jafari',
      'validThru': '12 / 25',
      'bank': 'SYMWALL',
    },
    {
      'cardNumber': '6221 0612 4625 0072',
      'holder': 'Parham RamazanZadeh',
      'validThru': '09 / 27',
      'bank': 'Bank Melli',
    },
  ];

  @override
  void initState() {
    super.initState();
    _generatedCode = _generateCode();
    _payAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _payFillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _payAnimController, curve: Curves.easeInOut),
    );
    _pageController = PageController(initialPage: _currentCardIndex, viewportFraction: 0.88);

    // شماره کارت را با فرمت درست نمایش بده
    _cardController.addListener(() {
      final text = _cardController.text.replaceAll(' ', '');
      final newText = text.replaceAllMapped(RegExp(r".{1,4}"), (match) => "${match.group(0)} ");
      if (_cardController.text != newText.trim()) {
        final pos = _cardController.selection.baseOffset;
        _cardController.value = TextEditingValue(
          text: newText.trim(),
          selection: TextSelection.collapsed(offset: min(newText.trim().length, pos + (newText.length - text.length))),
        );
      }
    });
  }

  @override
  void dispose() {
    _payAnimController.dispose();
    _cardController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvvController.dispose();
    _passwordController.dispose();
    _inputCodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _generateCode() =>
      List.generate(6, (_) => Random().nextInt(10).toString()).join();

  void _regenerateCode() {
    setState(() {
      _generatedCode = _generateCode();
      _inputCodeController.clear();
    });
  }

  void _onPayPressed() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    _payAnimController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1400), () {
      setState(() => _loading = false);
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Payment Successful',
          style: TextStyle(color: colorScheme.onBackground),
        ),
        content: Icon(
          Icons.check_circle,
          color: colorScheme.primary,
          size: 60,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous page
            },
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _nextCard() {
    setState(() {
      _currentCardIndex = (_currentCardIndex + 1) % _cards.length;
      _pageController.animateToPage(
        _currentCardIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _build3DCard({
    required Color color1,
    required Color color2,
    required double angle,
    required double elevation,
    required String cardNumber,
    required String holder,
    required String validThru,
    required String bank,
    bool isMain = false,
  }) {
    final theme = Theme.of(context);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateZ(angle),
      child: Container(
        height: 200,
        margin: EdgeInsets.only(bottom: isMain ? 0 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.25),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
            if (isMain)
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
          ],
        ),
        padding: EdgeInsets.all(24),
        child: Stack(
          children: [
            // Shine effect
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 80,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            // Card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank,
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  cardNumber,
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontSize: 24,
                    letterSpacing: 3,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'VALID THRU',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      holder,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      validThru,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Chip
            Positioned(
              top: 38,
              right: 24,
              child: Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.yellow.shade700, Colors.orange.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Circles
            Positioned(
              bottom: 24,
              right: 24,
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCardSlider() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final List<List<Color>> gradients = [
      [colorScheme.primary, colorScheme.secondary],
      [colorScheme.secondary.withOpacity(0.8), colorScheme.primary.withOpacity(0.7)],
    ];
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _cards.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final card = _cards[index];
              final isMain = index == _currentCardIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: isMain ? 0 : 12, vertical: isMain ? 0 : 16),
                child: Transform.scale(
                  scale: isMain ? 1.0 : 0.93,
                  child: _build3DCard(
                    color1: gradients[index][0],
                    color2: gradients[index][1],
                    angle: isMain ? 0.05 : -0.08,
                    elevation: isMain ? 28 : 12,
                    cardNumber: card['cardNumber']!,
                    holder: card['holder']!,
                    validThru: card['validThru']!,
                    bank: card['bank']!,
                    isMain: isMain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.primary, size: 32),
                onPressed: _nextCard,
                splashRadius: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPayButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _payFillAnimation,
      builder: (context, child) {
        // تغییر رنگ متن Pay به طلایی هنگام پر شدن آب
        final textColor = _payFillAnimation.value > 0.35
            ? Colors.amber.shade400
            : colorScheme.onPrimary;
        return Stack(
          alignment: Alignment.center,
          children: [
            // دکمه با افکت پر شدن آب مشکی
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.18),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _ButtonLiquidFillPainter(_payFillAnimation.value),
                  child: Container(),
                ),
              ),
            ),
            _loading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                  )
                : Positioned(
                    left: 0,
                    right: 0,
                    child: Text(
                      'Pay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAnimatedCardSlider(),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Amount: \$${widget.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge!,
                  ),
                ),
                const SizedBox(height: 16),
                // شماره کارت با فرمت 4 رقم 4 رقم
                CustomTextField(
                  label: 'Card Number',
                  controller: _cardController,
                  keyboardType: TextInputType.number,
                  maxLength: 19, // 16 رقم + 3 فاصله
                  validator: (v) {
                    final numbers = v?.replaceAll(' ', '') ?? '';
                    return numbers.length == 16 ? null : 'Enter 16-digit card number';
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Month',
                        controller: _monthController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator: (v) {
                          final p = int.tryParse(v ?? '');
                          return p != null && p >= 1 && p <= 12 ? null : 'MM';
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Year',
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator: (v) => v != null && v.length == 2 ? null : 'YY',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'CVV2',
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (v) => v != null && v.length == 4 ? null : 'Enter CVV2',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: theme.textTheme.bodyMedium,
                  obscureText: _obscurePassword,
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Enter password',
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: colorScheme.surface,
                    labelStyle: TextStyle(color: colorScheme.onSurface),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      color: colorScheme.onSurface,
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedCode,
                        style: theme.textTheme.titleLarge!.copyWith(
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                      onPressed: _regenerateCode,
                    ),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'Security Code',
                        controller: _inputCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (v) =>
                            v != null && v == _generatedCode ? null : 'Incorrect code',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loading ? null : _onPayPressed,
                  child: _buildAnimatedPayButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidFillPainter extends CustomPainter {
  final double fillPercent; // 0.0 to 1.0
  final Color color;
  _LiquidFillPainter(this.fillPercent, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.7);
    final double fillHeight = size.height * fillPercent;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - fillHeight)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height - fillHeight - 8 * (1 - fillPercent),
        size.width * 0.5,
        size.height - fillHeight + 8 * fillPercent,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height - fillHeight - 8 * (1 - fillPercent),
        size.width,
        size.height - fillHeight,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidFillPainter oldDelegate) =>
      oldDelegate.fillPercent != fillPercent || oldDelegate.color != color;
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLength;
  final String? Function(String?)? validator;

  const CustomTextField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colorScheme.surface,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// افکت پر شدن آب مشکی برای کل دکمه
class _ButtonLiquidFillPainter extends CustomPainter {
  final double fillPercent; // 0.0 to 1.0
  _ButtonLiquidFillPainter(this.fillPercent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.95);
    final double fillHeight = size.height * fillPercent;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - fillHeight)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height - fillHeight - 8 * (1 - fillPercent),
        size.width * 0.5,
        size.height - fillHeight + 8 * fillPercent,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height - fillHeight - 8 * (1 - fillPercent),
        size.width,
        size.height - fillHeight,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ButtonLiquidFillPainter oldDelegate) =>
      oldDelegate.fillPercent != fillPercent;
}


