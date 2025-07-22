package com.com.SymWall.api;

import com.com.SymWall.util.DB;
import com.google.gson.Gson;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SocketApiService {

    private static final int PORT = 8085;

    public static void main(String[] args) {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Socket API Service started at port " + PORT);

            while (true) {
                try (Socket clientSocket = serverSocket.accept()) {
                    System.out.println("New client connected: " + clientSocket.getInetAddress());

                    // خواندن دیتا به صورت داینامیک از ResultSet و ذخیره در لیست Map
                    List<Map<String, Object>> data = fetchMusicData();

                    // تبدیل لیست به JSON
                    String json = new Gson().toJson(data);
                    System.out.println("Sending JSON: " + json);

                    // ارسال JSON به کلاینت
                    try (BufferedWriter writer = new BufferedWriter(
                            new OutputStreamWriter(clientSocket.getOutputStream(), StandardCharsets.UTF_8))) {

                        writer.write(json);
                        writer.flush();
                    }
                } catch (Exception e) {
                    System.err.println("Error handling client: " + e.getMessage());
                    e.printStackTrace();
                }
            }

        } catch (Exception e) {
            System.err.println("Server error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static List<Map<String, Object>> fetchMusicData() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT * FROM musics";

        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", rs.getString("id"));
                row.put("name", rs.getString("name"));
                row.put("singer", rs.getString("singer"));
                row.put("duration_seconds", rs.getInt("duration_seconds"));
                row.put("genre", rs.getString("genre"));
                row.put("file_path", rs.getString("file_path"));
                list.add(row);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }
}
