#!/bin/bash

WATCH_DIR="$HOME/WhisperScribe"
SCRIPT="$HOME/WhisperScribe/scripts/transcribe.sh"
LOG_FILE="$HOME/WhisperScribe/logs/fswatch.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting fswatch listener..." | tee -a "$LOG_FILE"

fswatch -0 "$WATCH_DIR" --event Created | while read -d "" FILE; do
    case "$FILE" in
        *.mp3|*.mp4|*.mpeg|*.mpga|*.m4a|*.wav|*.webm)
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Detected new file: $FILE" | tee -a "$LOG_FILE"
            bash "$SCRIPT" "$FILE" &
            ;;
    esac
done
