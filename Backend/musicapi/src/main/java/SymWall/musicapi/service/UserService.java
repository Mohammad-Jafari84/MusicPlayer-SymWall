package SymWall.musicapi.service;

import SymWall.musicapi.dto.UserDto;
import SymWall.musicapi.model.User;
import SymWall.musicapi.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserService {
    private final UserRepository repo;

    public UserService(UserRepository repo) {
        this.repo = repo;
    }

    public List<UserDto> getAllUsers() {
        List<User> users = repo.findAll();
        return users.stream()
                .map(u -> new UserDto(u.getId(), u.getUsername(), u.getEmail(), u.getCreatedAt()))
                .collect(Collectors.toList());
    }


    public boolean signup(String username, String email, String password) {
        if (repo.findByEmail(email).isPresent()) return false;
        User user = new User(username, email, password);
        repo.save(user);
        return true;
    }

    public boolean login(String email, String password) {
        Optional<User> u = repo.findByEmail(email);
        return u.isPresent() && u.get().checkPassword(password);
    }


}