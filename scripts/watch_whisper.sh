#!/bin/bash

WATCH_DIR="$HOME/WhisperScribe"
SCRIPT="$HOME/WhisperScribe/scripts/transcribe.sh"
LOG_FILE="$HOME/WhisperScribe/logs/fswatch.log"
FSWATCH_CMD="/opt/homebrew/bin/fswatch"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ✅ Prevent multiple instances
if pgrep -f "$FSWATCH_CMD -0 $WATCH_DIR" > /dev/null; then
    log "fswatch already running, exiting..."
    exit 0
fi

if ! command -v fswatch &>/dev/null; then
    log "ERROR: fswatch not found! Install it using 'brew install fswatch'."
    exit 1
fi

log "Starting fswatch listener..."

$FSWATCH_CMD -0 "$WATCH_DIR" --event Created | while read -d "" FILE; do
    case "$FILE" in
        *.mp3|*.mp4|*.mpeg|*.mpga|*.m4a|*.wav|*.webm)
            log "Detected new file: $FILE"
            bash "$SCRIPT" "$FILE" &
            ;;
    esac
done
