import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: PaymentPage());
  }
}

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

  String _generateCode() {
    final rnd = Random();
    return List.generate(6, (_) => rnd.nextInt(10).toString()).join();
  }

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
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              backgroundColor: Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Payment Successful',
                style: TextStyle(color: Colors.white),
              ),
              content: Icon(
                Icons.check_circle,
                color: Color(0xFFFACF5A),
                size: 60,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(color: Color(0xFFFACF5A)),
                  ),
                ),
              ],
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFACF5A), Color(0xFFFFE580)],
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
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '6037 9981 4878 4555',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CARD HOLDER',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'VALID THRU',
                                style: TextStyle(
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
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '12 / 25',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _cardController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  validator:
                      (v) =>
                          v != null && v.length == 16
                              ? null
                              : 'Enter 16-digit card number',
                  decoration: _inputDecoration('Card Number'),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthController,
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator:
                            (v) =>
                                v != null &&
                                        int.tryParse(v)! >= 1 &&
                                        int.tryParse(v)! <= 12
                                    ? null
                                    : 'MM',
                        decoration: _inputDecoration('Month'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        validator:
                            (v) => v != null && v.length == 2 ? null : 'YY',
                        decoration: _inputDecoration('Year'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _cvvController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator:
                      (v) => v != null && v.length == 4 ? null : 'Enter CVV2',
                  decoration: _inputDecoration('CVV2'),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: Colors.white),
                  obscureText: _obscurePassword,
                  validator:
                      (v) =>
                          v != null && v.isNotEmpty ? null : 'Enter password',
                  decoration: _inputDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _regenerateCode,
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _inputCodeController,
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator:
                            (v) =>
                                v != null && v == _generatedCode
                                    ? null
                                    : 'Incorrect code',
                        decoration: _inputDecoration('Security Code'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFACF5A),
                      foregroundColor: Color(0xFF1C1C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _onPayPressed,
                    child:
                        _loading
                            ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF1C1C1C),
                              ),
                            )
                            : Text(
                              'Pay',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Color(0xFF333333),
      labelStyle: TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
