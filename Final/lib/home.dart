import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';
import 'theme.dart';
import 'userProfile.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String? image; // nullable for local songs
  final String filePath;
  final String lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.image,
    required this.filePath,
    required this.lyrics,
  });
}

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> likedSongIds = [];
  late SharedPreferences prefs;
  String searchQuery = "";
  int currentIndex = 0;
  bool hasSubscription = false;
  List<Song> localSongs = [];
  List<FileSystemEntity> localImageFiles = [];
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<Song> customSongs = [
    Song(
      id: '1',
      title: 'Bi Ehsas ',
      artist: 'Shadmehr',
      image: 'assets/images/shadmehr-aghili-bi-ehsas.jpg',
      filePath: 'assets/audio/Shadmehr Aghili - Bi Ehsas.mp3',
      lyrics: 'Lyrics of Bi Ehsas ...',
    ),
    Song(
      id: '2',
      title: 'Divar',
      artist: 'Mehdi Ahmadvand',
      image: 'assets/images/Mehdi-Ahmadvand-Divar.jpg',
      filePath: 'assets/audio/Mehdi Ahmadvand - Divar.mp3',
      lyrics: 'Lyrics of Divar...',
    ),

    Song(
      id: '3',
      title: 'Behet Ghol Midam',
      artist: 'Mohsen Yegane',
      image: 'assets/images/Mohsen-Yeganeh-Behet Ghol Midam.jpg',
      filePath: 'assets/audio/Mohsen Yeganeh - Behet Ghol Midam.mp3',
      lyrics: 'Lyrics of BehetGholMidam...',
    ),
    Song(
      id: '4',
      title: 'Nf-Clouds',
      artist: 'Nf',
      image: 'assets/images/Nf clouds.webp',
      filePath: 'assets/audio/1. NF - CLOUDS (320).mp3',
      lyrics: 'Lyrics of Clouds...',
    ),
    Song(
      id: '5',
      title: 'Plain Jane',
      artist: 'ASAP Ferg Ft Nicki Minaj',
      image: 'assets/images/Plain Jane.png',
      filePath: 'assets/audio/ASAP Ferg Plain Jane Ft Nicki Minaj Remix.mp3',
      lyrics: 'Lyrics of Plain Jane...',
    ),
  ];

  @override
  void initState() {
    super.initState();
    initApp();
    _loadLocalSongs();
  }

  Future<void> initApp() async {
    await loadPrefs();
    hasSubscription = await checkSubscriptionStatus();
  }

  Future<bool> checkSubscriptionStatus() async {
    return false;
  }

  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      likedSongIds = prefs.getStringList('likedSongs') ?? [];
    });
  }

  void toggleLike(String id) async {
    setState(() {
      if (likedSongIds.contains(id)) {
        likedSongIds.remove(id);
      } else {
        likedSongIds.add(id);
      }
    });
    await prefs.setStringList('likedSongs', likedSongIds);
  }

  List<Song> filterSongs(List<Song> songs) {
    return songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Song> get likedSongs {
    return customSongs.where((song) => likedSongIds.contains(song.id)).toList();
  }

  Future<void> _loadLocalSongs() async {
    if (!await Permission.storage.request().isGranted) return;
    List<Song> foundSongs = [];
    List<FileSystemEntity> foundImages = [];
    try {
      List<SongModel> audioFiles = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      for (var song in audioFiles) {
        foundSongs.add(Song(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          image: null, // will use QueryArtworkWidget
          filePath: song.data,
          lyrics: '',
        ));
      }
      // Scan for images (album arts) in Music folder
      final musicDir = Directory('/storage/emulated/0/Music');
      if (await musicDir.exists()) {
        await for (var entity in musicDir.list(recursive: true)) {
          if (entity is File) {
            String path = entity.path.toLowerCase();
            if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
              foundImages.add(entity);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading local songs: $e');
    }
    setState(() {
      localSongs = foundSongs;
      localImageFiles = foundImages;
      // Avoid duplicates in customSongs
      customSongs = [
        ...foundSongs.where((song) => !customSongs.any((s) => s.id == song.id)),
        ...customSongs,
      ];
    });
  }

  Widget _buildLocalFilesSection() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (localSongs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Local Music',
              style: tt.titleLarge,
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: localSongs.length,
              itemBuilder: (context, index) {
                final song = localSongs[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerPage(song: song, songs: localSongs),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          QueryArtworkWidget(
                            id: int.tryParse(song.id) ?? 0,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Icon(Icons.music_note, size: 40, color: cs.primary),
                            artworkBorder: BorderRadius.circular(8),
                            artworkHeight: 60,
                            artworkWidth: 60,
                            artworkFit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (localImageFiles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Local Images',
              style: tt.titleLarge,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: localImageFiles.length,
            itemBuilder: (context, index) {
              final file = localImageFiles[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(),
                          body: Center(child: Image.file(File(file.path))),
                        ),
                      ),
                    );
                  },
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text("SymWall", style: GoogleFonts.dancingScript(fontSize: 33)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              style: tt.bodyMedium,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "search...",
                hintStyle: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
                prefixIcon: Icon(Icons.search, color: cs.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onPrimary),
            onSelected: (value) {
              if (value == 'name') {
                setState(() {
                  customSongs.sort((a, b) => a.title.compareTo(b.title));
                });
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Text('Sort by name'),
                  ),
                ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.6),
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Liked'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [
            // Home Tab
            ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildLocalFilesSection(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filterSongs(customSongs).length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final song = filterSongs(customSongs)[index];
                    final isLiked = likedSongIds.contains(song.id);

                    return Card(
                      color: cs.surface,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: cs.onSurface.withOpacity(0.2),
                          width: 1,
                        ), // ← (تغییر)
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        PlayerPage(song: song, songs: customSongs),
                              ),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Album Art
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: song.image != null
                                    ? Image.asset(
                                        song.image!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Icon(Icons.music_note, size: 40, color: cs.primary),
                                      )
                                    : QueryArtworkWidget(
                                        id: int.tryParse(song.id) ?? 0,
                                        type: ArtworkType.AUDIO,
                                        nullArtworkWidget: Icon(Icons.music_note, size: 40, color: cs.primary),
                                        artworkBorder: BorderRadius.circular(8),
                                        artworkHeight: 60,
                                        artworkWidth: 60,
                                        artworkFit: BoxFit.cover,
                                      ),
                              ),

                              const SizedBox(width: 16),

                              // Song Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      song.artist,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Like Button
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => toggleLike(song.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Liked Songs Tab
            likedSongs.isEmpty
                ? Center(
                  // ← حذف const تا از textTheme استفاده بشه
                  child: Text(
                    'No liked songs yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      // ← از تم مرکزی
                      fontSize: 18,
                    ),
                  ),
                )
                : ListView(
                  children: [
                    Padding(
                      // ← حذف const
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Liked Songs',
                        style: Theme.of(context) // ← از تم مرکزی
                        .textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...likedSongs.map(
                      (song) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.image != null
                              ? Image.asset(
                                  song.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Icon(Icons.music_note, size: 40, color: cs.primary),
                                )
                              : QueryArtworkWidget(
                                  id: int.tryParse(song.id) ?? 0,
                                  type: ArtworkType.AUDIO,
                                  nullArtworkWidget: Icon(Icons.music_note, size: 40, color: cs.primary),
                                  artworkBorder: BorderRadius.circular(8),
                                  artworkHeight: 50,
                                  artworkWidth: 50,
                                  artworkFit: BoxFit.cover,
                                ),
                        ),
                        title: Text(
                          song.title,
                          style:
                              Theme.of(context).textTheme.bodyLarge, // ← از تم
                        ),
                        subtitle: Text(
                          song.artist,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context) // ← از تم
                            .colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.error, // ← از تم (قرمز)
                          ),
                          onPressed: () => toggleLike(song.id),
                        ),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PlayerPage(
                                      song: song,
                                      songs: likedSongs,
                                    ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),

            // Shop Tab
            const MusicShopPage(),
          ],
        ),
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> songs;
  const PlayerPage({super.key, required this.song, required this.songs});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioPlayer _player = AudioPlayer();
  bool isShuffling = false;
  bool isRepeating = false;
  int _currentIndex = 0;
  List<Song> _playlist = [];

  @override
  void initState() {
    super.initState();
    _playlist = List.from(widget.songs);
    _currentIndex = _playlist.indexWhere((song) => song.id == widget.song.id);
    _playSong(_playlist[_currentIndex]);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextSong();
      }
    });
  }

  void _playSong(Song song) async {
    try {
      await _player.stop();
      if (song.filePath.startsWith('assets/')) {
        await _player.setAsset(song.filePath);
      } else {
        await _player.setFilePath(song.filePath);
      }
      await _player.play();
      setState(() {});
    } catch (e) {
      print('Error playing song: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play the song: ${e.toString()}')),
      );
    }
  }

  void _playNextSong() {
    if (_playlist.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    });
    _playSong(_playlist[_currentIndex]);
  }

  void _playPreviousSong() {
    if (_playlist.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1) >= 0 ? _currentIndex - 1 : _playlist.length - 1;
    });
    _playSong(_playlist[_currentIndex]);
  }

  void _toggleShuffle() {
    setState(() {
      isShuffling = !isShuffling;
      if (isShuffling) {
        final currentSong = _playlist[_currentIndex];
        _playlist.shuffle();
        _currentIndex = _playlist.indexWhere((s) => s.id == currentSong.id);
      } else {
        _playlist = List.from(widget.songs);
        _currentIndex = _playlist.indexWhere((s) => s.id == widget.song.id);
      }
    });
  }

  Widget _buildWaveform() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: WaveWidget(
        config: CustomConfig(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.5),
            Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ],
          durations: [3500, 19440],
          heightPercentages: [0.65, 0.66],
        ),
        backgroundColor: Colors.transparent,
        size: Size(double.infinity, 50),
        waveAmplitude: 10,
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final currentSong = _playlist[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text(currentSong.title, style: tt.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          currentSong.image != null
              ? Image.asset(
                  currentSong.image!,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(Icons.music_note, size: 100, color: cs.primary),
                )
              : QueryArtworkWidget(
                  id: int.tryParse(currentSong.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Icon(Icons.music_note, size: 100, color: cs.primary),
                  artworkBorder: BorderRadius.circular(8),
                  artworkHeight: 250,
                  artworkWidth: 250,
                  artworkFit: BoxFit.cover,
                ),
          const SizedBox(height: 20),
          Text(currentSong.title, style: tt.titleLarge),
          Text(currentSong.artist, style: tt.titleMedium),
          _buildWaveform(),
          const SizedBox(height: 10),
          StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ProgressBar(
                      progress: position,
                      total: duration,
                      thumbColor: cs.primary,
                      baseBarColor: cs.onSurface.withOpacity(0.3),
                      progressBarColor: cs.primary,
                      bufferedBarColor: cs.secondary,
                      onSeek: _player.seek,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, color: cs.onSurface),
                onPressed: _playPreviousSong,
              ),
              StreamBuilder<bool>(
                stream: _player.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: cs.primary),
                    iconSize: 48,
                    onPressed: () {
                      isPlaying ? _player.pause() : _player.play();
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: cs.onSurface),
                onPressed: _playNextSong,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(isShuffling ? Icons.shuffle_on : Icons.shuffle),
                color: cs.onSurface,
                onPressed: _toggleShuffle,
              ),
              IconButton(
                icon: Icon(isRepeating ? Icons.repeat_on : Icons.repeat),
                color: cs.onSurface,
                onPressed: () {
                  setState(() {
                    isRepeating = !isRepeating;
                    _player.setLoopMode(isRepeating ? LoopMode.one : LoopMode.off);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Lyrics:', style: tt.titleMedium),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(currentSong.lyrics, style: tt.bodyMedium),
          ),
        ],
      ),
    );
  }
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // ساخت لیست بر اساس دسته‌بندی و سورت
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

    // در همهٔ مسیرها Scaffold برگردانده می‌شود:
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface, // ← از تم مرکزی
        title: Text(
          'Music Shop',
          style: tt.titleLarge?.copyWith(
            color: cs.primary,
          ), // ← از textTheme + colorScheme
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.grey), // ← از colorScheme
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfile()),
              );
            },
          ),
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: Colors.grey), // ← از colorScheme
            onSelected: (opt) => setState(() => selectedSortOption = opt),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: SortOption.price,
                    child: Text(
                      'Sort by Price',
                      style: tt.bodyMedium,
                    ), // ← از textTheme
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
          // Tab دسته‌بندی
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
                      color:
                          isSelected
                              ? cs
                                  .primary // ← از colorScheme
                              : cs.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: tt.bodyMedium?.copyWith(
                        // ← از textTheme
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // لیست آهنگ‌ها
          Expanded(
            child: ListView.builder(
              itemCount: currentSongs.length,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemBuilder: (ctx, i) {
                final song = currentSongs[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  color: cs.background, // ← از colorScheme
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song.imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: cs.onSurface.withOpacity(
                                0.1,
                              ), // ← از colorScheme
                              child: Icon(Icons.music_note, color: cs.primary),
                            ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: tt.bodyLarge?.copyWith(
                        color: cs.primary,
                      ), // ← از textTheme + colorScheme
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.artist,
                          style: tt.bodyMedium?.copyWith(
                            // ← از textTheme
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
                            ), // ← از colorScheme
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
                    trailing:
                        song.isFree
                            ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green, // ← از colorScheme
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
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SongDetailPage(
                                  song: song,
                                  hasSubscription: false,
                                ),
                          ),
                        ),
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

  void _startDownload() async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0;
    });

    // Simulate download progress
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        downloadProgress = i / 100;
      });
    }

    setState(() {
      isDownloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download completed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _purchaseSong() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Purchase Song'),
            content: Text(
              'Do you want to purchase "${widget.song.title}" for \$${widget.song.price}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    isPurchased = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Purchased ${widget.song.title} successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Purchase'),
              ),
            ],
          ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final isFreeForUser =
        widget.song.isFree || widget.hasSubscription || isPurchased;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.song.title,
          style: tt.titleLarge, // ← استفاده از textTheme
        ),
        backgroundColor: cs.surface, // ← استفاده از colorScheme
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song Cover Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.song.imagePath,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 200,
                        height: 200,
                        color: cs.onSurface.withOpacity(
                          0.1,
                        ), // ← از colorScheme
                        child: Icon(
                          Icons.music_note,
                          size: 60,
                          color: cs.primary, // ← از colorScheme
                        ),
                      ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Song Title and Artist
            Center(
              child: Text(
                widget.song.title,
                style: tt.headlineSmall?.copyWith(
                  // ← متن بزرگ از textTheme
                  fontWeight: FontWeight.bold,
                  color: cs.primary, // ← از colorScheme
                ),
              ),
            ),

            Center(
              child: Text(
                widget.song.artist,
                style: tt.bodyMedium?.copyWith(
                  // ← از textTheme
                  color: cs.onSurface.withOpacity(0.7), // ← از colorScheme
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Rating Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Rating: ${widget.song.rating}',
                  style: tt.bodyMedium, // ← از textTheme
                ),
                const SizedBox(width: 10),
                ...List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < userRating ? Icons.star : Icons.star_border,
                      color: cs.secondary, // ← از colorScheme
                    ),
                    onPressed: () {
                      setState(() {
                        userRating = index + 1.0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Rated ${widget.song.title} with $userRating stars',
                            style: tt.bodyMedium, // ← از textTheme
                          ),
                          backgroundColor: cs.primary, // ← از colorScheme
                        ),
                      );
                    },
                  );
                }),
              ],
            ),

            const SizedBox(height: 20),

            // Download/Purchase Section
            if (isDownloading) ...[
              LinearProgressIndicator(value: downloadProgress),
              Text(
                '${(downloadProgress * 100).toStringAsFixed(0)}%',
                style: tt.bodyMedium, // ← از textTheme
              ),
            ] else if (isFreeForUser)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary, // ← از colorScheme
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _startDownload,
                  child: Text(
                    'Download Now',
                    style: tt.bodyLarge?.copyWith(
                      // ← از textTheme
                      color: cs.onPrimary, // ← از colorScheme
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

            // Song Details
            Text(
              'Details',
              style: tt.titleMedium?.copyWith(
                // ← از textTheme
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

            // Comments Section
            Text(
              'Comments',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),

            const SizedBox(height: 10),

            // Comment Input
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

            // Comments List
            ...comments.map(
              (comment) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: cs.surface, // ← از colorScheme
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

