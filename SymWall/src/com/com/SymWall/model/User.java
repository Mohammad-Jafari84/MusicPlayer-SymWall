package com.com.SymWall.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.util.Base64;
import java.nio.charset.StandardCharsets;

import org.json.JSONObject;

public class User {

    private String id;
    private String username;
    private String email;
    private String passwordHash;
    private String passwordSalt;
    private double credit;
    private SubscriptionType subscription;
    private LocalDateTime createdAt;

    private LocalDateTime subscriptionExpireAt;  // ✅ جدید

    private static final int ITERATIONS = 65536;
    private static final int KEY_LENGTH = 512;
    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";

    public User() {
        // Empty constructor for JSON parsing
    }

    public User(String username, String email, String passwordHash, String passwordSalt) {
        this.id = UUID.randomUUID().toString();
        this.username = username;
        this.email = email;
        this.passwordHash = passwordHash;
        this.passwordSalt = passwordSalt;
        this.credit = 0.0;
        this.subscription = SubscriptionType.STANDARD;
        this.createdAt = LocalDateTime.now();
        this.subscriptionExpireAt = null; // ✅ پیش‌فرض
    }

    // Password hashing
    private String hashPassword(String password, String salt) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt.getBytes(StandardCharsets.UTF_8), ITERATIONS, KEY_LENGTH);
            SecretKeyFactory factory = SecretKeyFactory.getInstance(ALGORITHM);
            byte[] hash = factory.generateSecret(spec).getEncoded();
            return Base64.getEncoder().encodeToString(hash);
        } catch (Exception e) {
            throw new RuntimeException("Error while hashing a password", e);
        }
    }

    private String generateSalt() {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[64];
        random.nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    public boolean checkPassword(String inputPassword) {
        try {
            String hashAttempt = hashPassword(inputPassword, this.passwordSalt);
            return this.passwordHash.equals(hashAttempt);
        } catch (Exception e) {
            return false;
        }
    }

    public void changePassword(String newPassword) {
        this.passwordSalt = generateSalt();
        this.passwordHash = hashPassword(newPassword, passwordSalt);
    }

    public void addCredit(double amount) {
        if (amount > 0) {
            this.credit += amount;
        }
    }

    public void upgradeSubscription(SubscriptionType newPlan, LocalDateTime expireAt) {
        if (newPlan != null) {
            this.subscription = newPlan;
            this.subscriptionExpireAt = expireAt;
        }
    }

    public void editUsername(String newUsername) {
        if (newUsername != null && !newUsername.isEmpty()) {
            this.username = newUsername;
        }
    }

    /**
     * ✅ NEW: Check if the subscription is expired
     * If expired, automatically downgrade to STANDARD
     */
    public void checkAndDowngradeIfExpired() {
        if (subscriptionExpireAt != null && LocalDateTime.now().isAfter(subscriptionExpireAt)) {
            this.subscription = SubscriptionType.STANDARD;
            this.subscriptionExpireAt = null;
        }
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) {
        if (id != null && !id.isEmpty()) this.id = id;
    }

    public String getUsername() { return username; }
    public void setUsername(String username) {
        if (username != null && !username.isEmpty()) this.username = username;
    }

    public String getEmail() { return email; }
    public void setEmail(String email) {
        if (email != null && !email.isEmpty()) this.email = email;
    }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) {
        if (passwordHash != null && !passwordHash.isEmpty()) this.passwordHash = passwordHash;
    }

    public String getPasswordSalt() { return passwordSalt; }
    public void setPasswordSalt(String passwordSalt) {
        if (passwordSalt != null && !passwordSalt.isEmpty()) this.passwordSalt = passwordSalt;
    }

    public double getCredit() { return credit; }
    public void setCredit(double credit) {
        if (credit >= 0) this.credit = credit;
    }

    public SubscriptionType getSubscription() { return subscription; }
    public void setSubscription(SubscriptionType subscription) {
        if (subscription != null) this.subscription = subscription;
    }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) {
        if (createdAt != null) this.createdAt = createdAt;
    }

    public LocalDateTime getSubscriptionExpireAt() { return subscriptionExpireAt; }
    public void setSubscriptionExpireAt(LocalDateTime subscriptionExpireAt) {
        this.subscriptionExpireAt = subscriptionExpireAt;
    }

    // JSON conversion helpers
    public JSONObject toJSONObject() {
        JSONObject json = new JSONObject();
        json.put("id", this.id);
        json.put("username", this.username);
        json.put("email", this.email);
        json.put("passwordHash", this.passwordHash);
        json.put("passwordSalt", this.passwordSalt);
        json.put("credit", this.credit);
        json.put("subscription", this.subscription.toString());
        json.put("createdAt", this.createdAt.toString());
        json.put("subscriptionExpireAt", this.subscriptionExpireAt != null ? this.subscriptionExpireAt.toString() : JSONObject.NULL); // ✅ جدید
        return json;
    }

    public static User fromJSONObject(JSONObject json) {
        User user = new User();
        user.setId(json.getString("id"));
        user.setUsername(json.getString("username"));
        user.setEmail(json.getString("email"));
        user.setPasswordHash(json.getString("passwordHash"));
        user.setPasswordSalt(json.getString("passwordSalt"));
        user.setCredit(json.getDouble("credit"));
        user.setSubscription(SubscriptionType.valueOf(json.getString("subscription")));
        user.setCreatedAt(LocalDateTime.parse(json.getString("createdAt")));
        if (json.has("subscriptionExpireAt") && !json.isNull("subscriptionExpireAt")) {
            user.setSubscriptionExpireAt(LocalDateTime.parse(json.getString("subscriptionExpireAt")));
        }
        return user;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof User user)) return false;
        return email.equals(user.email);
    }

    @Override
    public int hashCode() {
        return Objects.hash(email);
    }

    @Override
    public String toString() {
        return String.format("User{id='%s', username='%s', email='%s', credit=%.2f, subscription=%s, createdAt=%s, subscriptionExpireAt=%s}",
                id, username, email, credit, subscription, createdAt, subscriptionExpireAt);
    }
}
