package com.com.SymWall.repository;

import com.com.SymWall.model.Music;
import com.com.SymWall.util.DB;

import java.sql.*;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

public class MusicRepository {

    public boolean save(Music music) {
        String sql = "INSERT INTO music (id, name, singer, duration, filePath) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, music.getId());
            stmt.setString(2, music.getName());
            stmt.setString(3, music.getSinger());
            stmt.setLong(4, music.getDuration().toMillis());
            stmt.setString(5, music.getFilePath());

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean update(Music music) {
        String sql = "UPDATE music SET name = ?, singer = ?, duration = ?, filePath = ?, likes = ? WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, music.getName());
            stmt.setString(2, music.getSinger());
            stmt.setLong(3, music.getDuration().toMillis());
            stmt.setString(4, music.getFilePath());
            stmt.setInt(5, music.getLikes());
            stmt.setString(6, music.getId());

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }


    public Music findById(String id) {
        String sql = "SELECT * FROM music WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                Music music = new Music(
                        rs.getString("name"),
                        rs.getString("singer"),
                        Duration.ofMillis(rs.getLong("duration")),
                        rs.getString("filePath")
                );
                return music;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<Music> findAll() {
        String sql = "SELECT * FROM music";
        List<Music> musics = new ArrayList<>();

        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Music music = new Music(
                        rs.getString("name"),
                        rs.getString("singer"),
                        Duration.ofMillis(rs.getLong("duration")),
                        rs.getString("filePath")
                );
                musics.add(music);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return musics;
    }

    public boolean deleteById(String id) {
        String sql = "DELETE FROM music WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
