import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'paymentPage.dart';
import 'package:shake/shake.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'theme.dart';

void main() {
  runApp(UserProfile());
}

class UserProfile extends StatefulWidget {
  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isDark = true;
  bool _deletePressed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: ProfilePage(
        onThemeChange: (val) => setState(() => _isDark = val),
        isDark: _isDark,
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final ValueChanged<bool> onThemeChange;

  final bool isDark;
  ProfilePage({required this.onThemeChange, required this.isDark});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = 'Username';
  String _email = 'user@example.com';
  String _subscription = 'Standard';
  int _credit = 50000;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void payment() {
    print('Payment function called');
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
            // 1. پس‌زمینه از تم
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    // 2. رنگ آیکون از colorScheme.primary
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Gallery',
                    // 3. سبک متن از textTheme
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

  @override
  Widget build(BuildContext context) {
    bool _deletePressed = false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        elevation: 0,
        title: Text(
          'User Profile',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              widget.onThemeChange(!widget.isDark);
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (_imageFile != null)
                ? CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(File(_imageFile!.path)),
                ).animate().fade(duration: 500.ms).scale()
                : CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      widget.isDark ? Colors.grey[800] : Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ).animate().fade(duration: 500.ms).scale(),
            SizedBox(height: 8),
            IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _showImagePickerOptions,
              tooltip: 'Change Profile Picture',
            ),
            SizedBox(height: 16),
            Text(
              _username,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _email,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24),
            Card(
              color: widget.isDark ? Colors.grey[850] : Colors.grey[200],
              child: ListTile(
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Remaining Credit',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                trailing: Text(
                  '$_credit \$',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: Size(double.infinity, 48),
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text(
                'Add Credit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              onPressed: payment,
            ),
            SizedBox(height: 24),
            ExpansionTile(
              collapsedBackgroundColor:
                  widget.isDark ? Colors.grey[850] : Colors.grey[200],
              backgroundColor:
                  widget.isDark ? Colors.grey[900] : Colors.grey[100],
              title: Text(
                'Edit Info',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              leading: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              children: [
                TextField(
                  controller: _nameController..text = _username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                TextField(
                  controller: _emailController..text = _email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Save Changes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Changes saved')));
                  },
                ),
              ],
            ),
            SizedBox(height: 24),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _deletePressed = true;
                  });

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            'Are you sure?',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          content: Text(
                            'This will permanently delete your account.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Delete',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Account deleted',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  } else {
                    setState(() {
                      _deletePressed = false;
                    });
                  }
                },
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                label: Text(
                  'Delete Account',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _deletePressed
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.surfaceVariant,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subscription Type:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _subscription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_subscription != 'Premium') ...[
              Text(
                'Buy Premium Subscription',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => PaymentPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(
                      '1 Month',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => PaymentPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(
                      '3 Months',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => PaymentPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text(
                      '12 Months',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => SupportChatPage(isDark: widget.isDark),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.support_agent,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    label: Text(
                      'Support',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SupportChatPage extends StatelessWidget {
  final bool isDark;
  SupportChatPage({required this.isDark});

  final List<Map<String, String>> messages = [
    {'from': 'admin', 'text': 'Hello! How can I help you?'},
    {'from': 'user', 'text': 'Hi, thanks. Please help with my subscription.'},
    {'from': 'admin', 'text': 'Sure, go ahead with your question.'},
  ];

  @override
  Widget build(BuildContext context) {
    final Color txtColor = isDark ? Colors.white : Colors.black;
    final Color bubbleColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(
          'Live Support',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onBackground,
        ),
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
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onBackground.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
