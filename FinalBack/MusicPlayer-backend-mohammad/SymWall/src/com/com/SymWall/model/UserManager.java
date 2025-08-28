package com.com.SymWall.model;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import java.util.HashMap;
import java.util.Map;

import org.json.JSONArray;
import org.json.JSONObject;

public class UserManager {

    private final Map<String, User> usersByEmail;
    private static final String DATA_DIR = "C:\\Me\\Code\\JAVA\\Main\\SymWall\\data";
    private static final String USERS_FILE = DATA_DIR + "\\users.json";

    public UserManager() {
        usersByEmail = new HashMap<>();
        initialize();
        loadUsers();
    }

    private void initialize() {
        File directory = new File(DATA_DIR);
        if (!directory.exists()) {
            boolean created = directory.mkdirs();
            if (!created) {
                System.err.println("Failed to create data directory: " + DATA_DIR);
            }
        }
    }

    private void loadUsers() {
        File file = new File(USERS_FILE);
        if (!file.exists()) {
            System.out.println("Users file does not exist yet");
            return;
        }

        try {
            String content = new String(java.nio.file.Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8);
            JSONArray jsonArray = new JSONArray(content);

            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject userJson = jsonArray.getJSONObject(i);
                User user = User.fromJSONObject(userJson);
                user.checkAndDowngradeIfExpired();
                usersByEmail.put(user.getEmail(), user);
            }
            saveUsers(); // فقط یک بار بعد از بارگذاری

        } catch (IOException e) {
            System.err.println("Error loading users: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("Error parsing users JSON: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void saveUsers() {
        JSONArray jsonArray = new JSONArray();
        for (User user : usersByEmail.values()) {
            jsonArray.put(user.toJSONObject());
        }

        try (FileWriter writer = new FileWriter(USERS_FILE, StandardCharsets.UTF_8)) {
            writer.write(jsonArray.toString(2));
        } catch (IOException e) {
            System.err.println("Error saving users: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public User getUserByEmail(String email) {
        if (email == null) return null;
        User user = usersByEmail.get(email);
        if (user != null) {
            user.checkAndDowngradeIfExpired();
            // حذف saveUsers از اینجا برای جلوگیری از کندی و باگ
        }
        return user;
    }

    public boolean addUser(User user) {
        if (user == null || user.getEmail() == null) {
            return false;
        }
        if (usersByEmail.containsKey(user.getEmail())) {
            return false;
        }
        usersByEmail.put(user.getEmail(), user);
        saveUsers();
        return true;
    }

    public boolean updateUser(User user) {
        if (user == null || user.getEmail() == null) {
            return false;
        }
        if (!usersByEmail.containsKey(user.getEmail())) {
            return false;
        }
        user.checkAndDowngradeIfExpired();
        usersByEmail.put(user.getEmail(), user);
        saveUsers();
        return true;
    }

    public boolean deleteUser(String email) {
        if (email == null || !usersByEmail.containsKey(email)) {
            return false;
        }
        usersByEmail.remove(email);
        saveUsers();
        return true;
    }
}
