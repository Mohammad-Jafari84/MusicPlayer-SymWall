package com.com.SymWall.service;

import com.com.SymWall.model.Comment;
import com.com.SymWall.repository.CommentRepository;

import java.util.List;

public class CommentService {
    private final CommentRepository commentRepository;

    public CommentService(CommentRepository commentRepository) {
        this.commentRepository = commentRepository;
    }

    public boolean addComment(Comment comment) {
        return commentRepository.save(comment);
    }

    public boolean removeComment(String id) {
        return commentRepository.deleteById(id);
    }

    public boolean updateCommentContent(String id, String newContent) {
        return commentRepository.updateContent(id, newContent);
    }

    public Comment getCommentById(String id) {
        return commentRepository.findById(id);
    }

    public List<Comment> getAllComments() {
        return commentRepository.findAll();
    }

    public List<Comment> getCommentsByAuthor(String authorUsername) {
        return commentRepository.findByAuthor(authorUsername);
    }

    public List<Comment> getCommentsSortedByNewest() {
        return commentRepository.findAllSortedByCreatedDesc();
    }

    public List<Comment> getCommentsSortedByOldest() {
        return commentRepository.findAllSortedByCreatedAsc();
    }
}
