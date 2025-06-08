package SymWall.musicapi.dto;

import java.time.LocalDateTime;

public class UserDto {
    private String id;
    private String username;
    private String email;
    private LocalDateTime createdAt;

    public UserDto(String id, String username, String email, LocalDateTime createdAt) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.createdAt = createdAt;
    }

    // --------- Getters ---------
    public String getId() { return id; }
    public String getUsername() { return username; }
    public String getEmail() { return email; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
