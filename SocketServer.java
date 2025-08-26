package com.com.SymWall.server;

import com.com.SymWall.handler.ClientHandler;

import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SocketServer {
    private final int port = 8081;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);

    public void start() {
        try {
            ServerSocket serverSocket = new ServerSocket(port, 50, InetAddress.getByName("0.0.0.0"));
            System.out.println("Server is running on all interfaces, port " + port);
            System.out.println("Local IP: " + InetAddress.getLocalHost().getHostAddress());
            System.out.println("\nTest commands (copy and paste these):");
            System.out.println("1. Sign up:");
            System.out.println("{\"action\":\"signup_request\",\"data\":{\"username\":\"test\",\"email\":\"test@test.com\",\"password\":\"123456\"}}");
            System.out.println("\n2. Login:");
            System.out.println("{\"action\":\"login_request\",\"data\":{\"email\":\"test@test.com\",\"password\":\"123456\"}}");
            System.out.println("\nWaiting for connections...\n");

            while (true) {
                Socket clientSocket = serverSocket.accept();
                System.out.println("New client connected from: " + clientSocket.getInetAddress());
                pool.execute(new ClientHandler(clientSocket));
            }

        } catch (IOException e) {
            System.err.println("Server error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        SocketServer server = new SocketServer();
        server.start();
    }
}
