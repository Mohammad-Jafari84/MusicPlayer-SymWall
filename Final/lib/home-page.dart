import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'music-shop-page.dart';
import 'theme.dart';
import 'userProfile.dart';

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
          image: null,
          filePath: song.data,
          lyrics: '',
        ));
      }
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
        child: IndexedStack(
          index: currentIndex,
          children: [
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
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerPage(song: song, songs: customSongs),
                          ),
                        ),
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
                  },
                ),
              ],
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerPage(
                          song: song,
                          songs: likedSongs,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    _playSong(_playlist[_currentIndex]);
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
      print('Error playing song: $e');
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