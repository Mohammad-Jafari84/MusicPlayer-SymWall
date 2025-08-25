import 'package:SymWall/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
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
import 'package:azlistview/azlistview.dart';
import 'music-shop-page.dart';
import 'theme.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

enum SongViewType { list, grid }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeProvider.isDarkMode
              ? ThemeMode.dark
              : themeProvider.isLightMode
              ? ThemeMode.light
              : themeProvider.isGreenMode
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class Song extends ISuspensionBean {
  final String id;
  final String title;
  final String artist;
  final String? image;
  final String filePath;
  final String lyrics;
  DateTime? lastPlayed;
  String tag;
  int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.image,
    required this.filePath,
    required this.lyrics,
    this.tag = '',
    this.lastPlayed,
    this.playCount = 0,
  });

  @override
  String getSuspensionTag() => tag;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'image': image,
    'filePath': filePath,
    'lyrics': lyrics,
    'lastPlayed': lastPlayed?.toIso8601String(),
    'tag': tag,
    'playCount': playCount,
  };

  factory Song.fromMap(Map<String, dynamic> map) => Song(
    id: map['id'],
    title: map['title'],
    artist: map['artist'],
    image: map['image'],
    filePath: map['filePath'],
    lyrics: map['lyrics'],
    lastPlayed:
        map['lastPlayed'] != null ? DateTime.parse(map['lastPlayed']) : null,
    tag: map['tag'] ?? '',
    playCount: map['playCount'] ?? 0,
  );
}

class Playlist {
  String id;
  String name;
  String? description;
  List<Song> songs;
  DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.songs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'songs': songs.map((s) => s.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    songs: (json['songs'] as List).map((s) => Song.fromMap(s)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class GlobalAudioPlayer {
  static final AudioPlayer instance = AudioPlayer();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
  bool _miniPlayerShuffling = false;
  List<Song> _miniPlayerPlaylist = [];
  int _miniPlayerCurrentIndex = 0;
  final ScrollController _azScrollController = ScrollController();
  List<Song> downloadedSongs = [];
  List<Song> recentlyPlayed = [];
  List<Playlist> playlists = [];
  String _sortType = 'name'; // Add this to track current sort type

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
    _miniPlayerPlaylist = localSongs;
    _miniPlayerCurrentIndex = 0;
    _miniPlayerShuffling = false;
    GlobalAudioPlayer.instance.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleMiniPlayerNext();
      }
    });
    _loadPlaylists();

    // Load play counts after songs are loaded
    _localSongsFuture?.then((_) => _loadPlayCounts());
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

  List<Song> get likedSongs {
    return localSongs.where((song) => likedSongIds.contains(song.id)).toList();
  }


