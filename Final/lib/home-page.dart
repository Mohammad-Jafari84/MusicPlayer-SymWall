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
import 'dart:io';
import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'music-shop-page.dart';
import 'theme.dart';
import 'userProfile.dart';

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
  final String? image;
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
  AudioHandler? _audioHandler;

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

    bool? lastIsPlaying;
    GlobalAudioPlayer.instance.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      if (lastIsPlaying != isPlaying) {
        lastIsPlaying = isPlaying;
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
      }
    });
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
        .where((song) =>
    song.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        song.artist.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  List<Song> get likedSongs {
    return localSongs.where((song) => likedSongIds.contains(song.id)).toList();
  }

  Future<List<Song>> _getOrLoadLocalSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_local_songs');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      final songs = decoded
          .map((e) => Song(
        id: e['id'],
        title: e['title'],
        artist: e['artist'],
        image: null,
        filePath: e['filePath'],
        lyrics: '',
      ))
          .toList()
          .cast<Song>();
      setState(() {
        localSongs = songs;
      });
      _loadLocalSongsAndUpdateCache();
      return songs;
    } else {
      return await _loadLocalSongsAndUpdateCache();
    }
  }

  Future<List<Song>> _loadLocalSongsAndUpdateCache() async {
    bool permissionGranted = false;
    if (Platform.isAndroid) {
      int sdkInt = 0;
      try {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        sdkInt = deviceInfo.version.sdkInt;
      } catch (_) {
        sdkInt = 33; // fallback
      }
      if (sdkInt >= 33) {
        // Android 13+
        var audioStatus = await Permission.audio.request();
        if (audioStatus.isGranted) {
          permissionGranted = true;
        } else if (audioStatus.isPermanentlyDenied) {
          await openAppSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enable audio permission in settings')),
            );
          }
        }
      } else {
        // Android 12 and below
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          permissionGranted = true;
        } else if (storageStatus.isPermanentlyDenied) {
          await openAppSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enable storage permission in settings')),
            );
          }
        }
      }
    } else if (Platform.isIOS) {
      var permissionStatus = await Permission.mediaLibrary.request();
      if (permissionStatus.isGranted) {
        permissionGranted = true;
      } else if (permissionStatus.isPermanentlyDenied) {
        await openAppSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable media library permission in settings')),
          );
        }
      }
    } else {
      permissionGranted = true; // For other platforms, allow by default
    }

    if (!permissionGranted) {
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
        if (await File(song.data).exists()) {
          foundSongs.add(Song(
            id: song.id.toString(),
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            image: null,
            filePath: song.data,
            lyrics: '',
          ));
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final toCache = foundSongs
          .map((s) => {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'filePath': s.filePath,
      })
          .toList();
      await prefs.setString('cached_local_songs', jsonEncode(toCache));
    } catch (e) {
      print('Error loading local songs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load local songs: $e')),
        );
      }
    }
    setState(() {
      localSongs = foundSongs;
      _permissionDenied = false;
    });
    return foundSongs;
  }

  Future<void> pickMusicFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        List<Song> pickedSongs = [];
        for (var file in result.files) {
          if (file.path != null && await File(file.path!).exists()) {
            pickedSongs.add(Song(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: file.name,
              artist: 'Unknown Artist',
              image: null,
              filePath: file.path!,
              lyrics: '',
            ));
          }
        }
        setState(() {
          localSongs.addAll(pickedSongs);
        });
        final prefs = await SharedPreferences.getInstance();
        final toCache = localSongs
            .map((s) => {
          'id': s.id,
          'title': s.title,
          'artist': s.artist,
          'filePath': s.filePath,
        })
            .toList();
        await prefs.setString('cached_local_songs', jsonEncode(toCache));
      }
    } catch (e) {
      print('Error picking music files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick music files: $e')),
        );
      }
    }
  }

  List<Song> get allSongs => localSongs;

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
                child: QueryArtworkWidget(
                  id: int.tryParse(song.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget:
                  Icon(Icons.music_note, size: 40, color: cs.primary),
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
              child: QueryArtworkWidget(
                id: int.tryParse(song.id) ?? 0,
                type: ArtworkType.AUDIO,
                nullArtworkWidget:
                Icon(Icons.music_note, size: 50, color: cs.primary),
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
        itemBuilder: (context, index) =>
            _buildSongTile(songsToShow[index], songsToShow),
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
        itemBuilder: (context, index) =>
            _buildSongGridTile(songsToShow[index], songsToShow),
      );
    }
  }

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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: QueryArtworkWidget(
              id: int.tryParse(_currentSong!.id) ?? 0,
              type: ArtworkType.AUDIO,
              nullArtworkWidget:
              Icon(Icons.music_note, size: 32, color: cs.primary),
              artworkBorder: BorderRadius.circular(10),
              artworkHeight: 48,
              artworkWidth: 48,
              artworkFit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
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
                    style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _currentSong!.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () async {
              final idx = allSongs.indexWhere((s) => s.id == _currentSong!.id);
              if (idx > 0) {
                try {
                  setState(() {
                    _currentSong = allSongs[idx - 1];
                  });
                  if (await File(_currentSong!.filePath).exists()) {
                    await GlobalAudioPlayer.instance
                        .setFilePath(_currentSong!.filePath);
                  } else {
                    throw Exception("File not found: ${_currentSong!.filePath}");
                  }
                  await GlobalAudioPlayer.instance.play();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to play song: $e')),
                    );
                  }
                }
              }
            },
          ),
          StreamBuilder<bool>(
            stream: GlobalAudioPlayer.instance.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    size: 32),
                onPressed: () async {
                  try {
                    if (isPlaying) {
                      await GlobalAudioPlayer.instance.pause();
                    } else {
                      await GlobalAudioPlayer.instance.play();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to control playback: $e')),
                      );
                    }
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () async {
              final idx = allSongs.indexWhere((s) => s.id == _currentSong!.id);
              if (idx < allSongs.length - 1) {
                try {
                  setState(() {
                    _currentSong = allSongs[idx + 1];
                  });
                  if (await File(_currentSong!.filePath).exists()) {
                    await GlobalAudioPlayer.instance
                        .setFilePath(_currentSong!.filePath);
                  } else {
                    throw Exception("File not found: ${_currentSong!.filePath}");
                  }
                  await GlobalAudioPlayer.instance.play();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to play song: $e')),
                    );
                  }
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
              color: cs.onPrimary,
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
          IconButton(
            icon: Icon(Icons.add, color: cs.onPrimary),
            tooltip: 'Add music files',
            onPressed: pickMusicFile,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onPrimary),
            onSelected: (value) {
              if (value == 'name') {
                setState(() {
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
                        child: Center(
                            child: Text(
                                'Storage permission denied. Please enable it in settings.')),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    localSongs = snapshot.data ?? [];
                    final songsToShow = filterSongs(localSongs);
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
                    style: tt.bodyMedium?.copyWith(fontSize: 18),
                  ),
                )
                    : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Liked Songs',
                        style: tt.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...likedSongs.map(
                          (song) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: int.tryParse(song.id) ?? 0,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Icon(Icons.music_note,
                                size: 40, color: cs.primary),
                            artworkBorder: BorderRadius.circular(8),
                            artworkHeight: 50,
                            artworkWidth: 50,
                            artworkFit: BoxFit.cover,
                          ),
                        ),
                        title: Text(song.title, style: tt.bodyLarge),
                        subtitle: Text(
                          song.artist,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.favorite, color: cs.error),
                          onPressed: () => toggleLike(song.id),
                        ),
                        onTap: () => _onSongPlay(song, likedSongs),
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (context) => MusicShopPage(
                    // اگر MusicShopPage پارامتر ندارد، همین را نگه دار
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildMiniPlayer(),
            ),
          ],
        ),
      ),
      floatingActionButton: currentIndex == 2
          ? null
          : null, // اگر لازم شد
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // اگر از push برای رفتن به MusicShopPage استفاده می‌کنی:
    Future.microtask(() async {
      if (currentIndex == 2) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MusicShopPage()),
        );
        if (result is ShopSong) {
          setState(() {
            localSongs.add(Song(
              id: result.id,
              title: result.title,
              artist: result.artist,
              image: null,
              filePath: '', // اگر فایل دانلود شد، مسیر را قرار بده
              lyrics: '',
            ));
          });
        }
      }
    });
  }
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = GlobalAudioPlayer.instance;

  MyAudioHandler() {
    _notify();
    _player.playerStateStream.listen((state) {
      _notify();
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
    _player.currentIndexStream.listen((_) => _notify());
  }

  void _notify() {
    try {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        playing: playing,
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ?? AudioProcessingState.ready,
      ));
    } catch (e) {
      print("Error in MyAudioHandler _notify: $e");
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print("Error pausing audio: $e");
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print("Error stopping audio: $e");
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print("Error seeking audio: $e");
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      await _player.seekToNext();
    } catch (e) {
      print("Error skipping to next: $e");
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      await _player.seekToPrevious();
    } catch (e) {
      print("Error skipping to previous: $e");
    }
  }
}

