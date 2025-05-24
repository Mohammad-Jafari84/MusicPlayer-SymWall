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
      builder: (_) => Container(
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

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'User Profile',
          style: TextStyle(color: cs.onBackground),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProv.isDarkMode
                  ? Icons.light_mode
                  : themeProv.isLightMode
                  ? Icons.eco
                  : Icons.dark_mode,
              color: cs.primary,
            ),
            onPressed: () {
              final prov = Provider.of<ThemeProvider>(context, listen: false);
              prov.cycleTheme(); // چرخش بین تم‌ها: dark -> light -> green
            },
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
              backgroundColor: cs.surface,
              child: Icon(
                Icons.person,
                size: 50,
                color: cs.primary,
              ),
            ).animate().fade(duration: 500.ms).scale(),
            SizedBox(height: 8),
            IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: cs.primary,
              ),
              onPressed: _showImagePickerOptions,
              tooltip: 'Change Profile Picture',
            ),
            SizedBox(height: 16),
            Text(
              _username,
              style: TextStyle(
                fontSize: 20,
                color: cs.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _email,
              style: TextStyle(
                fontSize: 16,
                color: cs.onBackground.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24),
            Card(
              color: cs.surface,
              child: ListTile(
                leading: Icon(
                  Icons.account_balance_wallet,
                  color: cs.primary,
                ),
                title: Text(
                  'Remaining Credit',
                  style: TextStyle(color: cs.onBackground),
                ),
                trailing: Text(
                  '$_credit \$',
                  style: TextStyle(color: cs.onBackground),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: Size(double.infinity, 48),
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text('Add Credit'),
              onPressed: payment,
            ),
            SizedBox(height: 24),
            ExpansionTile(
              collapsedBackgroundColor: cs.surface,
              backgroundColor: cs.surfaceVariant,
              title: Text(
                'Edit Info',
                style: TextStyle(color: cs.onBackground),
              ),
              leading: Icon(
                Icons.edit,
                color: cs.primary,
              ),
              children: [
                TextField(
                  controller: _nameController..text = _username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: cs.onBackground),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: cs.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(color: cs.onBackground),
                ),
                TextField(
                  controller: _emailController..text = _email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: cs.onBackground),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: cs.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(color: cs.onBackground),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: cs.onBackground),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: cs.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                  style: TextStyle(color: cs.onBackground),
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
                    builder: (context) => AlertDialog(
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
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: cs.error),
                          ),
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
                label: Text(
                  'Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _deletePressed ? cs.error : cs.surfaceVariant,
                  foregroundColor: cs.onSurfaceVariant,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subscription Type:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _subscription,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_subscription != 'Premium') ...[
              Text(
                'Buy Premium Subscription',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: cs.onBackground),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(amount: 100.0),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: Text('1 Month'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(amount: 100.0),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: Text('3 Months'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(amount: 100.0),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    child: Text('12 Months'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SupportChatPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.support_agent, color: cs.onPrimary),
                    label: Text(
                      'Support',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondaryContainer,
                      foregroundColor: cs.onSecondaryContainer,
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