  Future<void> saveRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'recently_played',
      jsonEncode(recentlyPlayed.map((s) => s.toMap()).toList()),
    );
  }

  Future<List<Song>> _getOrLoadLocalSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_local_songs');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      final songs =
          decoded
              .map(
                (e) => Song(
                  id: e['id'],
                  title: e['title'],
                  artist: e['artist'],
                  image: null,
                  filePath: e['filePath'],
                  lyrics: e['lyrics'] ?? '',
                ),
              )
              .toList()
              .cast<Song>();
      setState(() {
        localSongs = songs;
      });
      await _loadPlayCounts(); // <-- Load play counts after loading songs
      _loadLocalSongsAndUpdateCache();
      return songs;
    } else {
      final loadedSongs = await _loadLocalSongsAndUpdateCache();
      await _loadPlayCounts(); // <-- Load play counts after loading songs
      return loadedSongs;
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
        sdkInt = 33;
      }
      if (sdkInt >= 33) {
        var audioStatus = await Permission.audio.request();
        if (audioStatus.isGranted) {
          permissionGranted = true;
        } else if (audioStatus.isPermanentlyDenied) {
          await openAppSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable audio permission in settings'),
              ),
            );
          }
        }
      } else {
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          permissionGranted = true;
        } else if (storageStatus.isPermanentlyDenied) {
          await openAppSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable storage permission in settings'),
              ),
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
            const SnackBar(
              content: Text(
                'Please enable media library permission in settings',
              ),
            ),
          );
        }
      }
    } else {
      permissionGranted = true;
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
          foundSongs.add(
            Song(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist ?? 'Unknown Artist',
              image: null,
              filePath: song.data,
              lyrics: '',
            ),
          );
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final toCache =
          foundSongs
              .map(
                (s) => {
                  'id': s.id,
                  'title': s.title,
                  'artist': s.artist,
                  'filePath': s.filePath,
                  'lyrics': s.lyrics,
                },
              )
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

  void _addToRecentlyPlayed(Song song) {
    setState(() {
      recentlyPlayed.removeWhere((s) => s.id == song.id);
      song.lastPlayed = DateTime.now();
      recentlyPlayed.insert(0, song);
      if (recentlyPlayed.length > 20) {
        recentlyPlayed = recentlyPlayed.sublist(0, 20);
      }
    });
  }

  Future<void> pickMusicFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        List<Song> pickedSongs = [];
        String cleanPath(String path) {
          if (path.startsWith('file://')) {
            return path.replaceFirst('file://', '');
          }
          return path;
        }

        for (var file in result.files) {
          if (file.path != null && await File(file.path!).exists()) {
            pickedSongs.add(
              Song(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: file.name,
                artist: 'Unknown Artist',
                image: null,
                filePath: file.path!,
                lyrics: '',
              ),
            );
          }
        }
        setState(() {
          localSongs.addAll(pickedSongs);
        });
        final prefs = await SharedPreferences.getInstance();
        final toCache =
            localSongs
                .map(
                  (s) => {
                    'id': s.id,
                    'title': s.title,
                    'artist': s.artist,
                    'filePath': s.filePath,
                  },
                )
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

  Future<void> _loadPlayCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final playCountsJson = prefs.getString('play_counts') ?? '{}';
    final Map<String, dynamic> playCounts = json.decode(playCountsJson);

    setState(() {
      for (var song in localSongs) {
        if (playCounts.containsKey(song.id)) {
          song.playCount = playCounts[song.id];
        }
      }
    });
  }

  Future<void> _savePlayCount(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final playCountsJson = prefs.getString('play_counts') ?? '{}';
    Map<String, dynamic> playCounts = json.decode(playCountsJson);
    playCounts[song.id] = song.playCount;
    await prefs.setString('play_counts', json.encode(playCounts));
  }

  void _onSongPlay(Song song, List<Song> playlist) async {
    setState(() {
      song.playCount++;
      _currentSong = song;
      _isPlaying = true;
      _miniPlayerPlaylist = List<Song>.from(playlist);
      _miniPlayerCurrentIndex = playlist.indexWhere((s) => s.id == song.id);
      _miniPlayerShuffling = isShufflingGlobal;
    });
    await _savePlayCount(song);

    // If sorted by play count, re-sort after play
    if (_sortType == 'playCount') {
      setState(() {
        localSongs.sort((a, b) => b.playCount.compareTo(a.playCount));
      });
    }

    _addToRecentlyPlayed(song);
    _playMiniPlayerSong(force: true);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PlayerPage(
              song: song,
              songs: playlist,
              localSongs: localSongs,
              resumeInsteadOfRestart: true,
              onShuffleChanged: (shuffling) {
                setState(() {
                  _miniPlayerShuffling = shuffling;
                });
              },
              onSongChanged: (newSong) {
                setState(() {
                  _currentSong = newSong;
                  _miniPlayerCurrentIndex = playlist.indexWhere(
                    (s) => s.id == newSong.id,
                  );
                });
              },
            ),
      ),
    );
  }

  bool get isShufflingGlobal => _miniPlayerShuffling;

  void _handleMiniPlayerNext() {
    setState(() {
      if (_miniPlayerPlaylist.isEmpty) return;
      if (_miniPlayerShuffling) {
        final possible = List<Song>.from(_miniPlayerPlaylist)
          ..removeAt(_miniPlayerCurrentIndex);
        if (possible.isNotEmpty) {
          final nextSong = (possible..shuffle()).first;
          _miniPlayerCurrentIndex = _miniPlayerPlaylist.indexWhere(
            (s) => s.id == nextSong.id,
          );
          _currentSong = nextSong;
        }
      } else {
        _miniPlayerCurrentIndex =
            (_miniPlayerCurrentIndex + 1) % _miniPlayerPlaylist.length;
        _currentSong = _miniPlayerPlaylist[_miniPlayerCurrentIndex];
      }
      _playMiniPlayerSong(force: true);
    });
  }

  void _handleMiniPlayerPrevious() {
    setState(() {
      if (_miniPlayerPlaylist.isEmpty) return;
      if (_miniPlayerShuffling) {
        final possible = List<Song>.from(_miniPlayerPlaylist)
          ..removeAt(_miniPlayerCurrentIndex);
        if (possible.isNotEmpty) {
          final prevSong = (possible..shuffle()).first;
          _miniPlayerCurrentIndex = _miniPlayerPlaylist.indexWhere(
            (s) => s.id == prevSong.id,
          );
          _currentSong = prevSong;
        }
      } else {
        _miniPlayerCurrentIndex =
            (_miniPlayerCurrentIndex - 1) >= 0
                ? _miniPlayerCurrentIndex - 1
                : _miniPlayerPlaylist.length - 1;
        _currentSong = _miniPlayerPlaylist[_miniPlayerCurrentIndex];
      }
      _playMiniPlayerSong(force: true);
    });
  }

  Future<void> _playMiniPlayerSong({bool force = false}) async {
    try {
      if (_currentSong == null) return;
      if (_currentSong!.filePath.isNotEmpty &&
          await File(_currentSong!.filePath).exists()) {
        await GlobalAudioPlayer.instance.setFilePath(_currentSong!.filePath);
        await GlobalAudioPlayer.instance.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play song: $e')));
      }
    }
  }

  List<Song> _prepareAZSongs(List<Song> songs) {
    for (var song in songs) {
      String tag = '';
      if (song.title.isNotEmpty) {
        tag = song.title[0].toUpperCase();
        if (!RegExp(r'[A-Z]').hasMatch(tag)) tag = '#';
      } else {
        tag = '#';
      }
      song.tag = tag;
    }
    SuspensionUtil.sortListBySuspensionTag(songs);
    SuspensionUtil.setShowSuspensionStatus(songs);
    return songs;
  }

  Widget _buildAZSongList(List<Song> songsToShow) {
    final cs = Theme.of(context).colorScheme;
    final azSongs = _prepareAZSongs(List<Song>.from(songsToShow));
    return AzListView(
      data: azSongs,
      itemCount: azSongs.length,
      itemBuilder: (context, index) {
        final song = azSongs[index];
        return _buildSongTile(song, azSongs);
      },
      indexBarData:
          SuspensionUtil.getTagIndexList(
            azSongs,
          ).map((e) => e.toString()).toList(),
      indexBarOptions: IndexBarOptions(
        needRebuild: true,
        selectTextStyle: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          shadows: [
            Shadow(
              color: cs.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(2, 2),
            ),
          ],
        ),
        selectItemDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary.withOpacity(0.25),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.18),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        indexHintAlignment: Alignment.centerRight,
        indexHintOffset: Offset(-20, 0),
      ),
      physics: const ClampingScrollPhysics(),
      susItemBuilder:
          (context, tag) => Container(
            height: 28,
            color: cs.surface.withOpacity(0.97),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              tag.toString(),
              style: TextStyle(
                fontSize: 16,
                color: cs.primary,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: cs.primary.withOpacity(0.18),
                    blurRadius: 6,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSongTile(Song song, List<Song> playlist) {
    final cs = Theme.of(context).colorScheme;
    final isLiked = likedSongIds.contains(song.id);
    final isPlaying = _currentSong?.id == song.id;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isPlaying)
              BoxShadow(
                color: cs.primary.withOpacity(0.25),
                blurRadius: 18,
                spreadRadius: 2,
                offset: Offset(0, 6),
              ),
            BoxShadow(
              color: cs.onSurface.withOpacity(0.07),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Card(
          color: isPlaying
              ? cs.primary.withOpacity(0.13)
              : cs.surface,
          elevation: isPlaying ? 10 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isPlaying ? cs.primary : cs.onSurface.withOpacity(0.13),
              width: isPlaying ? 2.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _onSongPlay(song, playlist),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isPlaying)
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                cs.primary.withOpacity(0.18),
                                cs.primary.withOpacity(0.07),
                                Colors.transparent,
                              ],
                              stops: const [0.6, 0.9, 1.0],
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isPlaying ? 54 : 48,
                        height: isPlaying ? 54 : 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (isPlaying)
                              BoxShadow(
                                color: cs.primary.withOpacity(0.18),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: QueryArtworkWidget(
                            id: int.tryParse(song.id) ?? 0,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Icon(
                              Icons.music_note,
                              size: 32,
                              color: cs.primary,
                            ),
                            artworkBorder: BorderRadius.circular(24),
                            artworkHeight: 48,
                            artworkWidth: 48,
                            artworkFit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_outline, size: 12, color: cs.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${song.playCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 22,
                    ),
                    onPressed: () => toggleLike(song.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongGridTile(Song song, List<Song> playlist) {
    final cs = Theme.of(context).colorScheme;
    final isLiked = likedSongIds.contains(song.id);
    final isPlaying = _currentSong?.id == song.id;
    return InkWell(
      onTap: () => _onSongPlay(song, playlist),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? cs.primary : cs.onSurface.withOpacity(0.15),
            width: isPlaying ? 2.5 : 1,
          ),
          boxShadow:
              isPlaying
                  ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.18),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isPlaying)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cs.primary.withOpacity(0.18),
                          cs.primary.withOpacity(0.09),
                          cs.primary.withOpacity(0.01),
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: QueryArtworkWidget(
                    id: int.tryParse(song.id) ?? 0,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Icon(
                      Icons.music_note,
                      size: 50,
                      color: cs.primary,
                    ),
                    artworkBorder: BorderRadius.circular(12),
                    artworkHeight: 90,
                    artworkWidth: 90,
                    artworkFit: BoxFit.cover,
                  ),
                ),
              ],
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
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.7),
              ),
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
      return _buildAZSongList(songsToShow);
    } else {
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: songsToShow.length,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
        ),
        itemBuilder:
            (context, index) =>
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
          colors: [cs.primary.withOpacity(0.12), Colors.white],
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
              nullArtworkWidget: Icon(
                Icons.music_note,
                size: 32,
                color: cs.primary,
              ),
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
                    builder:
                        (_) => PlayerPage(
                          song: _currentSong!,
                          songs: _miniPlayerPlaylist,
                          localSongs: localSongs,
                          resumeInsteadOfRestart: true,
                          onShuffleChanged: (shuffling) {
                            setState(() {
                              _miniPlayerShuffling = shuffling;
                            });
                          },
                          onSongChanged: (newSong) {
                            setState(() {
                              _currentSong = newSong;
                              _miniPlayerCurrentIndex = _miniPlayerPlaylist
                                  .indexWhere((s) => s.id == newSong.id);
                            });
                          },
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _currentSong!.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: _handleMiniPlayerPrevious,
          ),
          StreamBuilder<bool>(
            stream: GlobalAudioPlayer.instance.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 32,
                ),
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
                        SnackBar(content: Text('Failed to play/pause: $e')),
                      );
                    }
                  }
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _handleMiniPlayerNext,
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
            icon: Icon(Icons.refresh, color: Colors.grey),
            tooltip: 'Reload songs',
            onPressed: () async {
              await _loadLocalSongsAndUpdateCache();
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(
              _songViewType == SongViewType.list ? Icons.grid_view : Icons.list,
              color: Colors.grey,
            ),
            tooltip: 'Toggle view',
            onPressed: () {
              setState(() {
                _songViewType =
                    _songViewType == SongViewType.list
                        ? SongViewType.grid
                        : SongViewType.list;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.grey),
            tooltip: 'Add music files',
            onPressed: pickMusicFile,
          ),
          IconButton(
            icon: Icon(Icons.brightness_6, color: Colors.grey),
            tooltip: 'Change theme',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).cycleTheme();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              setState(() {
                _sortType = value; // Track sort type
                if (value == 'name') {
                  localSongs.sort((a, b) => a.title.compareTo(b.title));
                } else if (value == 'playCount') {
                  localSongs.sort((a, b) => b.playCount.compareTo(a.playCount));
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Sort by name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'playCount',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline),
                    SizedBox(width: 8),
                    Text('Most played'),
                  ],
                ),
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Recent'),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music),
            label: 'Playlists',
          ),
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
                            'Storage permission denied. Please enable it in settings.',
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (localSongs.isEmpty && snapshot.data != null) {
                      localSongs = snapshot.data!;
                    }
                    final allSongsSet = <String, Song>{};
                    for (var s in localSongs) {
                      allSongsSet[s.id] = s;
                    }
                    for (var s in downloadedSongs) {
                      allSongsSet[s.id] = s;
                    }
                    final songsToShow = filterSongs(
                      allSongsSet.values.toList(),
                    );
                    if (songsToShow.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No music found.')),
                      );
                    }
                    return Column(
                      children: [
                        if (downloadedSongs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Downloaded Songs',
                              style: tt.titleLarge,
                            ),
                          ),
                        if (downloadedSongs.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: downloadedSongs.length,
                              itemBuilder: (context, index) {
                                final song = downloadedSongs[index];
                                return _buildSongGridTile(
                                  song,
                                  downloadedSongs,
                                );
                              },
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadLocalSongsAndUpdateCache,
                            child: _buildSongList(songsToShow),
                          ),
                        ),
                      ],
                    );
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
                                nullArtworkWidget: Icon(
                                  Icons.music_note,
                                  size: 32,
                                  color: cs.primary,
                                ),
                                artworkBorder: BorderRadius.circular(8),
                                artworkHeight: 48,
                                artworkWidth: 48,
                                artworkFit: BoxFit.cover,
                              ),
                            ),
                            title: Text(song.title, style: tt.bodyLarge),
                            subtitle: Text(
                              song.artist,
                              style: tt.bodyMedium?.copyWith(color: cs.primary),
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
                MusicShopPage(key: UniqueKey()),
                recentlyPlayed.isEmpty
                    ? Center(
                      child: Text(
                        'No recently played songs',
                        style: tt.bodyMedium?.copyWith(fontSize: 18),
                      ),
                    )
                    : ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Recently Played', style: tt.titleLarge),
                        ),
                        ...recentlyPlayed.map(
                          (song) => _buildSongTile(song, recentlyPlayed),
                        ),
                      ],
                    ),
                _buildPlaylistsView(),
              ],
            ),
            Align(alignment: Alignment.bottomCenter, child: _buildMiniPlayer()),
          ],
        ),
      ),
    );
  }

  Future<void> addDownloadedSongFromShop(Map<String, dynamic> songMap) async {
    final song = Song(
      id: songMap['id'],
      title: songMap['title'],
      artist: songMap['artist'],
      image: songMap['image'],
      filePath: songMap['filePath'],
      lyrics: songMap['lyrics'] ?? '',
    );
    setState(() {
      if (!downloadedSongs.any((s) => s.id == song.id)) {
        downloadedSongs.add(song);
      }
      if (!localSongs.any((s) => s.id == song.id)) {
        localSongs.add(song);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${song.title} added to your library!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('playlists');
    if (playlistsJson != null) {
      final List decoded = jsonDecode(playlistsJson);
      setState(() {
        playlists = decoded.map((p) => Playlist.fromJson(p)).toList();
      });
    }
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'playlists',
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final playlist = Playlist(
                  id: DateTime.now().toString(),
                  name: nameController.text,
                  description: descController.text,
                  songs: [],
                  createdAt: DateTime.now(),
                );
                setState(() {
                  playlists.add(playlist);
                });
                _savePlaylists();
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddSongsDialog(Playlist playlist) {
    String songSearch = '';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredSongs = songSearch.isEmpty
                ? localSongs
                : localSongs.where((song) =>
                    song.title.toLowerCase().contains(songSearch.toLowerCase()) ||
                    song.artist.toLowerCase().contains(songSearch.toLowerCase())
                  ).toList();
            return Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    AppBar(
                      title: Text('Add Songs'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Done'),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search songs...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            songSearch = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          final isInPlaylist = playlist.songs.any((s) => s.id == song.id);
                          return ListTile(
                            leading: QueryArtworkWidget(
                              id: int.tryParse(song.id) ?? 0,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Icon(Icons.music_note),
                              artworkHeight: 40,
                              artworkWidth: 40,
                            ),
                            title: Text(song.title),
                            subtitle: Text(song.artist),
                            trailing: Checkbox(
                              value: isInPlaylist,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true && !isInPlaylist) {
                                    playlist.songs.add(song);
                                  } else if (value == false && isInPlaylist) {
                                    playlist.songs.removeWhere((s) => s.id == song.id);
                                  }
                                });
                                setState(() {}); // Update main state
                                _savePlaylists(); // Save changes
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlaylistDetailDialog(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Scaffold(
            appBar: AppBar(
              title: Text(playlist.name),
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showAddSongsDialog(playlist),
                ),
              ],
            ),
            body: Column(
              children: [
                // Playlist header with artwork
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: playlist.songs.isNotEmpty
                          ? QueryArtworkWidget(
                              id: int.tryParse(playlist.songs.first.id) ?? 0,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Icon(Icons.queue_music),
                              artworkBorder: BorderRadius.zero,
                              artworkFit: BoxFit.cover,
                            )
                          : Icon(Icons.queue_music),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${playlist.songs.length} songs',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Songs list
                Expanded(
                  child: playlist.songs.isEmpty
                    ? Center(child: Text('No songs in playlist'))
                    : ListView.builder(
                        itemCount: playlist.songs.length,
                        itemBuilder: (context, index) {
                          final song = playlist.songs[index];
                          return ListTile(
                            leading: QueryArtworkWidget(
                              id: int.tryParse(song.id) ?? 0,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Icon(Icons.music_note),
                              artworkHeight: 40,
                              artworkWidth: 40,
                            ),
                            title: Text(song.title),
                            subtitle: Text(song.artist),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setDialogState(() {
                                  playlist.songs.removeAt(index);
                                });
                                setState(() {}); // Update main state
                                _savePlaylists(); // Save changes
                              },
                            ),
                            onTap: () => _onSongPlay(song, playlist.songs),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPlaylistDialog(Playlist playlist) {
    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(text: playlist.description ?? '');
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            child: Text('Save'),
            onPressed: () {
              setState(() {
                playlist.name = nameController.text;
                playlist.description = descController.text;
              });
              _savePlaylists();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _deletePlaylist(Playlist playlist) {
    setState(() {
      playlists.removeWhere((p) => p.id == playlist.id);
    });
    _savePlaylists();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist "${playlist.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              playlists.add(playlist);
            });
            _savePlaylists();
          },
        ),
      ),
    );
  }

  Widget _buildPlaylistsView() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search playlists...',
              prefixIcon: Icon(Icons.search, color: cs.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: cs.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                // Implement playlist search here if needed
              });
            },
          ),
        ),

        // Create Playlist Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _showCreatePlaylistDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: cs.onPrimary),
                SizedBox(width: 8),
                Text('Create New Playlist',
                  style: tt.titleMedium?.copyWith(color: cs.onPrimary)),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Playlists List
        Expanded(
          child: playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue_music,
                        size: 64,
                        color: cs.primary.withOpacity(0.5)),
                      SizedBox(height: 16),
                      Text(
                        'No playlists yet',
                        style: tt.titleMedium?.copyWith(
                          color: cs.primary.withOpacity(0.7)
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create your first playlist!',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.6)
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withOpacity(0.1),
                            cs.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: cs.primary.withOpacity(0.1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: playlist.songs.isNotEmpty
                            ? QueryArtworkWidget(
                                id: int.tryParse(playlist.songs.first.id) ?? 0,
                                type: ArtworkType.AUDIO,
                                nullArtworkWidget: Icon(Icons.queue_music, color: cs.primary, size: 30),
                                artworkBorder: BorderRadius.zero,
                                artworkFit: BoxFit.cover,
                              )
                            : Icon(Icons.queue_music, color: cs.primary, size: 30),
                        ),
                        title: Text(playlist.name,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                        subtitle: Text('${playlist.songs.length} songs',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary)),
                        trailing: PopupMenuButton(
                          icon: Icon(Icons.more_vert, color: cs.primary),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: ListTile(
                                leading: Icon(Icons.add, color: cs.primary),
                                title: Text('Add Songs'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () => Future.delayed(
                                Duration(seconds: 0),
                                () => _showAddSongsDialog(playlist),
                              ),
                            ),
                            PopupMenuItem(
                              child: ListTile(
                                leading: Icon(Icons.edit, color: cs.primary),
                                title: Text('Rename'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () => Future.delayed(
                                Duration(seconds: 0),
                                () => _showEditPlaylistDialog(playlist),
                              ),
                            ),
                            PopupMenuItem(
                              child: ListTile(
                                leading: Icon(Icons.delete, color: cs.error),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () => _deletePlaylist(playlist),
                            ),
                          ],
                        ),
                        onTap: () => _showPlaylistDetailDialog(playlist),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          playing: playing,
          processingState:
              {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState] ??
              AudioProcessingState.ready,
        ),
      );
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
    final Paint discPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.grey.shade800, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromCircle(
              center: size.center(Offset.zero),
              radius: size.width / 2,
            ),
          );
    final Paint centerPaint = Paint()..color = Colors.black;
    final Paint holePaint = Paint()..color = Colors.white;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, discPaint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 6, centerPaint);
    canvas.drawCircle(size.center(Offset.zero), size.width / 16, holePaint);

    final Paint tapeHolePaint = Paint()..color = Colors.black.withOpacity(0.7);
    final double tapeHoleRadius = size.width / 10;
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.7),
      tapeHoleRadius,
      tapeHolePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.7),
      tapeHoleRadius,
      tapeHolePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> songs;
  final List<Song> localSongs;
  final bool resumeInsteadOfRestart;
  final void Function(bool shuffling)? onShuffleChanged;
  final void Function(Song)? onSongChanged;

  const PlayerPage({
    super.key,
    required this.song,
    required this.songs,
    this.resumeInsteadOfRestart = false,
    required this.localSongs,
    this.onSongChanged,
    this.onShuffleChanged,
  });

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
    _playSong(_playlist[_currentIndex]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedArtwork = _buildArtwork(_playlist[_currentIndex]);
  }

  Widget _buildArtwork(Song song) {
    final cs = Theme.of(context).colorScheme;
    return ClipOval(
      child: QueryArtworkWidget(
        id: int.tryParse(song.id) ?? 0,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Icon(Icons.music_note, size: 100, color: cs.primary),
        artworkBorder: BorderRadius.circular(105),
        artworkHeight: 210,
        artworkWidth: 210,
        artworkFit: BoxFit.cover,
      ),
    );
  }

  Future<void> _pasteLyrics() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null && clipboardData!.text!.trim().isNotEmpty) {
      setState(() {
        final oldSong = _playlist[_currentIndex];
        final updatedSong = Song(
          id: oldSong.id,
          title: oldSong.title,
          artist: oldSong.artist,
          image: oldSong.image,
          filePath: oldSong.filePath,
          lyrics: clipboardData.text!.trim(),
          tag: oldSong.tag,
          lastPlayed: oldSong.lastPlayed,
        );
        _playlist[_currentIndex] = updatedSong;
        final localIndex = widget.localSongs.indexWhere((s) => s.id == updatedSong.id);
        if (localIndex != -1) {
          widget.localSongs[localIndex] = updatedSong;
        }
      });

      // Save updated localSongs to cache
      final prefs = await SharedPreferences.getInstance();
      final toCache = widget.localSongs
          .map((s) => {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'filePath': s.filePath,
        'lyrics': s.lyrics,
      })
          .toList();
      await prefs.setString('cached_local_songs', jsonEncode(toCache));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lyrics pasted!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clipboard is empty.')),
      );
    }
  }

  Future<void> _playSong(Song song) async {
    try {
      final newIndex = _playlist.indexWhere((s) => s.id == song.id);
      if (newIndex == -1) return;
      setState(() {
        _currentIndex = newIndex;
        _cachedArtwork = _buildArtwork(song);
      });
      widget.onSongChanged?.call(song);
      if (_player.playing) await _player.stop();
      if (song.filePath.isNotEmpty && await File(song.filePath).exists()) {
        await _player.setFilePath(song.filePath);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play the song: $e')));
      }
    }
  }

  void _playNextSong() {
    if (_playlist.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    final nextSong = _playlist[nextIndex];
    _playSong(nextSong);
  }

  void _playPreviousSong() {
    if (_playlist.isEmpty) return;
    final prevIndex =
        (_currentIndex - 1) >= 0 ? _currentIndex - 1 : _playlist.length - 1;
    final prevSong = _playlist[prevIndex];
    _playSong(prevSong);
  }

  void _toggleShuffle() {
    setState(() {
      isShuffling = !isShuffling;
      widget.onShuffleChanged?.call(isShuffling);
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
                    cs.primary.withOpacity(0.18),
                    cs.primary.withOpacity(0.09),
                    cs.primary.withOpacity(0.01),
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
              child: Center(child: _cachedArtwork),
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
          heightPercentages: [0.60, 0.66],
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
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cs.onPrimary,
            size: 32,
          ),
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
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
          AnimatedOpacity(
            opacity: _isPlaying ? 1.0 : 0.0,
            duration: Duration(milliseconds: 400),
            child: _buildWaveform(),
          ),
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
                      onSeek: (pos) => _player.seek(pos),
                      baseBarColor: cs.onSurface.withOpacity(0.13),
                      progressBarColor: cs.primary,
                      thumbColor: cs.primary,
                      timeLabelTextStyle: tt.bodySmall,
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
                  color: isShuffling ? cs.primary : Colors.grey,
                ),
                onPressed: _toggleShuffle,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: cs.primary,
                  size: 36,
                ),
                onPressed: _playPreviousSong,
              ),
              const SizedBox(width: 8),
              StreamBuilder<bool>(
                stream: _player.playingStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: cs.primary,
                      size: 36,
                    ),
                    onPressed: () async {
                      if (isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.skip_next_rounded,
                  color: cs.primary,
                  size: 36,
                ),
                onPressed: _playNextSong,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.repeat,
                  color: isRepeating ? cs.primary : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    isRepeating = !isRepeating;
                    _player.setLoopMode(
                      isRepeating ? LoopMode.one : LoopMode.off,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lyrics",
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: Icon(Icons.paste, size: 18),
                  label: Text("Paste Lyrics"),
                  onPressed: _pasteLyrics,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SingleChildScrollView(
                child: Text(
                  currentSong.lyrics.isNotEmpty
                      ? currentSong.lyrics
                      : "No lyrics available.",
                  style: tt.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
