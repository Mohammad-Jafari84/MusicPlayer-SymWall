package com.com.SymWall.model;



import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

public class CommentManager {
    private final List<Comment> comments;

    public CommentManager() {
        comments = new ArrayList<>();
    }


    public void addComment(Comment comment) {
        comments.add(comment);
    }


    public boolean removeComment(Comment comment) {
        return comments.remove(comment);
    }


    public boolean removeCommentAt(int index) {
        if (index < 0 || index >= comments.size()) return false;
        comments.remove(index);
        return true;
    }


    public List<Comment> getAllComments() {
        return new ArrayList<>(comments);
    }


    public List<Comment> getCommentsByAuthor(String authorUsername) {
        return comments.stream()
                .filter(c -> c.getAuthorUsername().equalsIgnoreCase(authorUsername))
                .collect(Collectors.toList());
    }


    public List<Comment> getCommentsSortedByNewest() {
        return comments.stream()
                .sorted(Comparator.comparing(Comment::getCreatedAt).reversed())
                .collect(Collectors.toList());
    }


    public List<Comment> getCommentsSortedByOldest() {
        return comments.stream()
                .sorted(Comparator.comparing(Comment::getCreatedAt))
                .collect(Collectors.toList());
    }


    public int getCommentCount() {
        return comments.size();
    }


    public boolean editCommentContent(int index, String newContent) {
        if (index < 0 || index >= comments.size()) return false;
        comments.get(index).setContent(newContent);
        return true;
    }
}
