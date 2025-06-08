package SymWall.musicapi.controller;

import SymWall.musicapi.dto.LoginRequest;
import SymWall.musicapi.dto.SignupRequest;
import SymWall.musicapi.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {
    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/signup")
    public ResponseEntity<String> signup(@RequestBody SignupRequest req) {
        boolean ok = userService.signup(req.username(), req.email(), req.password());
        return ok ? ResponseEntity.ok("User created")
                : ResponseEntity.status(409).body("Email exists");
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody LoginRequest req) {
        return userService.login(req.email(), req.password())
                ? ResponseEntity.ok("Login successful")
                : ResponseEntity.status(401).body("Invalid credentials");
    }

    @GetMapping("/test")
    public String test() {
        return "API is running";
    }

    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        return ResponseEntity.ok("pong");
    }



}
