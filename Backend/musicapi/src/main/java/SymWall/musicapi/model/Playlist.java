package SymWall.musicapi.model;



import java.util.ArrayList;
import java.util.List;

public class Playlist {
    private String id;
    private String name;
    private List<Music> songs;

    public Playlist(String name) {
        this.name = name;
        this.songs = new ArrayList<>();
        this.id = java.util.UUID.randomUUID().toString();
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<Music> getSongs() {
        return new ArrayList<>(songs);
    }

    public void addSong(Music music) {
        if (!songs.contains(music)) {
            songs.add(music);
        }
    }

    public void removeSong(Music music) {
        songs.remove(music);
    }

    public void clear() {
        songs.clear();
    }

    public int getSize() {
        return songs.size();
    }
}
