package com.com.SymWall.model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

public class Comment {
    private String id;
    private String authorUsername;
    private String content;
    private int likes;
    private int dislikes;
    private LocalDateTime createdAt;
    private LocalDateTime lastEditedAt;


    public Comment(String authorUsername, String content) {
        this.id = UUID.randomUUID().toString();
        this.authorUsername = authorUsername;
        this.content = content;
        this.likes = 0;
        this.dislikes = 0;
        this.createdAt = LocalDateTime.now();
        this.lastEditedAt = null;
    }

    public Comment(String id, String authorUsername, String content,
                   int likes, int dislikes, LocalDateTime createdAt, LocalDateTime lastEditedAt) {
        this.id = id;
        this.authorUsername = authorUsername;
        this.content = content;
        this.likes = likes;
        this.dislikes = dislikes;
        this.createdAt = createdAt;
        this.lastEditedAt = lastEditedAt;
    }

    public Comment() {

    }

    // Getters
    public String getId() {
        return id;
    }

    public String getAuthorUsername() {
        return authorUsername;
    }

    public String getContent() {
        return content;
    }

    public int getLikes() {
        return likes;
    }

    public int getDislikes() {
        return dislikes;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getLastEditedAt() {
        return lastEditedAt;
    }


    public void setContent(String content) {
        this.content = content;
        this.lastEditedAt = LocalDateTime.now();
    }
    public void setId(String id) {
        if (id != null && !id.isEmpty()) {
            this.id = id;
        }
    }
    public void setAuthorUsername(String authorUsername) {
        if (authorUsername != null && !authorUsername.isEmpty()) {
            this.authorUsername = authorUsername;
        }
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        if (createdAt != null) this.createdAt = createdAt;
    }

    public void setLikes(int likes) {
        if (likes >= 0) this.likes = likes;
    }

    public void setDislikes(int dislikes) {
        if (dislikes >= 0) this.dislikes = dislikes;
    }

    public void setLastEditedAt(LocalDateTime lastEditedAt) {
        this.lastEditedAt = lastEditedAt;
    }

    // Actions

    public void like() {
        likes++;
    }

    public void dislike() {
        dislikes++;
    }

    public void undoLike() {
        if (likes > 0) likes--;
    }

    public void undoDislike() {
        if (dislikes > 0) dislikes--;
    }

    public void editContent(String newContent) {
        setContent(newContent);
    }

    // Formatters

    public String getFormattedCreatedAt() {
        return createdAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
    }

    public String getFormattedEditedAt() {
        if (lastEditedAt == null) return "Never edited";
        return lastEditedAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
    }

    @Override
    public String toString() {
        return String.format(
                "👤 %s\n💬 %s\n👍 %d   👎 %d\n🕒 Posted: %s%s",
                authorUsername,
                content,
                likes,
                dislikes,
                getFormattedCreatedAt(),
                (lastEditedAt != null ? " (edited: " + getFormattedEditedAt() + ")" : "")
        );
    }
}
