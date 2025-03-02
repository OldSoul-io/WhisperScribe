#!/bin/bash

ROOT_DIR="$HOME/WhisperScribe"
LOGS_DIR="$ROOT_DIR/logs"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.user.fswatch.whisper.plist"
INSTALL_TRACKER="$LOGS_DIR/install-tracker.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGS_DIR/uninstall.log"
}

log "🛑 Uninstalling WhisperScribe and cleaning up system files..."

# ✅ Stop & Remove LaunchAgent
if [ -f "$LAUNCH_AGENT" ]; then
    log "📂 Unloading and removing LaunchAgent..."
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null
    rm -f "$LAUNCH_AGENT"
    log "✅ LaunchAgent removed."
else
    log "⚠️ No LaunchAgent found. Skipping."
fi

# ✅ Kill Running Processes
log "🔪 Terminating fswatch and watch_whisper.sh processes..."
pkill -f fswatch && log "✅ fswatch process stopped." || log "⚠️ No fswatch process found."
pkill -f watch_whisper.sh && log "✅ watch_whisper.sh process stopped." || log "⚠️ No watch_whisper.sh process found."

# ✅ Remove Installed Packages Based on `install-tracker.log`
while read -r package; do
    case "$package" in
        "whisper") log "🗑️ Removing Whisper..."; pip uninstall -y openai-whisper torch torchvision torchaudio ;;
        "ollama") log "🗑️ Removing Ollama..."; brew uninstall ollama ;;
        "mistral") log "🗑️ Removing Mistral model..."; ollama rm mistral ;;
        "fswatch") log "🗑️ Removing fswatch..."; brew uninstall fswatch ;;
        "venv") log "🗑️ Removing Python virtual environment..."; rm -rf "$VENV_DIR" ;;
    esac
done < "$INSTALL_TRACKER"

log "🛑 WhisperScribe has been uninstalled! If you want to remove everything, manually delete '$ROOT_DIR'."