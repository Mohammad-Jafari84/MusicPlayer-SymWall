package SymWall.musicapi.model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Comment {
    private final String authorUsername;
    private String content;
    private int likes;
    private int dislikes;
    private final LocalDateTime createdAt;
    private LocalDateTime lastEditedAt;

    public Comment(String authorUsername, String content) {
        this.authorUsername = authorUsername;
        this.content = content;
        this.likes = 0;
        this.dislikes = 0;
        this.createdAt = LocalDateTime.now();
        this.lastEditedAt = null;
    }

    // Getters
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

    public void setContent(String content) {
        this.content = content;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getLastEditedAt() {
        return lastEditedAt;
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
        this.content = newContent;
        this.lastEditedAt = LocalDateTime.now();
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
