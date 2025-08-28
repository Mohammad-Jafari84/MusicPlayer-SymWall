import 'dart:io';
import 'package:SymWall/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'theme.dart';
import 'paymentPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/socket_service.dart';
import 'sign_in_screen.dart';

class UserProfile extends StatefulWidget {
  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  @override
  Widget build(BuildContext context) {
    return ProfilePage();
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Username';
  String _email = 'user@example.com';
  String _subscription = 'Standard';
  String? _subscriptionExpiresAt;
  int _credit = 50000;
  bool _deletePressed = false;
  String? _deleteError;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;

  void payment() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PaymentPage(amount: 100.0)));
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Camera',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _addCredit() async {
    final cs = Theme.of(context).colorScheme;
    double? amount;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Add Credit'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (\$)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: cs.error)),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  amount = value;
                  Navigator.pop(context);
                }
              },
              child: Text('Continue', style: TextStyle(color: cs.primary)),
            ),
          ],
        );
      },
    );
    if (amount != null) {
      final result = await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PaymentPage(amount: amount!)));
      if (result == true) {
        setState(() {
          _credit += amount!.toInt();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Credit increased by \$${amount!.toInt()}')),
        );
      }
    }
  }

  // اضافه کردن متد برای کم کردن اعتبار بعد از خرید آهنگ
  void decreaseCredit(int amount) {
    setState(() {
      _credit -= amount;
      if (_credit < 0) _credit = 0;
    });
  }

  bool validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  bool get isPremium {
    return _subscription.startsWith('PREMIUM');
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final localSubscription = prefs.getString('subscription') ?? 'STANDARD';
    final localEmail = prefs.getString('user_email') ?? 'user@example.com';
    // Fetch latest subscription from server
    final serverStatus = await SocketService.fetchUserStatus(localEmail);
    String subscription = localSubscription;
    String? subscriptionExpiresAt;
    if (serverStatus != null && serverStatus['subscription'] != null) {
      subscription = serverStatus['subscription'];
      subscriptionExpiresAt = serverStatus['subscriptionExpiresAt'];
      await prefs.setString('subscription', subscription);
    }
    setState(() {
      _username = prefs.getString('user_name') ?? 'Username';
      _email = localEmail;
      _subscription = subscription;
      _subscriptionExpiresAt = subscriptionExpiresAt;
    });
  }

  Future<bool> _verifyPassword(String email, String password) async {
    final result = await SocketService.sendLoginRequest(email, password);
    return result == null;
  }

  Future<String?> _deleteAccount(String email, String password) async {
    return await SocketService.sendDeleteAccountRequest(email, password);
  }

  Future<void> _upgradeToPremium(String type, double price) async {
    final cs = Theme.of(context).colorScheme;
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PaymentPage(amount: price)));
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription', type);
      // Update server status
      final serverResult = await SocketService.updatePremiumStatus(
        _email,
        type,
      );
      if (serverResult == null) {
        await _loadUserInfo(); // <-- Ensure user info is reloaded after upgrade
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(
                  'Premium Activated',
                  style: TextStyle(color: cs.primary),
                ),
                content: Text('Your account is now Premium!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('OK', style: TextStyle(color: cs.primary)),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update premium status: $serverResult'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SignInScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _switchAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SignInScreen()),
        (route) => false,
      );
      // Reload user info after switching account
      await _loadUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final cs = Theme.of(context).colorScheme;

    IconData themeIcon;
    if (themeProv.isDarkMode) {
      themeIcon = Icons.light_mode;
    } else if (themeProv.isLightMode) {
      themeIcon = Icons.dark_mode;
    } else {
      themeIcon = Icons.eco;
    }

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.background.withOpacity(0.97),
        elevation: 0,
        title: Text(
          'User Profile',
          style: GoogleFonts.poppins(
            color: cs.onBackground,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              themeProv.isDarkMode
                  ? Icons.dark_mode
                  : themeProv.isLightMode
                  ? Icons.light_mode
                  : themeProv.isGreenMode
                  ? Icons.eco
                  : Icons.brightness_auto,
              color: cs.primary,
            ),
            tooltip: 'Change Theme',
            onSelected: (value) {
              final prov = Provider.of<ThemeProvider>(context, listen: false);
              if (value == 'light') prov.setLightMode();
              if (value == 'dark') prov.setDarkMode();
              if (value == 'green') prov.setTheme('green');
              if (value == 'system') prov.setSystemMode();
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'light',
                    child: Row(
                      children: [
                        Icon(Icons.light_mode, color: cs.primary),
                        SizedBox(width: 8),
                        Text('Light'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'dark',
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode, color: cs.primary),
                        SizedBox(width: 8),
                        Text('Dark'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'green',
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: cs.primary),
                        SizedBox(width: 8),
                        Text('Green'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'system',
                    child: Row(
                      children: [
                        Icon(Icons.brightness_auto, color: cs.primary),
                        SizedBox(width: 8),
                        Text('System'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with 3D effect
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.15),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.12),
                          cs.secondary.withOpacity(0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: cs.surface,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _imageFile != null
                                ? FileImage(File(_imageFile!.path))
                                : null,
                        child:
                            _imageFile == null
                                ? Icon(
                                  Icons.person,
                                  size: 48,
                                  color: cs.primary,
                                )
                                : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Material(
                      color: cs.primary,
                      shape: CircleBorder(),
                      child: InkWell(
                        customBorder: CircleBorder(),
                        onTap: _showImagePickerOptions,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera_alt,
                            color: cs.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22),
            // User Info Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18),
              margin: EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.06),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _username,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Credit Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: cs.surfaceVariant,
              child: ListTile(
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: cs.primary,
                  size: 28,
                ),
                title: Text('Credit', style: TextStyle(color: cs.onSurface)),
                trailing: Text(
                  '$_credit \$',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: Size(double.infinity, 44),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text('Add Credit'),
              onPressed: _addCredit,
            ),
            SizedBox(height: 24),
            // Edit Info
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: cs.surface.withOpacity(0.92),
                boxShadow: [
                  BoxShadow(
                    color: cs.secondary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                title: Text('Edit Info', style: TextStyle(color: cs.primary)),
                leading: Icon(Icons.edit, color: cs.primary),
                children: [
                  TextField(
                    controller: _nameController..text = _username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: cs.onSurface),
                    ),
                    style: TextStyle(color: cs.onSurface),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _emailController..text = _email,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: cs.onSurface),
                        ),
                        style: TextStyle(color: cs.onSurface),
                        onChanged: (value) {
                          setState(() {
                            _emailError =
                                validateEmail(value)
                                    ? null
                                    : 'Please enter a valid email address.';
                          });
                        },
                      ),
                      if (_emailError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 18, top: 2),
                          child: Text(
                            _emailError!,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: cs.onSurface),
                    ),
                    style: TextStyle(color: cs.onSurface),
                    obscureText: true,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: Text('Save Changes'),
                    onPressed: () {
                      setState(() {
                        _username = _nameController.text;
                        _email = _emailController.text;
                        _emailError =
                            validateEmail(_email)
                                ? null
                                : 'Please enter a valid email address.';
                      });
                      if (_emailError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_emailError!),
                            backgroundColor: cs.error,
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Changes saved')));
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 22),
            // Delete Account
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _deletePressed = true;
                  _deleteError = null;
                });
                String password = '';
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => StatefulBuilder(
                        builder:
                            (context, setStateDialog) => AlertDialog(
                              title: Text('Delete Account'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Enter your password to confirm deletion:',
                                  ),
                                  TextField(
                                    obscureText: true,
                                    onChanged: (val) => password = val,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      errorText: _deleteError,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (password.isEmpty) {
                                      setStateDialog(() {
                                        _deleteError = 'Password required';
                                      });
                                      return;
                                    }
                                    setStateDialog(() {
                                      _deleteError = null;
                                    });
                                    // اعتبارسنجی رمز
                                    final valid = await _verifyPassword(
                                      _email,
                                      password,
                                    );
                                    if (!valid) {
                                      setStateDialog(() {
                                        _deleteError = 'Incorrect password';
                                      });
                                      return;
                                    }
                                    final deleteResult = await _deleteAccount(
                                      _email,
                                      password,
                                    );
                                    if (deleteResult != null) {
                                      setStateDialog(() {
                                        _deleteError = deleteResult;
                                      });
                                      return;
                                    }
                                    Navigator.pop(context, true);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: cs.error),
                                  ),
                                ),
                              ],
                            ),
                      ),
                );
                if (confirm == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account deleted'),
                      backgroundColor: cs.error,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpScreen()),
                  );
                } else {
                  setState(() {
                    _deletePressed = false;
                  });
                }
              },
              icon: Icon(Icons.delete, color: cs.onPrimary),
              label: Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _deletePressed ? cs.error : cs.surfaceVariant,
                foregroundColor: cs.onSurfaceVariant,
                minimumSize: const Size(double.infinity, 44),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 22),
            // Switch Account Button
            ElevatedButton.icon(
              onPressed: _switchAccount,
              icon: Icon(Icons.switch_account, color: cs.onPrimary),
              label: Text(
                'Switch Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(double.infinity, 44),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 22),
            // Subscription
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subscription:', style: TextStyle(color: cs.onSurface)),
                isPremium
                    ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.18),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (_subscriptionExpiresAt != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                'Remaining: ${DateTime.parse(_subscriptionExpiresAt!).difference(DateTime.now()).inDays} days',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                    : Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Standard',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              ],
            ),
            SizedBox(height: 12),
            if (!isPremium) ...[
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await _upgradeToPremium('PREMIUM_1_MONTH', 5.0);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: cs.primary,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text('1 Month'),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$5',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await _upgradeToPremium('PREMIUM_3_MONTHS', 12.0);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: cs.primary,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text('3 Months'),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$12',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await _upgradeToPremium('PREMIUM_12_MONTHS', 40.0);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: cs.primary,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text('12 Months'),
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$40',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SupportChatPage()),
                      );
                    },
                    icon: Icon(Icons.support_agent, color: cs.primary),
                    label: Text(
                      'Support',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.secondary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SupportChatPage extends StatelessWidget {
  SupportChatPage();

  final List<Map<String, String>> messages = [
    {'from': 'admin', 'text': 'Hello! How can I help you?'},
    {'from': 'user', 'text': 'Hi, thanks. Please help with my subscription.'},
    {'from': 'admin', 'text': 'Sure, go ahead with your question.'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.background,
        title: Text(
          'Live Support',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        iconTheme: IconThemeData(color: cs.onBackground),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['from'] == 'user';
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: cs.onBackground),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            color: cs.surfaceVariant,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(
                        color: cs.onBackground.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: cs.onBackground),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: cs.primary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
