import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class SocketService {
  static Socket? _socket;
  static Stream<List<int>>? socketStream;
  static const String SERVER_IP = "192.168.160.197";
  static const int SERVER_PORT = 8081;

  static final Map<String, Completer<Map<String, dynamic>>> _responseCompleters = {};
  static final StringBuffer _buffer = StringBuffer();

  static Future<bool> initSocket() async {
    if (_socket != null) return true;

    try {
      print('🔗 Connecting to $SERVER_IP:$SERVER_PORT...');
      _socket = await Socket.connect(SERVER_IP, SERVER_PORT, timeout: Duration(seconds: 5));
      socketStream = _socket!.asBroadcastStream();

      _startListening();

      print('✅ Socket connected');
      return true;
    } catch (e) {
      print('❌ Connection failed: $e');
      _disposeSocket();
      return false;
    }
  }

  static void _startListening() {
    socketStream!.listen(
          (data) {
        _buffer.write(utf8.decode(data));

        var lines = _buffer.toString().split('\n');
        _buffer.clear();

        if (lines.last.isNotEmpty) {
          _buffer.write(lines.removeLast());
        }

        for (final line in lines) {
          final cleanLine = line.trim();
          if (cleanLine.isEmpty) continue;
          try {
            final decoded = jsonDecode(cleanLine);
            print('📥 Received JSON: $decoded');
            if (decoded is Map<String, dynamic> && decoded['action'] != null) {
              final action = decoded['action'];
              if (_responseCompleters.containsKey(action)) {
                _responseCompleters[action]?.complete(decoded);
              } else {
                print('⚠️ No completer for action: $action');
              }
            } else {
              print('⚠️ Invalid JSON format');
            }
          } catch (e) {
            print('❌ Response parse error: $e');
            for (var c in _responseCompleters.values) {
              if (!c.isCompleted) c.completeError(e);
            }
          }
        }
      },
      onError: (error) {
        print('❌ Socket error: $error');
        _disposeSocket();
      },
      onDone: () {
        print('❌ Server disconnected');
        _disposeSocket();
      },
      cancelOnError: true,
    );
  }

  static void _disposeSocket() {
    _socket?.destroy();
    _socket = null;
    socketStream = null;
    for (var c in _responseCompleters.values) {
      if (!c.isCompleted) c.completeError('Connection closed');
    }
    _responseCompleters.clear();
  }

  static String _generateSalt([int length = 64]) {
    final rand = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64.encode(saltBytes);
  }

  static Future<String> hashPassword(String password, String saltBase64) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 65536,
      bits: 512,
    );
    final secretKey = SecretKey(utf8.encode(password));
    final salt = base64.decode(saltBase64);

    final newKey = await pbkdf2.deriveKey(secretKey: secretKey, nonce: salt);
    final hashed = await newKey.extractBytes();
    return base64.encode(hashed);
  }

  static Future<String?> _sendRequest(String action, Map<String, dynamic> data) async {
    if (_socket == null && !await initSocket()) return 'Could not connect to server.';

    final completer = Completer<Map<String, dynamic>>();
    final expectedResponseAction = action.endsWith('_request')
        ? '${action.replaceAll('_request', '')}_response'
        : '${action}_response';
    _responseCompleters[expectedResponseAction] = completer;

    final message = jsonEncode({'action': action, 'data': data}) + '\n';
    print('📤 Sending: $message');
    _socket!.write(message);

    // Timeout support
    Future.delayed(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.completeError('Timeout waiting for $expectedResponseAction');
      }
    });

    try {
      final response = await completer.future;
      _responseCompleters.remove(expectedResponseAction);

      if (response['status'] == 'success') {
        return jsonEncode(response);
      } else {
        // پیام خطا را به صورت رشته برگردان
        return response['message'] ?? 'Operation failed. Please try again.';
      }
    } catch (e) {
      _responseCompleters.remove(expectedResponseAction);
      return 'Operation failed. Please try again.';
    }
  }

  static Future<String?> fetchSalt(String email) async {
    final response = await _sendRequest('get_salt', {'email': email});
    if (response != null) {
      final decoded = jsonDecode(response);
      return decoded['salt'];
    }
    return null;
  }

  static Future<String?> fetchNonce(String email) async {
    final response = await _sendRequest('get_nonce', {'email': email});
    if (response != null) {
      final decoded = jsonDecode(response);
      return decoded['nonce'];
    }
    return null;
  }

  static Future<String?> sendSignupRequest(String username, String email, String password) async {
    final salt = _generateSalt();
    final hashedPassword = await hashPassword(password, salt);

    final response = await _sendRequest('signup_request', {
      'username': username,
      'email': email,
      'passwordHash': hashedPassword,
      'passwordSalt': salt,
    });

    if (response == null) return 'Signup failed. Please try again.';
    try {
      final decoded = jsonDecode(response);
      if (decoded['status'] == 'success') {
        return null;
      } else {
        return decoded['message'] ?? 'Signup failed. Please try again.';
      }
    } catch (_) {
      return response;
    }
  }

  static Future<String?> sendLoginRequest(String email, String password) async {
    final salt = await fetchSalt(email);
    if (salt == null) return 'Email not found.';

    final hashedPassword = await hashPassword(password, salt);

    final nonce = await fetchNonce(email);
    if (nonce == null) return 'Login failed.';

    final combinedHash = await _doubleHash(hashedPassword + nonce);

    final response = await _sendRequest('login_request', {
      'email': email,
      'passwordHash': combinedHash,
    });

    if (response == null) return 'Login failed. Please try again.';
    try {
      final decoded = jsonDecode(response);
      if (decoded['status'] == 'success') {
        return null;
      } else {
        return decoded['message'] ?? 'Login failed. Please check your credentials.';
      }
    } catch (_) {
      return response;
    }
  }

  static Future<String?> sendDeleteAccountRequest(String email, String password) async {
    final salt = await fetchSalt(email);
    if (salt == null) return 'Email not found.';
    final hashedPassword = await hashPassword(password, salt);

    final response = await _sendRequest('delete_account_request', {
      'email': email,
      'passwordHash': hashedPassword,
    });

    if (response == null) return 'Delete failed. Please try again.';
    try {
      final decoded = jsonDecode(response);
      if (decoded['status'] == 'success') {
        return null;
      } else {
        return decoded['message'] ?? 'Delete failed. Please try again.';
      }
    } catch (_) {
      return response;
    }
  }

  static Future<String?> updatePremiumStatus(String email, String subscriptionType) async {
    final response = await _sendRequest('update_premium_status', {
      'email': email,
      'subscriptionType': subscriptionType,
    });
    if (response == null) return 'Failed to update premium status.';
    try {
      final decoded = jsonDecode(response);
      if (decoded['status'] == 'success') {
        return null;
      } else {
        return decoded['message'] ?? 'Failed to update premium status.';
      }
    } catch (_) {
      return response;
    }
  }

  static Future<Map<String, dynamic>?> fetchUserStatus(String email) async {
    final response = await _sendRequest('get_user_status', {'email': email});
    if (response == null) return null;
    try {
      final decoded = jsonDecode(response);
      if (decoded['status'] == 'success') {
        // Check for subscription expiration
        final data = decoded['data'];
        if (data['subscriptionExpireAt'] != null) {
          final expiresAt = DateTime.tryParse(data['subscriptionExpireAt']);
          if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
            data['subscription'] = 'STANDARD';
            data['subscriptionExpireAt'] = null;
          }
        }
        return data;
      }
    } catch (_) {}
    return null;
  }

  static Future<String> _doubleHash(String input) async {
    final algo = Sha256();
    final hash = await algo.hash(utf8.encode(input));
    return base64.encode(hash.bytes);
  }
}