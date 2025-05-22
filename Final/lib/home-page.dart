import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'music-shop-page.dart';
import 'theme.dart';
import 'userProfile.dart';
import 'package:audio_service/audio_service.dart';

enum SongViewType { list, grid }

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

class GlobalAudioPlayer {
  static final AudioPlayer instance = AudioPlayer();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<String> likedSongIds = [];
  late SharedPreferences prefs;
  String searchQuery = "";
  int currentIndex = 0;
  bool hasSubscription = false;
  List<Song> localSongs = [];
  Future<List<Song>>? _localSongsFuture;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _permissionDenied = false;
  Song? _currentSong;
  bool _isPlaying = false;
  SongViewType _songViewType = SongViewType.list;
  late AnimationController _cassetteController;
  late Animation<double> _centerPulseAnimation;
  bool _isActuallyPlaying = false;

  // AudioService handler for notification and background playback
  AudioHandler? _audioHandler;

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
    _localSongsFuture = _getOrLoadLocalSongs();
    _cassetteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _centerPulseAnimation = Tween<double>(begin: 0.7, end: 1.5).animate(
      CurvedAnimation(parent: _cassetteController, curve: Curves.easeInOut),
    );
    _initAudioService();
    GlobalAudioPlayer.instance.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
          _isActuallyPlaying = isPlaying;
        });
      }
      if (isPlaying) {
        _cassetteController.repeat(reverse: true);
      } else {
        _cassetteController.stop();
      }
    });
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.musicapp.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );
  }

  @override
  void dispose() {
    _cassetteController.dispose();
    super.dispose();
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
    if (searchQuery.isEmpty) return songs;
    return songs
        .where(
          (song) =>
          song.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(searchQuery.toLowerCase()),
    )
        .toList();
  }

  // لایک‌ها: هم customSongs و هم localSongs را شامل کن
  List<Song> get likedSongs {
    final all = [...customSongs, ...localSongs];
    return all.where((song) => likedSongIds.contains(song.id)).toList();
  }

  // Try to load from cache, otherwise scan device
  Future<List<Song>> _getOrLoadLocalSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_local_songs');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      final songs = decoded.map((e) => Song(
        id: e['id'],
        title: e['title'],
        artist: e['artist'],
        image: null,
        filePath: e['filePath'],
        lyrics: '',
      )).toList().cast<Song>();
      setState(() {
        localSongs = songs;
      });
      // در پس‌زمینه، لیست را آپدیت کن (در صورت تغییر فایل‌ها)
      _loadLocalSongsAndUpdateCache();
      return songs;
    } else {
      return await _loadLocalSongsAndUpdateCache();
    }
  }

  // Always scan all songs, but cache metadata for next time
  Future<List<Song>> _loadLocalSongsAndUpdateCache() async {
    if (!await Permission.storage.request().isGranted) {
      setState(() => _permissionDenied = true);
      return [];
    }
    List<Song> foundSongs = [];
    try {
      List<SongModel> audioFiles = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      for (var song in audioFiles) {
        foundSongs.add(Song(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          image: null,
          filePath: song.data,
          lyrics: '',
        ));
      }
      // Cache metadata for next time
      final prefs = await SharedPreferences.getInstance();
      final toCache = foundSongs.map((s) => {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'filePath': s.filePath,
      }).toList();
      await prefs.setString('cached_local_songs', jsonEncode(toCache));
    } catch (e) {
      print('Error loading local songs: $e');
    }
    setState(() {
      localSongs = foundSongs;
      _permissionDenied = false;
    });
    return foundSongs;
  }

  List<Song> get allSongs => [...customSongs, ...localSongs];

  void _onSongPlay(Song song, List<Song> playlist) {
    setState(() {
      _currentSong = song;
      _isPlaying = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(song: song, songs: playlist),
      ),
    );
  }

  Widget _buildSongTile(Song song, List<Song> playlist) {
    final cs = Theme.of(context).colorScheme;
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
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onSongPlay(song, playlist),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
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
  }

  Widget _buildSongGridTile(Song song, List<Song> playlist) {
    final cs = Theme.of(context).colorScheme;
    final isLiked = likedSongIds.contains(song.id);
    return InkWell(
      onTap: () => _onSongPlay(song, playlist),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.15)),
        ),
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: song.image != null
                  ? Image.asset(
                song.image!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Icon(Icons.music_note, size: 50, color: cs.primary),
              )
                  : QueryArtworkWidget(
                id: int.tryParse(song.id) ?? 0,
                type: ArtworkType.AUDIO,
                nullArtworkWidget: Icon(Icons.music_note, size: 50, color: cs.primary),
                artworkBorder: BorderRadius.circular(12),
                artworkHeight: 90,
                artworkWidth: 90,
                artworkFit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
            ),
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
                size: 20,
              ),
              onPressed: () => toggleLike(song.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(List<Song> songsToShow) {
    if (_songViewType == SongViewType.list) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: songsToShow.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) => _buildSongTile(songsToShow[index], songsToShow),
      );
    } else {
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: songsToShow.length,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) => _buildSongGridTile(songsToShow[index], songsToShow),
      );
    }
  }

  // mini player: فقط وقتی روی خود mini player (نه دکمه‌ها) کلیک شد، PlayerPage باز شود
  Widget _buildMiniPlayer() {
    if (_currentSong == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.12), cs.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- animated icon ---
          AnimatedBuilder(
            animation: _cassetteController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _cassetteController.value * 2 * math.pi,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black,
                        Colors.grey.shade800,
                        Colors.grey.shade400,
                        Colors.white,
                      ],
                      stops: const [0.0, 0.7, 0.9, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _centerPulseAnimation,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // ...artwork...
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _currentSong!.image != null
                ? Image.asset(
                    _currentSong!.image!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Icon(Icons.music_note, size: 32, color: cs.primary),
                  )
                : QueryArtworkWidget(
                    id: int.tryParse(_currentSong!.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Icon(Icons.music_note, size: 32, color: cs.primary),
                    artworkBorder: BorderRadius.circular(10),
                    artworkHeight: 48,
                    artworkWidth: 48,
                    artworkFit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 14),
          // ...song info...
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerPage(
                      song: _currentSong!,
                      songs: allSongs,
                      resumeInsteadOfRestart: true,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSong!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _currentSong!.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ),
          // --- دکمه‌ها: فقط آهنگ را عوض کن، صفحه PlayerPage باز نشود ---
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () {
              final idx = allSongs.indexWhere((s) => s.id == _currentSong!.id);
              if (idx > 0) {
                setState(() {
                  _currentSong = allSongs[idx - 1];
                });
                if (_currentSong!.filePath.startsWith('assets/')) {
                  GlobalAudioPlayer.instance.setAsset(_currentSong!.filePath).then((_) {
                    GlobalAudioPlayer.instance.play();
                  });
                } else {
                  GlobalAudioPlayer.instance.setFilePath(_currentSong!.filePath).then((_) {
                    GlobalAudioPlayer.instance.play();
                  });
                }
              }
            },
          ),
          StreamBuilder<bool>(
            stream: GlobalAudioPlayer.instance.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 32),
                onPressed: () async {
                  if (isPlaying) {
                    await GlobalAudioPlayer.instance.pause();
                  } else {
                    await GlobalAudioPlayer.instance.play();
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () {
              final idx = allSongs.indexWhere((s) => s.id == _currentSong!.id);
              if (idx < allSongs.length - 1) {
                setState(() {
                  _currentSong = allSongs[idx + 1];
                });
                if (_currentSong!.filePath.startsWith('assets/')) {
                  GlobalAudioPlayer.instance.setAsset(_currentSong!.filePath).then((_) {
                    GlobalAudioPlayer.instance.play();
                  });
                } else {
                  GlobalAudioPlayer.instance.setFilePath(_currentSong!.filePath).then((_) {
                    GlobalAudioPlayer.instance.play();
                  });
                }
              }
            },
          ),
        ],
      ),
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
          IconButton(
            icon: Icon(
              _songViewType == SongViewType.list ? Icons.grid_view : Icons.list,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: 'Toggle view',
            onPressed: () {
              setState(() {
                _songViewType = _songViewType == SongViewType.list
                    ? SongViewType.grid
                    : SongViewType.list;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onPrimary),
            onSelected: (value) {
              if (value == 'name') {
                setState(() {
                  customSongs.sort((a, b) => a.title.compareTo(b.title));
                  localSongs.sort((a, b) => a.title.compareTo(b.title));
                });
              }
            },
            itemBuilder: (context) => [
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
        child: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: [
                FutureBuilder<List<Song>>(
                  future: _localSongsFuture,
                  builder: (context, snapshot) {
                    if (_permissionDenied) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Storage permission denied. Please enable it in settings.')),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    localSongs = snapshot.data ?? [];
                    final songsToShow = filterSongs([...customSongs, ...localSongs]);
                    if (songsToShow.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No music found.')),
                      );
                    }
                    return _buildSongList(songsToShow);
                  },
                ),
                likedSongs.isEmpty
                    ? Center(
                  child: Text(
                    'No liked songs yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                )
                    : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Liked Songs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                            errorBuilder: (c, e, s) => Icon(Icons.music_note, size: 40, color: Theme.of(context).colorScheme.primary),
                          )
                              : QueryArtworkWidget(
                            id: int.tryParse(song.id) ?? 0,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Icon(Icons.music_note, size: 40, color: Theme.of(context).colorScheme.primary),
                            artworkBorder: BorderRadius.circular(8),
                            artworkHeight: 50,
                            artworkWidth: 50,
                            artworkFit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => toggleLike(song.id),
                        ),
                        onTap: () => _onSongPlay(song, likedSongs),
                      ),
                    ),
                  ],
                ),
                const MusicShopPage(),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildMiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }
}

// AudioService handler for notification and background playback
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = GlobalAudioPlayer.instance;

  MyAudioHandler() {
    _notify();
    _player.playerStateStream.listen((state) => _notify());
    _player.currentIndexStream.listen((_) => _notify());
  }

  void _notify() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      playing: playing,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> skipToNext() => _player.seekToNext();
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
}

