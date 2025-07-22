package com.com.SymWall.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class MusicViewer {

    public static void main(String[] args) {
        String sql = "SELECT * FROM musics";

        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                String id = rs.getString("id");
                String name = rs.getString("name");
                String singer = rs.getString("singer");
                int duration = rs.getInt("duration_seconds");
                String genre = rs.getString("genre");
                String filePath = rs.getString("file_path");

                System.out.printf("ID: %s, Name: %s, Singer: %s, Duration: %d, Genre: %s, File Path: %s%n",
                        id, name, singer, duration, genre, filePath);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
