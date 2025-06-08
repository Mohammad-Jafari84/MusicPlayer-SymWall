package SymWall.musicapi.model;

import java.time.Duration;
import java.util.UUID;

public class Music {
    private final String id;
    private final String name;
    private final String singer;
    private final Duration duration;
    private final String filePath;

    private Duration currentPosition;
    private boolean isPaused;
    private boolean isLiked;
    private boolean isShuffled;
    private boolean isRepeated;
    private int likes;

    public Music(String name, String singer, Duration duration, String filePath) {
        this.id = UUID.randomUUID().toString();
        this.name = name;
        this.singer = singer;
        this.duration = duration != null ? duration : Duration.ZERO;
        this.filePath = filePath;
        this.currentPosition = Duration.ZERO;
        this.isPaused = true;
        this.isLiked = false;
        this.isShuffled = false;
        this.isRepeated = false;
        this.likes = 0;
    }

    // ------------------ Core Control ------------------

    public void play() {
        isPaused = false;
    }

    public void pause() {
        isPaused = true;
    }

    public void reset() {
        currentPosition = Duration.ZERO;
        isPaused = true;
    }

    public boolean isFinished() {
        return currentPosition.compareTo(duration) >= 0;
    }

    // ------------------ Like/Dislike ------------------

    public void like() {
        if (!isLiked) {
            likes++;
            isLiked = true;
        }
    }

    public void unlike() {
        if (isLiked && likes > 0) {
            likes--;
            isLiked = false;
        }
    }

    // ------------------ Toggle States ------------------

    public void toggleRepeat() {
        isRepeated = !isRepeated;
    }

    public void toggleShuffle() {
        isShuffled = !isShuffled;
    }

    // ------------------ Navigation ------------------

    public void forward(Duration step) {
        if (step != null && !step.isNegative()) {
            currentPosition = currentPosition.plus(step);
            if (currentPosition.compareTo(duration) > 0) {
                currentPosition = duration;
            }
        }
    }

    public void rewind(Duration step) {
        if (step != null && !step.isNegative()) {
            currentPosition = currentPosition.minus(step);
            if (currentPosition.isNegative()) {
                currentPosition = Duration.ZERO;
            }
        }
    }

    // ------------------ Getters ------------------

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getSinger() {
        return singer;
    }

    public String getFilePath() {
        return filePath;
    }

    public Duration getDuration() {
        return duration;
    }

    public Duration getCurrentPosition() {
        return currentPosition;
    }

    public boolean isPaused() {
        return isPaused;
    }

    public boolean isLiked() {
        return isLiked;
    }

    public boolean isShuffled() {
        return isShuffled;
    }

    public boolean isRepeated() {
        return isRepeated;
    }

    public int getLikes() {
        return likes;
    }

    public double getProgressPercent() {
        if (duration.isZero()) return 0.0;
        return (double) currentPosition.toMillis() / duration.toMillis() * 100.0;
    }

    // ------------------ Format Helpers ------------------

    public String getFormattedPosition() {
        return formatDuration(currentPosition);
    }

    public String getFormattedDuration() {
        return formatDuration(duration);
    }

    private String formatDuration(Duration d) {
        long minutes = d.toMinutes();
        long seconds = d.minusMinutes(minutes).getSeconds();
        return String.format("%02d:%02d", minutes, seconds);
    }

    // ------------------ Debugging ------------------

    @Override
    public String toString() {
        return String.format("Music[name='%s', singer='%s', duration=%s, position=%s, liked=%s, likes=%d]",
                name, singer, getFormattedDuration(), getFormattedPosition(), isLiked, likes);
    }
}
