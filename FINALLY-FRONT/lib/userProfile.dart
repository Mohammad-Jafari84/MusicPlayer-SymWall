import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'theme.dart';
import 'paymentPage.dart';

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
  int _credit = 50000;
  bool _deletePressed = false;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void payment() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentPage(amount: 100.0)),
    );
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
      builder: (_) =>
          Container(
            color: Theme
                .of(context)
                .scaffoldBackgroundColor,
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                  title: Text(
                    'Gallery',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                  title: Text(
                    'Camera',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
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
    final cs = Theme
        .of(context)
        .colorScheme;
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
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaymentPage(amount: amount!)),
      );
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




  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final cs = Theme
        .of(context)
        .colorScheme;

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
            itemBuilder: (context) => [
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
                          cs.secondary.withOpacity(0.10)
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
                        backgroundImage: _imageFile != null
                            ? FileImage(File(_imageFile!.path))
                            : null,
                        child: _imageFile == null
                            ? Icon(Icons.person, size: 48, color: cs.primary)
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
                          child: Icon(Icons.camera_alt, color: cs.onPrimary,
                              size: 20),
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
                    Icons.account_balance_wallet, color: cs.primary, size: 28),
                title: Text('Credit', style: TextStyle(color: cs.onSurface)),
                trailing: Text('$_credit \$',
                    style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
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
                    borderRadius: BorderRadius.circular(12)),
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
                  TextField(
                    controller: _emailController..text = _email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: cs.onSurface),
                    ),
                    style: TextStyle(color: cs.onSurface),
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
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Changes saved')),
                      );
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
                });
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) =>
                      AlertDialog(
                        title: Text('Are you sure?'),
                        content: Text(
                            'This will permanently delete your account.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                                'Delete', style: TextStyle(color: cs.error)),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account deleted'),
                      backgroundColor: cs.error,
                    ),
                  );
                } else {
                  setState(() {
                    _deletePressed = false;
                  });
                }
              },
              icon: Icon(Icons.delete, color: cs.onPrimary),
              label: Text('Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _deletePressed ? cs.error : cs.surfaceVariant,
                foregroundColor: cs.onSurfaceVariant,
                minimumSize: const Size(double.infinity, 44),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 22),
            // Subscription
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subscription:', style: TextStyle(color: cs.onSurface)),
                Text(_subscription, style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            if (_subscription != 'Premium') ...[
              Text('Upgrade to Premium', style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final label in ['1 Month', '3 Months', '12 Months'])
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (
                            _) => PaymentPage(amount: 100.0)));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(label),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SupportChatPage()));
                    },
                    icon: Icon(Icons.support_agent, color: cs.primary),
                    label: Text('Support',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.secondary, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
