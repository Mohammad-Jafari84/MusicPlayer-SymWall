package com.com.SymWall.model;


import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MusicPlayer {
    private List<Music> playlist;
    private int currentIndex;
    private boolean isShuffle;
    private boolean isRepeat;

    public MusicPlayer(List<Music> playlist) {
        this.playlist = new ArrayList<>(playlist);
        this.currentIndex = 0;
        this.isShuffle = false;
        this.isRepeat = false;
    }

    public void toggleShuffle() {
        isShuffle = !isShuffle;
        if (isShuffle) {
            Collections.shuffle(playlist);
        } else {

        }
    }

    public void toggleRepeat() {
        isRepeat = !isRepeat;
    }

    public void play() {
        getCurrentMusic().play();
    }

    public void pause() {
        getCurrentMusic().pause();
    }

    public Music getCurrentMusic() {
        return playlist.get(currentIndex);
    }

    public void next() {
        if (currentIndex < playlist.size() - 1) {
            currentIndex++;
        } else if (isRepeat) {
            currentIndex = 0;
        }
        play();
    }

    public void previous() {
        if (currentIndex > 0) {
            currentIndex--;
        } else if (isRepeat) {
            currentIndex = playlist.size() - 1;
        }
        play();
    }
}
