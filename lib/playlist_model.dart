import 'home-page.dart';

class Playlist {
  String name;
  List<Song> songs;

  Playlist({required this.name, required this.songs});

  Map<String, dynamic> toMap() => {
    'name': name,
    'songs': songs.map((s) => s.toMap()).toList(),
  };

  factory Playlist.fromMap(Map<String, dynamic> map) => Playlist(
    name: map['name'],
    songs: (map['songs'] as List).map((e) => Song.fromMap(e)).toList(),
  );
}