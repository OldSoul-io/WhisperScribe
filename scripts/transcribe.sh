#!/bin/bash

ROOT_DIR="$HOME/WhisperScribe"
LOGS_FILE="$ROOT_DIR/logs/transcription.log"
OUTPUT_DIR="$ROOT_DIR/transcripts"
ARCHIVE_DIR="$ROOT_DIR/archive"
VENV_DIR="$ROOT_DIR/whisper-env"

mkdir -p "$OUTPUT_DIR" "$ARCHIVE_DIR"

generate_title() {
    local content="$1"
    local title=$(echo "$content" | ollama run mistral "Summarize this transcript into a concise filename (5 words max, no special characters):" | tr -d '[:punct:]' | tr ' ' '_')
    echo "${title:-Transcript_$(date '+%Y%m%d%H%M%S')}"
}

for FILE in "$@"; do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Processing: $FILE" >> "$LOGS_FILE"
    
    source "$VENV_DIR/bin/activate"
    whisper "$FILE" --model large --output_dir "$OUTPUT_DIR" >> "$LOGS_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        TRANSCRIPT_PATH="$OUTPUT_DIR/$(basename "$FILE" .${FILE##*.}).txt"
        if [[ -f "$TRANSCRIPT_PATH" ]]; then
            TRANSCRIPT_CONTENT=$(head -n 50 "$TRANSCRIPT_PATH")
            NEW_FILENAME=$(generate_title "$TRANSCRIPT_CONTENT")
            mv "$TRANSCRIPT_PATH" "$OUTPUT_DIR/$NEW_FILENAME.txt"
        fi
        mv "$FILE" "$ARCHIVE_DIR/$(basename "$FILE")_$(date '+%Y%m%d%H%M%S')"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Transcription failed for $FILE" >> "$LOGS_FILE"
    fi
done
