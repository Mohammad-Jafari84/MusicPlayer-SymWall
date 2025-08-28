import 'dart:io';
import 'dart:convert';

void main() async {
  final host = 'localhost'; // آدرس سرور
  final port = 8085;        // پورت سرور
  final targetDirPath = r'D:\MyCode\MusicPlayer-frontend-mohammad\MusicPlayer-frontend-mohammad\assets\audio';

  try {
    // اتصال به سرور سوکت
    final socket = await Socket.connect(host, port);
    print('Connected to server at $host:$port');

    // دریافت داده از سوکت
    final buffer = await socket.fold<List<int>>([], (prev, element) {
      prev.addAll(element);
      return prev;
    });

    final jsonString = utf8.decode(buffer);
    print('Received JSON from server:\n$jsonString');

    // تبدیل JSON به لیستی از دیکشنری‌ها
    final List<dynamic> musicList = jsonDecode(jsonString);


    final targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);

    }


    for (var music in musicList) {
      final originalPath = music['file_path'] as String;
      final fileName = originalPath.split(RegExp(r'[\\/]+')).last;
      final destinationPath = '$targetDirPath\\$fileName';

      // print('$originalPath');
      // print('$destinationPath');

      final originalFile = File(originalPath);
      final destinationFile = File(destinationPath);

      if (await originalFile.exists()) {
        await originalFile.copy(destinationFile.path);
        print('$fileName');
      } else {
        print('File not found: $originalPath');
      }
    }

    // بستن سوکت
    socket.destroy();
    print('Done.');

  } catch (e) {
    print('Error: $e');
  }
}
