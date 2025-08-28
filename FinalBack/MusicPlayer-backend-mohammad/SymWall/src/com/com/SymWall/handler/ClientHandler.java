package com.com.SymWall.handler;

import java.io.*;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class ClientHandler implements Runnable {
    private final Socket clientSocket;
    private final RequestHandler requestHandler;

    public ClientHandler(Socket clientSocket) {
        this.clientSocket = clientSocket;
        this.requestHandler = new RequestHandler();
    }

    @Override
    public void run() {
        System.out.println("New client connected from: " + clientSocket.getInetAddress());
        try (
                BufferedReader reader = new BufferedReader(
                        new InputStreamReader(clientSocket.getInputStream(), StandardCharsets.UTF_8));
                PrintWriter writer = new PrintWriter(
                        new OutputStreamWriter(clientSocket.getOutputStream(), StandardCharsets.UTF_8), true)
        ) {
            String message;
            while ((message = reader.readLine()) != null) {
                System.out.println("Raw message received: " + message);
                String response = requestHandler.handleRequest(message.trim());
                writer.println(response);
                System.out.println("Response sent: " + response);
            }
        } catch (IOException e) {
            System.err.println("Error handling client: " + e.getMessage());
            e.printStackTrace();
        } finally {
            try {
                System.out.println("Closing connection with: " + clientSocket.getInetAddress());
                clientSocket.close();
            } catch (IOException e) {
                System.err.println("Error closing socket: " + e.getMessage());
            }
        }
    }
}
