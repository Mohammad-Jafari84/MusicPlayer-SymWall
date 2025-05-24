import 'package:flutter/material.dart';
import 'theme.dart';
import 'userProfile.dart';
import 'paymentPage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ShopSong {
  final String id;
  final String title;
  final String artist;
  final String imagePath;
  final double rating;
  final double price;
  final int downloads;
  final bool isFree;

  ShopSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.imagePath,
    required this.rating,
    required this.price,
    required this.downloads,
    required this.isFree,
  });
}

class Comment {
  final String id;
  final String username;
  final String text;
  final DateTime date;
  int likes;
  int dislikes;

  Comment({
    required this.id,
    required this.username,
    required this.text,
    required this.date,
    this.likes = 0,
    this.dislikes = 0,
  });
}

class MusicShopPage extends StatefulWidget {
  const MusicShopPage({Key? key}) : super(key: key);

  @override
  State<MusicShopPage> createState() => _MusicShopPageState();
}

enum SortOption { price, downloads, rating }

class _MusicShopPageState extends State<MusicShopPage> {
  final List<String> categories = [
    'Iranian',
    'Foreigner',
    'Top of songs',
    'The latest',
  ];

  String selectedCategory = 'Iranian';
  SortOption? selectedSortOption;

  final Map<String, List<ShopSong>> songsByCategory = {
    'Iranian': [
      ShopSong(
        id: '1',
        title: 'Ahoo',
        artist: 'Meysam Ebrahimi',
        imagePath:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRHz22XYGXnnynqPYzO8bJNjjgork8r0MXxwg&s',
        rating: 4.5,
        price: 1.99,
        downloads: 1000,
        isFree: false,
      ),
      ShopSong(
        id: '2',
        title: 'Divar',
        artist: 'Mehdi Ahmadvand',
        imagePath:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6dwCkXdmRzoqZ_JzXVRf7HTtQK97iaGIROQ&s',
        rating: 4.2,
        price: 0.00,
        downloads: 2500,
        isFree: true,
      ),
      // اضافه کردن آهنگ ایرانی asset
      ShopSong(
        id: 'shadmehr_bi_ehsas',
        title: 'Bi Ehsas',
        artist: 'Shadmehr Aghili',
        imagePath: 'assets/images/shadmehr-aghili-bi-ehsas.jpg',
        rating: 4.7,
        price: 0.00,
        downloads: 3000,
        isFree: true,
      ),
    ],
    'Foreigner': [
      ShopSong(
        id: '3',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        imagePath:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQkBcHnkbQmOIp93z5vk9ihLtzPTml2FOGMcg&s',
        rating: 4.8,
        price: 2.99,
        downloads: 5000,
        isFree: false,
      ),
      // اضافه کردن آهنگ خارجی asset
      ShopSong(
        id: 'nf_clouds',
        title: 'CLOUDS',
        artist: 'NF',
        imagePath: 'assets/images/Nf clouds.webp',
        rating: 4.9,
        price: 4.99,
        downloads: 8000,
        isFree: false,
      ),
    ],
    'Top of songs': [
      ShopSong(
        id: '4',
        title: 'Goriz',
        artist: 'Eb',
        imagePath:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQy4Q8Tr5CQI4BEnOzCI6cUbly2x6u7DkBojA&s',
        rating: 4.3,
        price: 0.99,
        downloads: 1200,
        isFree: false,
      ),
    ],
    'The latest': [
      ShopSong(
        id: '5',
        title: 'After You',
        artist: 'Mohsen Chavoshi',
        imagePath:
        'https://rozmusic.com/wp-content/uploads/2025/05/Mohsen-Chavoshi-Bad-Az-To.jpg',
        rating: 4.7,
        price: 1.49,
        downloads: 2000,
        isFree: false,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final currentSongs = List<ShopSong>.from(
      songsByCategory[selectedCategory] ?? [],
    );
    if (selectedSortOption != null) {
      currentSongs.sort((a, b) {
        switch (selectedSortOption!) {
          case SortOption.price:
            return a.price.compareTo(b.price);
          case SortOption.downloads:
            return b.downloads.compareTo(a.downloads);
          case SortOption.rating:
            return b.rating.compareTo(a.rating);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text(
          'Music Shop',
          style: tt.titleLarge?.copyWith(
            color: cs.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfile()),
              );
            },
          ),
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: Colors.grey),
            onSelected: (opt) => setState(() => selectedSortOption = opt),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: SortOption.price,
                child: Text(
                  'Sort by Price',
                  style: tt.bodyMedium,
                ),
              ),
              PopupMenuItem(
                value: SortOption.downloads,
                child: Text('Sort by Downloads', style: tt.bodyMedium),
              ),
              PopupMenuItem(
                value: SortOption.rating,
                child: Text('Sort by Rating', style: tt.bodyMedium),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final category = categories[i];
                final isSelected = category == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: tt.bodyMedium?.copyWith(
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentSongs.length,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (ctx, i) {
                final song = currentSongs[i];
                final isAssetSong = song.id == 'shadmehr_bi_ehsas' || song.id == 'nf_clouds';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: cs.background,
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.imagePath.startsWith('assets/')
                          ? Image.asset(
                        song.imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.onSurface.withOpacity(0.1),
                          child: Icon(Icons.music_note, color: cs.primary),
                        ),
                      )
                          : Image.network(
                        song.imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.onSurface.withOpacity(0.1),
                          child: Icon(Icons.music_note, color: cs.primary),
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: tt.bodyLarge?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.artist,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: cs.secondary,
                            ),
                            Text(
                              ' ${song.rating.toStringAsFixed(1)}',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.download,
                              size: 16,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                            Text(
                              ' ${song.downloads}',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: song.isFree
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                        : Text(
                      '\$${song.price.toStringAsFixed(2)}',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      // همیشه ابتدا وارد صفحه کامنت (SongDetailPage) شو
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongDetailPage(
                            song: song,
                            hasSubscription: false,
                          ),
                        ),
                      );
                      // اگر آهنگ asset دانلود شد، Map برمی‌گردد
                      if (result is Map && result['filePath'] != null) {
                        Navigator.pop(context, result);
                      } else if (result is ShopSong) {
                        Navigator.pop(context, result);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SongDetailPage extends StatefulWidget {
  final ShopSong song;
  final bool hasSubscription;

  const SongDetailPage({
    Key? key,
    required this.song,
    required this.hasSubscription,
  }) : super(key: key);

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  double userRating = 0;
  bool isDownloading = false;
  double downloadProgress = 0;
  List<Comment> comments = [];
  TextEditingController commentController = TextEditingController();
  bool isPurchased = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    setState(() {
      comments = [
        Comment(
          id: '1',
          username: 'User1',
          text: 'Great song!',
          date: DateTime.now().subtract(const Duration(days: 2)),
          likes: 5,
          dislikes: 1,
        ),
        Comment(
          id: '2',
          username: 'User2',
          text: 'I love this artist',
          date: DateTime.now().subtract(const Duration(days: 1)),
          likes: 3,
          dislikes: 0,
        ),
      ];
    });
  }

  void _submitComment() {
    if (commentController.text.isNotEmpty) {
      setState(() {
        comments.insert(
          0,
          Comment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            username: 'CurrentUser',
            text: commentController.text,
            date: DateTime.now(),
          ),
        );
        commentController.clear();
      });
    }
  }

  void _likeComment(String commentId) {
    setState(() {
      final comment = comments.firstWhere((c) => c.id == commentId);
      comment.likes++;
    });
  }

  void _dislikeComment(String commentId) {
    setState(() {
      final comment = comments.firstWhere((c) => c.id == commentId);
      comment.dislikes++;
    });
  }

  Future<String?> _copyAssetToDownloads(String assetPath, String fileName) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      Directory? musicDir;
      if (Platform.isAndroid) {
        // فولدر Music عمومی
        musicDir = Directory('/storage/emulated/0/Music');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
      } else {
        // برای iOS یا fallback
        final appDocDir = await getApplicationDocumentsDirectory();
        musicDir = Directory('${appDocDir.path}/DownloadedMusic');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
      }
      final audioFile = File('${musicDir.path}/$fileName');
      await audioFile.writeAsBytes(byteData.buffer.asUint8List());
      return audioFile.path;
    } catch (e) {
      print('Error copying files: $e');
      return null;
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0;
    });

    String? assetPath;
    String? fileName;

    if (widget.song.id == 'shadmehr_bi_ehsas') {
      assetPath = 'assets/audio/Shadmehr Aghili - Bi Ehsas.mp3';
      fileName = 'Shadmehr Aghili - Bi Ehsas.mp3';
    } else if (widget.song.id == 'nf_clouds') {
      assetPath = 'assets/audio/1. NF - CLOUDS (320).mp3';
      fileName = 'NF - CLOUDS.mp3';
    }

    if (assetPath != null && fileName != null) {
      for (int i = 0; i <= 100; i += 2) {
        if (!mounted) return;
        setState(() {
          downloadProgress = i / 100;
        });
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final savedPath = await _copyAssetToDownloads(assetPath, fileName);

      setState(() {
        isDownloading = false;
      });

      if (savedPath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download completed!')),
          );
        }
        // آهنگ را به صورت Map به صفحه قبل برگردان
        Navigator.pop(context, {
          'id': widget.song.id,
          'title': widget.song.title,
          'artist': widget.song.artist,
          'image': widget.song.imagePath,
          'filePath': savedPath,
          'lyrics': '',
        });
      }
    } else {
      setState(() {
        isDownloading = false;
      });
      Navigator.pop(context, widget.song);
    }
  }

  void _purchaseSong() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          amount: widget.song.price,
        ),
      ),
    );
    if (result == true) {
      setState(() {
        isPurchased = true;
      });
      // بعد از خرید، دانلود و کپی آهنگ asset
      _startDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final isFreeForUser = widget.song.isFree || widget.hasSubscription || isPurchased;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.song.title,
          style: tt.titleLarge,
        ),
        backgroundColor: cs.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.song.imagePath.startsWith('assets/')
                    ? Image.asset(
                  widget.song.imagePath,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: cs.onSurface.withOpacity(0.1),
                    child: Icon(
                      Icons.music_note,
                      size: 60,
                      color: cs.primary,
                    ),
                  ),
                )
                    : Image.network(
                  widget.song.imagePath,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: cs.onSurface.withOpacity(0.1),
                    child: Icon(
                      Icons.music_note,
                      size: 60,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                widget.song.title,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
            Center(
              child: Text(
                widget.song.artist,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Rating: ${widget.song.rating}',
                  style: tt.bodyMedium,
                ),
                const SizedBox(width: 10),
                ...List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < userRating ? Icons.star : Icons.star_border,
                      color: cs.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        userRating = index + 1.0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Rated ${widget.song.title} with $userRating stars',
                            style: tt.bodyMedium,
                          ),
                          backgroundColor: cs.primary,
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
            if (isDownloading) ...[
              LinearProgressIndicator(value: downloadProgress),
              Text(
                '${(downloadProgress * 100).toStringAsFixed(0)}%',
                style: tt.bodyMedium,
              ),
            ] else if (isFreeForUser)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _startDownload,
                  child: Text(
                    'Download Now',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _purchaseSong,
                  child: Text(
                    'Purchase for \$${widget.song.price}',
                    style: tt.bodyLarge?.copyWith(color: cs.onPrimary),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            Text(
              'Details',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.download,
                  size: 16,
                  color: cs.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Downloads: ${widget.song.downloads}',
                  style: tt.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: cs.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text('Price: \$${widget.song.price}', style: tt.bodyMedium),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Comments',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Add your comment...',
                      hintStyle: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: cs.primary),
                  onPressed: _submitComment,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...comments.map(
                  (comment) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            comment.username,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            '${comment.date.day}/${comment.date.month}/${comment.date.year}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(comment.text, style: tt.bodyMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              size: 16,
                              color: cs.secondary,
                            ),
                            onPressed: () => _likeComment(comment.id),
                          ),
                          Text(comment.likes.toString(), style: tt.bodyMedium),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down,
                              size: 16,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () => _dislikeComment(comment.id),
                          ),
                          Text(
                            comment.dislikes.toString(),
                            style: tt.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
