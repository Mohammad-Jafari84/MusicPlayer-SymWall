package SymWall.musicapi.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID; //Random ID

import javax.crypto.SecretKeyFactory; //PBEKeySpec SHA-256 -> PBKDF2 = Password-Based Key Derivation Function 2
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.util.Base64; //Hash to String
import java.nio.charset.StandardCharsets; //To UTF-8



@Entity
@Table(name = "users")
public class User {
    public User() {
        // Required by JPA
    }
    @Id
    private String id;

    @Column(nullable=false)
    private String username;

    @Column(nullable=false, unique=true)
    private String email;

    private String passwordHash;
    private String passwordSalt;
    private double credit;

    @Enumerated(EnumType.STRING)
    private SubscriptionType subscription;

    private LocalDateTime createdAt;

    private static final int ITERATIONS = 65536;
    private static final int KEY_LENGTH = 512; // bits
    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";






    public User(String username, String email, String password) {
        this.id = UUID.randomUUID().toString();
        this.username = username;
        this.email = email;
        this.passwordSalt = generateSalt();
        this.passwordHash = hashPassword(password, passwordSalt);

        this.credit = 0.0;
        this.subscription = SubscriptionType.STANDARD;
        this.createdAt = LocalDateTime.now();
    }


    // ----------------- Password Hashing -----------------
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


    @Override
    public int hashCode() {
        return Objects.hash(email);
    }

    public boolean checkPassword(String inputPassword) {
        String hashAttempt = hashPassword(inputPassword, this.passwordSalt);
        return this.passwordHash.equals(hashAttempt);
    }

    public void changePassword(String newPassword) {
        this.passwordSalt = generateSalt();
        this.passwordHash = hashPassword(newPassword, passwordSalt);
    }


    // ----------------- Credit -----------------
    public void addCredit(double amount) {
        if (amount > 0) {
            this.credit += amount;
        }
    }

    // ----------------- Subscription -----------------
    public void upgradeSubscription(SubscriptionType newPlan) {
        if (newPlan != null) {
            this.subscription = newPlan;
        }
    }

    // ----------------- Info Editing -----------------
    public void editUsername(String newUsername) {
        if (newUsername != null && !newUsername.isEmpty()) {
            this.username = newUsername;
        }
    }

    // ----------------- Getters -----------------
    public String getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public String getEmail() {
        return email;
    }

    public double getCredit() {
        return credit;
    }

    public SubscriptionType getSubscription() {
        return subscription;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    // ----------------- Setters -----------------
    public void setUsername(String username) {
        if (username != null && !username.isEmpty()) {
            this.username = username;
        }
    }

    public void setCredit(double credit) {
        if (credit >= 0) {
            this.credit = credit;
        }
    }

    public void setSubscription(SubscriptionType subscription) {
        if (subscription != null) {
            this.subscription = subscription;
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof User user)) return false;
        return email.equals(user.email);
    }

    // ----------------- ToString -----------------
    @Override
    public String toString() {
        return String.format("User{id='%s', username='%s', email='%s', credit=%.2f, subscription=%s, createdAt=%s}",
                id, username, email, credit, subscription, createdAt);
    }
}

enum SubscriptionType {
    STANDARD,
    PREMIUM_1_MONTH,
    PREMIUM_3_MONTHS,
    PREMIUM_12_MONTHS
}

