package com.com.SymWall.repository;

import com.com.SymWall.model.User;
import com.com.SymWall.util.DB;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserRepository {

    public boolean save(User user) {
        String sql = "INSERT INTO users (id, username, email, passwordHash, passwordSalt, credit, subscription, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, user.getId());
            stmt.setString(2, user.getUsername());
            stmt.setString(3, user.getEmail());
            stmt.setString(4, user.getPasswordHash());
            stmt.setString(5, user.getPasswordSalt());
            stmt.setDouble(6, user.getCredit());
            stmt.setString(7, user.getSubscription().name());
            stmt.setTimestamp(8, Timestamp.valueOf(user.getCreatedAt()));

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean update(User user) {
        String sql = "UPDATE users SET username = ?, email = ?, passwordHash = ?, passwordSalt = ?, credit = ?, subscription = ? WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, user.getUsername());
            stmt.setString(2, user.getEmail());
            stmt.setString(3, user.getPasswordHash());
            stmt.setString(4, user.getPasswordSalt());
            stmt.setDouble(5, user.getCredit());
            stmt.setString(6, user.getSubscription().name());
            stmt.setString(7, user.getId());

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }


    public User findByEmail(String email) {
        String sql = "SELECT * FROM users WHERE email = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, email);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                User user = new User();
                user.setId(rs.getString("id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setPasswordHash(rs.getString("passwordHash"));
                user.setPasswordSalt(rs.getString("passwordSalt"));
                user.setCredit(rs.getDouble("credit"));
                user.setSubscription(com.com.SymWall.model.SubscriptionType.valueOf(rs.getString("subscription")));
                user.setCreatedAt(rs.getTimestamp("createdAt").toLocalDateTime());
                return user;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<User> findAll() {
        String sql = "SELECT * FROM users";
        List<User> users = new ArrayList<>();

        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                User user = new User();
                user.setId(rs.getString("id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setPasswordHash(rs.getString("passwordHash"));
                user.setPasswordSalt(rs.getString("passwordSalt"));
                user.setCredit(rs.getDouble("credit"));
                user.setSubscription(com.com.SymWall.model.SubscriptionType.valueOf(rs.getString("subscription")));
                user.setCreatedAt(rs.getTimestamp("createdAt").toLocalDateTime());
                users.add(user);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return users;
    }

    public boolean updateCredit(String userId, double newCredit) {
        String sql = "UPDATE users SET credit = ? WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setDouble(1, newCredit);
            stmt.setString(2, userId);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteById(String userId) {
        String sql = "DELETE FROM users WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, userId);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
