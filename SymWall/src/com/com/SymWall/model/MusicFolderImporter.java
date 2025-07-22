package com.com.SymWall.model;
import java.io.File;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.UUID;

public class MusicFolderImporter {

    private static final String MUSIC_FOLDER = "D:\\MainMusic";

    public static void main(String[] args) {
        File folder = new File(MUSIC_FOLDER);

        if (!folder.exists() || !folder.isDirectory()) {
            System.err.println("مسیر فولدر صوتی معتبر نیست!");
            return;
        }

        File[] files = folder.listFiles((dir, name) -> {
            String lower = name.toLowerCase();
            return lower.endsWith(".mp3") || lower.endsWith(".wav") || lower.endsWith(".m4a");
        });

        if (files == null || files.length == 0) {
            System.out.println("هیچ فایل صوتی در مسیر یافت نشد.");
            return;
        }

        for (File file : files) {
            String fileName = file.getName();
            String baseName = fileName.substring(0, fileName.lastIndexOf('.')); // حذف پسوند

            // جدا کردن خواننده و نام آهنگ (فرمت: خواننده - نام آهنگ [کیفیت])
            String singer = "Unknown";
            String songName = baseName;

            if (baseName.contains(" - ")) {
                String[] parts = baseName.split(" - ", 2);
                singer = parts[0].trim();
                songName = parts[1].trim();
            }

            // حذف قسمت کیفیت مانند [320]
            songName = songName.replaceAll("\\[.*?\\]", "").trim();

            int duration = 0; // اگر نیاز به مدت زمان داری، باید با کتابخانه جداگانه استخراج کنی
            String genre = "Unknown";
            String filePath = file.getAbsolutePath();

            boolean saved = saveMusicToDB(songName, singer, duration, genre, filePath);
            System.out.printf("فایل %s %s ذخیره شد.%n", fileName, saved ? "با موفقیت" : "ناموفق");
        }
    }

    private static boolean saveMusicToDB(String name, String singer, int duration, String genre, String filePath) {
        String sql = "INSERT INTO musics (id, name, singer, duration_seconds, genre, file_path) VALUES (?, ?, ?, ?, ?, ?)";

        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, UUID.randomUUID().toString());
            stmt.setString(2, name);
            stmt.setString(3, singer);
            stmt.setInt(4, duration);
            stmt.setString(5, genre);
            stmt.setString(6, filePath);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
