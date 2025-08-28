package com.com.SymWall.handler;

import com.com.SymWall.model.SubscriptionType;
import com.com.SymWall.model.User;
import com.com.SymWall.model.UserManager;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;
import java.time.LocalDateTime;

public class RequestHandler {
    private final UserManager userManager;
    private final Map<String, String> loginNonces;

    public RequestHandler() {
        userManager = new UserManager();
        loginNonces = new ConcurrentHashMap<>();
    }

    public String handleRequest(String message) {
        try {
            System.out.println("Received request: " + message);
            JSONObject request = new JSONObject(message);
            String action = request.getString("action");
            JSONObject data = request.getJSONObject("data");
            JSONObject response = new JSONObject();

            switch (action) {
                case "get_nonce": {
                    String email = data.getString("email");
                    User user = userManager.getUserByEmail(email);
                    if (user != null) {
                        String nonce = UUID.randomUUID().toString();
                        loginNonces.put(email, nonce);
                        response.put("status", "success");
                        response.put("nonce", nonce);
                        response.put("action", "get_nonce_response");
                    } else {
                        response.put("status", "error");
                        response.put("message", "User not found");
                        response.put("action", "get_nonce_response");
                    }
                    break;
                }

                case "signup_request": {
                    String newUsername = data.getString("username");
                    String newEmail = data.getString("email");
                    String passwordHash = data.getString("passwordHash");
                    String passwordSalt = data.getString("passwordSalt");
                    if (userManager.getUserByEmail(newEmail) != null) {
                        response.put("status", "error");
                        response.put("message", "Email already exists");
                    } else {
                        User newUser = new User(newUsername, newEmail, passwordHash, passwordSalt);
                        userManager.addUser(newUser);
                        JSONObject userData = new JSONObject();
                        userData.put("id", newUser.getId());
                        userData.put("username", newUser.getUsername());
                        userData.put("email", newUser.getEmail());
                        response.put("status", "success");
                        response.put("message", "Registration successful");
                        response.put("data", userData);
                    }
                    response.put("action", "signup_response");
                    break;
                }

                case "login_request": {
                    String email = data.getString("email");
                    String clientPasswordHash = data.getString("passwordHash");
                    User user = userManager.getUserByEmail(email);
                    String nonce = loginNonces.get(email);
                    if (user != null && nonce != null) {
                        String storedPasswordHash = user.getPasswordHash();
                        String expectedHash = hashSHA256Base64(storedPasswordHash + nonce);
                        if (expectedHash.equals(clientPasswordHash)) {
                            user.checkAndDowngradeIfExpired(); // چک انقضا اشتراک
                            JSONObject userData = new JSONObject();
                            userData.put("id", user.getId());
                            userData.put("username", user.getUsername());
                            userData.put("email", user.getEmail());
                            userData.put("credit", user.getCredit());
                            userData.put("subscription", user.getSubscription().toString());
                            userData.put("subscriptionExpireAt", user.getSubscriptionExpireAt() != null ? user.getSubscriptionExpireAt().toString() : JSONObject.NULL);
                            response.put("status", "success");
                            response.put("message", "Login successful");
                            response.put("data", userData);
                            loginNonces.remove(email);
                        } else {
                            response.put("status", "error");
                            response.put("message", "Invalid email or password");
                        }
                    } else {
                        response.put("status", "error");
                        response.put("message", "Invalid email, password, or nonce missing");
                    }
                    response.put("action", "login_response");
                    break;
                }

                case "get_salt": {
                    String email = data.getString("email");
                    User user = userManager.getUserByEmail(email);
                    if (user != null) {
                        response.put("status", "success");
                        response.put("salt", user.getPasswordSalt());
                        response.put("action", "get_salt_response");
                    } else {
                        response.put("status", "error");
                        response.put("message", "User not found");
                        response.put("action", "get_salt_response");
                    }
                    break;
                }

                case "delete_account_request": {
                    String email = data.getString("email");
                    String clientPasswordHash = data.getString("passwordHash");
                    User user = userManager.getUserByEmail(email);
                    if (user != null) {
                        String storedPasswordHash = user.getPasswordHash();
                        if (storedPasswordHash.equals(clientPasswordHash)) {
                            boolean removed = userManager.deleteUser(email);
                            if (removed) {
                                response.put("status", "success");
                                response.put("message", "Account deleted successfully");
                            } else {
                                response.put("status", "error");
                                response.put("message", "Failed to delete account");
                            }
                        } else {
                            response.put("status", "error");
                            response.put("message", "Invalid password");
                        }
                    } else {
                        response.put("status", "error");
                        response.put("message", "User not found");
                    }
                    response.put("action", "delete_account_response");
                    break;
                }

                case "update_premium_status": {
                    String email = data.getString("email");
                    String subscriptionTypeStr = data.getString("subscriptionType");
                    User user = userManager.getUserByEmail(email);
                    if (user != null) {
                        try {
                            SubscriptionType newPlan = SubscriptionType.valueOf(subscriptionTypeStr);
                            LocalDateTime expireAt = null;
                            if (newPlan == SubscriptionType.PREMIUM_1_MONTH) {
                                expireAt = LocalDateTime.now().plusMonths(1);
                            } else if (newPlan == SubscriptionType.PREMIUM_3_MONTHS) {
                                expireAt = LocalDateTime.now().plusMonths(3);
                            } else if (newPlan == SubscriptionType.PREMIUM_12_MONTHS) {
                                expireAt = LocalDateTime.now().plusYears(1);
                            }
                            user.setSubscription(newPlan);
                            user.setSubscriptionExpireAt(expireAt);
                            boolean updated = userManager.updateUser(user);
                            if (updated) {
                                response.put("status", "success");
                                response.put("message", "Subscription updated successfully");
                            } else {
                                response.put("status", "error");
                                response.put("message", "Failed to update user data");
                            }
                        } catch (IllegalArgumentException ex) {
                            response.put("status", "error");
                            response.put("message", "Invalid subscription type");
                        }
                    } else {
                        response.put("status", "error");
                        response.put("message", "User not found");
                    }
                    response.put("action", "update_premium_status_response");
                    break;
                }

                case "get_user_status": {
                    String email = data.getString("email");
                    User user = userManager.getUserByEmail(email);
                    if (user != null) {
                        user.checkAndDowngradeIfExpired(); // چک انقضا اشتراک
                        JSONObject userData = new JSONObject();
                        userData.put("id", user.getId());
                        userData.put("username", user.getUsername());
                        userData.put("email", user.getEmail());
                        userData.put("credit", user.getCredit());
                        userData.put("subscription", user.getSubscription().toString());
                        userData.put("createdAt", user.getCreatedAt().toString());
                        userData.put("subscriptionExpireAt", user.getSubscriptionExpireAt() != null ? user.getSubscriptionExpireAt().toString() : JSONObject.NULL);
                        response.put("status", "success");
                        response.put("data", userData);
                    } else {
                        response.put("status", "error");
                        response.put("message", "User not found");
                    }
                    response.put("action", "get_user_status_response");
                    break;
                }

                default: {
                    response.put("status", "error");
                    response.put("message", "Unknown action");
                    response.put("action", "error");
                    break;
                }
            }

            System.out.println("Sending response: " + response.toString());
            return response.toString();

        } catch (Exception e) {
            System.err.println("Error processing request: " + e.getMessage());
            e.printStackTrace();
            JSONObject errorResponse = new JSONObject();
            errorResponse.put("status", "error");
            errorResponse.put("message", "Server error: " + e.getMessage());
            errorResponse.put("action", "error");
            return errorResponse.toString();
        }
    }

    private String hashSHA256Base64(String input) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashedBytes = digest.digest(input.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(hashedBytes);
    }
}
