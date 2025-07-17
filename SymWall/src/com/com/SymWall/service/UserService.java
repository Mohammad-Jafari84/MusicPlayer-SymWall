package com.com.SymWall.service;

import com.com.SymWall.model.User;
import com.com.SymWall.repository.UserRepository;

import java.util.List;

public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public boolean signup(String username, String email, String passwordHash, String passwordSalt) {
        if (userRepository.findByEmail(email) != null) return false;
        User user = new User(username, email, passwordHash, passwordSalt);
        return userRepository.save(user);
    }

    public boolean login(String email, String password) {
        User user = userRepository.findByEmail(email);
        return user != null && user.checkPassword(password);
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public boolean changePassword(String email, String oldPassword, String newPassword) {
        User user = userRepository.findByEmail(email);
        if (user == null || !user.checkPassword(oldPassword)) return false;
        user.changePassword(newPassword);
        return userRepository.update(user);
    }

    public boolean addCredit(String email, double amount) {
        User user = userRepository.findByEmail(email);
        if (user == null) return false;
        user.addCredit(amount);
        return userRepository.update(user);
    }

    public boolean upgradeSubscription(String email, String newPlan, java.time.LocalDateTime expireAt) {
        User user = userRepository.findByEmail(email);
        if (user == null) return false;
        try {
            user.upgradeSubscription(com.com.SymWall.model.SubscriptionType.valueOf(newPlan), expireAt);
        } catch (IllegalArgumentException e) {
            return false;
        }
        return userRepository.update(user);
    }

}
