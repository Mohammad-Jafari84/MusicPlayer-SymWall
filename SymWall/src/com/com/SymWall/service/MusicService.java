package com.com.SymWall.service;

import com.com.SymWall.model.Music;
import com.com.SymWall.repository.MusicRepository;

import java.util.List;

public class MusicService {
    private final MusicRepository musicRepository;

    public MusicService(MusicRepository musicRepository) {
        this.musicRepository = musicRepository;
    }

    public boolean addMusic(Music music) {
        return musicRepository.save(music);
    }

    public Music getMusicById(String id) {
        return musicRepository.findById(id);
    }

    public List<Music> getAllMusic() {
        return musicRepository.findAll();
    }

    public boolean updateMusic(Music music) {
        return musicRepository.update(music);
    }

    public boolean deleteMusic(String id) {
        return musicRepository.deleteById(id);
    }
}

