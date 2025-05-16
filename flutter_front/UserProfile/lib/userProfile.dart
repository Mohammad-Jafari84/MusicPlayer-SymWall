import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'paymentPage.dart';
import 'package:shake/shake.dart';

void main() {
  runApp(UserProfile());
}

const Color darkColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFFACF5A);
const Color lightColor = Colors.white;

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFACF5A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Color(0xFF1C1C1C),
        useMaterial3: true,
      ),
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
            color: widget.isDark ? darkColor : lightColor,
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: widget.isDark ? goldColor : darkColor,
                  ),
                  title: Text(
                    'Gallery',
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: widget.isDark ? goldColor : darkColor,
                  ),
                  title: Text(
                    'Camera',
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
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
    final Color bgColor = widget.isDark ? darkColor : lightColor;
    final Color txtColor = widget.isDark ? Colors.white : Colors.black;
    final Color iconColor = widget.isDark ? goldColor : darkColor;

    bool _deletePressed = false;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('User Profile', style: TextStyle(color: txtColor)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: iconColor),
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
                  child: Icon(Icons.person, size: 50, color: iconColor),
                ).animate().fade(duration: 500.ms).scale(),
            SizedBox(height: 8),
            IconButton(
              icon: Icon(Icons.camera_alt, color: iconColor),
              onPressed: _showImagePickerOptions,
              tooltip: 'Change Profile Picture',
            ),
            SizedBox(height: 16),
            Text(
              _username,
              style: TextStyle(
                fontSize: 20,
                color: txtColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: txtColor.withOpacity(0.7)),
            ),
            SizedBox(height: 24),
            Card(
              color: widget.isDark ? Colors.grey[850] : Colors.grey[200],
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet, color: iconColor),
                title: Text(
                  'Remaining Credit',
                  style: TextStyle(color: txtColor),
                ),
                trailing: Text(
                  '$_credit \$',
                  style: TextStyle(color: txtColor),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: widget.isDark ? darkColor : lightColor,
                minimumSize: Size(double.infinity, 48),
              ),
              icon: Icon(Icons.add_shopping_cart),
              label: Text(
                'Add Credit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: payment,
            ),
            SizedBox(height: 24),
            ExpansionTile(
              collapsedBackgroundColor:
                  widget.isDark ? Colors.grey[850] : Colors.grey[200],
              backgroundColor:
                  widget.isDark ? Colors.grey[900] : Colors.grey[100],
              title: Text('Edit Info', style: TextStyle(color: txtColor)),
              leading: Icon(Icons.edit, color: iconColor),
              children: [
                TextField(
                  controller: _nameController..text = _username,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: txtColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: txtColor.withOpacity(0.5)),
                    ),
                  ),
                  style: TextStyle(color: txtColor),
                ),
                TextField(
                  controller: _emailController..text = _email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: txtColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: txtColor.withOpacity(0.5)),
                    ),
                  ),
                  style: TextStyle(color: txtColor),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: txtColor),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: txtColor.withOpacity(0.5)),
                    ),
                  ),
                  style: TextStyle(color: txtColor),
                  obscureText: true,
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: widget.isDark ? darkColor : lightColor,
                  ),
                  child: Text('Save Changes'),
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
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _deletePressed
                          ? Colors.redAccent
                          : Color.fromARGB(255, 162, 161, 161),
                  foregroundColor: widget.isDark ? darkColor : lightColor,
                  minimumSize: Size(double.infinity, 48),
                ),
                icon: Icon(Icons.delete),
                label: Text(
                  'Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  setState(() {
                    _deletePressed = true;
                  });

                  // نمایش هشدار تایید
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Are you sure?'),
                          content: Text(
                            'This will permanently delete your account.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    // TODO: حذف اکانت واقعی اینجا انجام بشه
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Account deleted')));
                  } else {
                    setState(() {
                      _deletePressed = false; // برمی‌گرده به رنگ اولیه
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subscription Type:',
                  style: TextStyle(fontSize: 16, color: txtColor),
                ),
                Text(
                  _subscription,
                  style: TextStyle(
                    fontSize: 16,
                    color: txtColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_subscription != 'Premium') ...[
              Text(
                'Buy Premium Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: txtColor,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: widget.isDark ? darkColor : lightColor,
                    ),
                    child: Text('1 Month'),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => PaymentPage()));
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: widget.isDark ? darkColor : lightColor,
                    ),
                    child: Text('3 Months'),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => PaymentPage()));
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: widget.isDark ? darkColor : lightColor,
                    ),
                    child: Text('12 Months'),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => PaymentPage()));
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700], // رنگ خاکستری دلخواه
                      foregroundColor: widget.isDark ? darkColor : lightColor,
                      minimumSize: Size(double.infinity, 48), // تمام‌عرض
                    ),
                    icon: Icon(
                      Icons.support_agent,
                      color:
                          widget.isDark
                              ? darkColor
                              : lightColor, // رنگ آیکون واضح
                    ),
                    label: Text(
                      'Support',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => SupportChatPage(isDark: widget.isDark),
                        ),
                      );
                    },
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
        backgroundColor: isDark ? darkColor : lightColor,
        title: Text('Live Support', style: TextStyle(color: txtColor)),
        iconTheme: IconThemeData(color: txtColor),
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
                      style: TextStyle(color: txtColor),
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
                      hintStyle: TextStyle(color: txtColor.withOpacity(0.6)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: txtColor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: isDark ? goldColor : darkColor),
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
