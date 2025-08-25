import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Playlist {
  List<Song> songs;

  Playlist({required this.songs});
}

class Song {
  String id;

  Song({required this.id});
}

Widget buildPlaylistCover(Playlist playlist, ColorScheme cs) {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: cs.primary.withOpacity(0.1),
    ),
    clipBehavior: Clip.antiAlias,
    child: playlist.songs.isNotEmpty
      ? QueryArtworkWidget(
          id: int.tryParse(playlist.songs.first.id) ?? 0,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: Icon(Icons.queue_music, color: cs.primary, size: 40),
          artworkBorder: BorderRadius.zero,
          artworkFit: BoxFit.cover,
        )
      : Icon(Icons.queue_music, color: cs.primary, size: 40),
  );
}