class _CassetteDiscPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint discPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade800, Colors.grey.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
          Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2));
    final Paint centerPaint = Paint()..color = Colors.black;
    final Paint holePaint = Paint()..color = Colors.white;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, discPaint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 6, centerPaint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 16, holePaint);

    final Paint tapeHolePaint = Paint()..color = Colors.black.withOpacity(0.7);
    final double tapeHoleRadius = size.width / 10;
    canvas.drawCircle(
        Offset(size.width * 0.28, size.height * 0.7), tapeHoleRadius, tapeHolePaint);
    canvas.drawCircle(
        Offset(size.width * 0.72, size.height * 0.7), tapeHoleRadius, tapeHolePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> songs;
  final bool resumeInsteadOfRestart;
  const PlayerPage(
      {super.key,
        required this.song,
        required this.songs,
        this.resumeInsteadOfRestart = false});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = GlobalAudioPlayer.instance;
  bool isShuffling = false;
  bool isRepeating = false;
  int _currentIndex = 0;
  List<Song> _playlist = [];
  late AnimationController _discController;
  late bool _isPlaying;

  Widget? _cachedArtwork;

  @override
  void initState() {
    super.initState();

    _playlist = List.from(widget.songs);
    _currentIndex = _playlist.indexWhere((song) => song.id == widget.song.id);
    _discController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _isPlaying = _player.playing;

    // DO NOT use Theme.of(context) or anything that depends on inherited widgets here!
    // _cachedArtwork will be initialized in didChangeDependencies instead.

    bool? lastIsPlaying = _isPlaying;
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      if (lastIsPlaying != isPlaying) {
        lastIsPlaying = isPlaying;
        if (mounted) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
        if (isPlaying) {
          _discController.repeat();
        } else {
          _discController.stop();
        }
      }
      if (state.processingState == ProcessingState.completed) {
        _playNextSong();
      }
    });

    // Only play if not resuming
    if (!(widget.resumeInsteadOfRestart == true && _player.playing)) {
      _playSong(_playlist[_currentIndex]);
    } else if (_player.playing) {
      _discController.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to use Theme.of(context) and build artwork
    _cachedArtwork = _buildArtwork(_playlist[_currentIndex]);
  }

  Widget _buildArtwork(Song song) {
    final cs = Theme.of(context).colorScheme;
    return ClipOval(
      child: QueryArtworkWidget(
        id: int.tryParse(song.id) ?? 0,
        type: ArtworkType.AUDIO,
        nullArtworkWidget:
            Icon(Icons.music_note, size: 100, color: cs.primary),
        artworkBorder: BorderRadius.circular(105),
        artworkHeight: 210,
        artworkWidth: 210,
        artworkFit: BoxFit.cover,
      ),
    );
  }

  Future<void> _playSong(Song song) async {
    try {
      if (_player.playing) await _player.stop();
      // FIX: Only set file path if filePath is not empty and file exists
      if (song.filePath.isNotEmpty && await File(song.filePath).exists()) {
        await _player.setFilePath(song.filePath);
        setState(() {
          _cachedArtwork = _buildArtwork(song);
        });
        await _player.play();
        setState(() {
          _isPlaying = true;
        });
      } else {
        throw Exception("File not found: ${song.filePath}");
      }
    } catch (e) {
      print("Error playing song: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play the song: $e')),
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
      _currentIndex =
          (_currentIndex - 1) >= 0 ? _currentIndex - 1 : _playlist.length - 1;
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

  Widget _buildSoundClubDisc(Song song) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: AnimatedBuilder(
        animation: _discController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _discController.value * 2 * math.pi,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withOpacity(0.1),
                    cs.primary.withOpacity(0.2),
                    cs.primary.withOpacity(0.4),
                    cs.primary.withOpacity(0.7),
                  ],
                  stops: const [0.5, 0.7, 0.9, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _cachedArtwork,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 24, bottom: 12),
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
        size: const Size(double.infinity, 60),
        waveAmplitude: 12,
      ),
    );
  }

  @override
  void dispose() {
    _discController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final currentSong = _playlist[_currentIndex];

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(currentSong.title, style: tt.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onPrimary, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: cs.onPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildSoundClubDisc(currentSong),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  currentSong.title,
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  currentSong.artist,
                  style: tt.titleMedium?.copyWith(color: cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _buildWaveform(),
          StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: isShuffling ? Color(0xFFFFD700) : Colors.grey,
                ),
                onPressed: _toggleShuffle,
              ),

              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.skip_previous_rounded, color: cs.primary, size: 36),
                onPressed: _playPreviousSong,
              ),
              const SizedBox(width: 8),
              StreamBuilder<bool>(
                stream: _player.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return GestureDetector(
                    onTap: () async {
                      try {
                        if (isPlaying) {
                          await _player.pause();
                          _discController.stop();
                        } else {
                          await _player.play();
                          _discController.repeat();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to control playback: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.skip_next_rounded, color: cs.primary, size: 36),
                onPressed: _playNextSong,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.repeat,
                  color: isRepeating ? Color(0xFFFFD700) : Colors.grey,
                ),


                onPressed: () {
                  setState(() {
                    isRepeating = !isRepeating;
                    _player.setLoopMode(
                        isRepeating ? LoopMode.one : LoopMode.off);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Lyrics",
                style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SingleChildScrollView(
                child: Text(
                  currentSong.lyrics,
                  style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.85)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

