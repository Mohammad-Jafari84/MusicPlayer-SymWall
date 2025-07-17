package com.com.SymWall.repository;

import com.com.SymWall.model.Comment;
import com.com.SymWall.util.DB;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class CommentRepository {

    public boolean save(Comment comment) {
        String sql = "INSERT INTO comments (id, authorUsername, content, createdAt, lastEditedAt, likes, dislikes) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, comment.getId());
            stmt.setString(2, comment.getAuthorUsername());
            stmt.setString(3, comment.getContent());
            stmt.setTimestamp(4, Timestamp.valueOf(comment.getCreatedAt()));
            if (comment.getLastEditedAt() != null) {
                stmt.setTimestamp(5, Timestamp.valueOf(comment.getLastEditedAt()));
            } else {
                stmt.setNull(5, Types.TIMESTAMP);
            }
            stmt.setInt(6, comment.getLikes());
            stmt.setInt(7, comment.getDislikes());

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public Comment findById(String id) {
        String sql = "SELECT * FROM comments WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                return mapRowToComment(rs);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<Comment> findAll() {
        String sql = "SELECT * FROM comments";
        return findAllByQuery(sql);
    }

    public boolean deleteById(String id) {
        String sql = "DELETE FROM comments WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateContent(String id, String newContent) {
        String sql = "UPDATE comments SET content = ?, lastEditedAt = ? WHERE id = ?";
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, newContent);
            stmt.setTimestamp(2, Timestamp.valueOf(LocalDateTime.now()));
            stmt.setString(3, id);

            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Comment> findByAuthor(String authorUsername) {
        String sql = "SELECT * FROM comments WHERE authorUsername = ?";
        List<Comment> comments = new ArrayList<>();
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, authorUsername);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                comments.add(mapRowToComment(rs));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return comments;
    }

    public List<Comment> findAllSortedByCreatedDesc() {
        String sql = "SELECT * FROM comments ORDER BY createdAt DESC";
        return findAllByQuery(sql);
    }

    public List<Comment> findAllSortedByCreatedAsc() {
        String sql = "SELECT * FROM comments ORDER BY createdAt ASC";
        return findAllByQuery(sql);
    }

    private List<Comment> findAllByQuery(String sql) {
        List<Comment> comments = new ArrayList<>();
        try (Connection conn = DB.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                comments.add(mapRowToComment(rs));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return comments;
    }

    private Comment mapRowToComment(ResultSet rs) throws SQLException {
        Comment comment = new Comment(
                rs.getString("authorUsername"),
                rs.getString("content")
        );

        comment.setId(rs.getString("id"));

        comment.setCreatedAt(rs.getTimestamp("createdAt").toLocalDateTime());

        Timestamp lastEditedTs = rs.getTimestamp("lastEditedAt");
        if (lastEditedTs != null) {
            comment.setLastEditedAt(lastEditedTs.toLocalDateTime());
        }

        comment.setLikes(rs.getInt("likes"));
        comment.setDislikes(rs.getInt("dislikes"));

        return comment;
    }
}
