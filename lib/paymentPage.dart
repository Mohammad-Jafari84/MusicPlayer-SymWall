// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'dart:math';

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
      themeMode:
      Theme.of(context).brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: PaymentPage(),
    );
  }
}

// payment_page.dart

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
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

  @override
  void initState() {
    super.initState();
    _generatedCode = _generateCode();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvvController.dispose();
    _passwordController.dispose();
    _inputCodeController.dispose();
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
    Future.delayed(Duration(seconds: 2), () {
      setState(() => _loading = false);
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
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
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Card Preview (uses theme colors)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BANK',
                            style: theme.textTheme.titleLarge!.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '6037 9981 4878 4555',
                            style: theme.textTheme.titleLarge!.copyWith(
                              fontSize: 24,
                              letterSpacing: 3,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CARD HOLDER',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'VALID THRU',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mohammad Jafari',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '12 / 25',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Amount: \$100.00',
                    style: theme.textTheme.titleLarge!,
                  ),
                ),
                SizedBox(height: 16),
                CustomTextField(
                  label: 'Card Number',
                  controller: _cardController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  validator:
                      (v) =>
                  v != null && v.length == 16
                      ? null
                      : 'Enter 16-digit card number',
                ),
                SizedBox(height: 16),
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
                    SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Year',
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator:
                            (v) => v != null && v.length == 2 ? null : 'YY',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                CustomTextField(
                  label: 'CVV2',
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator:
                      (v) => v != null && v.length == 4 ? null : 'Enter CVV2',
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: theme.textTheme.bodyMedium,
                  obscureText: _obscurePassword,
                  validator:
                      (v) =>
                  v != null && v.isNotEmpty ? null : 'Enter password',
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
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      color: colorScheme.onSurface,
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
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
                        validator:
                            (v) =>
                        v != null && v == _generatedCode
                            ? null
                            : 'Incorrect code',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onPayPressed,
                    child:
                    _loading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        colorScheme.onPrimary,
                      ),
                    )
                        : Text(
                      'Pay',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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