// --- Cassette Disc Painter for Mini Player ---
class _CassetteDiscPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint discPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade800, Colors.grey.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2));
    final Paint centerPaint = Paint()..color = Colors.black;
    final Paint holePaint = Paint()..color = Colors.white;

    // Draw disc
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, discPaint);
    // Draw center
    canvas.drawCircle(size.center(Offset.zero), size.width / 6, centerPaint);
    // Draw hole
    canvas.drawCircle(size.center(Offset.zero), size.width / 16, holePaint);

    // Draw cassette tape holes (left/right)
    final Paint tapeHolePaint = Paint()..color = Colors.black.withOpacity(0.7);
    final double tapeHoleRadius = size.width / 10;
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.7), tapeHoleRadius, tapeHolePaint);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.7), tapeHoleRadius, tapeHolePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> songs;
  final bool resumeInsteadOfRestart;
  const PlayerPage({super.key, required this.song, required this.songs, this.resumeInsteadOfRestart = false});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioPlayer _player = GlobalAudioPlayer.instance;
  bool isShuffling = false;
  bool isRepeating = false;
  int _currentIndex = 0;
  List<Song> _playlist = [];

  @override
  void initState() {
    super.initState();
    _playlist = List.from(widget.songs);
    _currentIndex = _playlist.indexWhere((song) => song.id == widget.song.id);
    // Only play if not resuming
    if (!(widget.resumeInsteadOfRestart == true && _player.playing)) {
      _playSong(_playlist[_currentIndex]);
    }
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextSong();
      }
    });
  }

  void _playSong(Song song) async {
    try {
      if (_player.playing) await _player.stop();
      if (song.filePath.startsWith('assets/')) {
        await _player.setAsset(song.filePath);
      } else {
        await _player.setFilePath(song.filePath);
      }
      await _player.play();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play the song: ${e.toString()}')),
        );
      }
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
    // Do not dispose the global player here
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




