#!/bin/bash

ROOT_DIR="$HOME/WhisperScribe"
SCRIPTS_DIR="$ROOT_DIR/scripts"
LOGS_DIR="$ROOT_DIR/logs"
OUTPUT_DIR="$ROOT_DIR/transcripts"
ARCHIVE_DIR="$ROOT_DIR/archive"
VENV_DIR="$ROOT_DIR/whisper-env"
WATCH_SCRIPT="$SCRIPTS_DIR/watch_whisper.sh"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.user.fswatch.whisper.plist"
INSTALL_TRACKER="$LOGS_DIR/install-tracker.log"

mkdir -p "$SCRIPTS_DIR" "$LOGS_DIR" "$OUTPUT_DIR" "$ARCHIVE_DIR"

# ✅ Log Function with Timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGS_DIR/setup.log"
}

log "📦 Setting up WhisperScribe on macOS..."
echo "" > "$INSTALL_TRACKER"  # Start fresh install tracking

# ✅ Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    log "🔧 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "homebrew" >> "$INSTALL_TRACKER"
else
    log "✅ Homebrew already installed."
fi

# ✅ Install Python 3.11
if ! brew list python@3.11 &>/dev/null; then
    log "🔧 Installing Python 3.11..."
    brew install python@3.11
    echo "python@3.11" >> "$INSTALL_TRACKER"
else
    log "✅ Python 3.11 already installed."
fi

PYTHON_BIN="$(brew --prefix python@3.11)/bin/python3.11"

# ✅ Create Virtual Environment
if [ ! -d "$VENV_DIR" ]; then
    log "🛠 Creating Python virtual environment..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
    echo "venv" >> "$INSTALL_TRACKER"
fi

source "$VENV_DIR/bin/activate"

# ✅ Install Whisper & Dependencies
if ! pip show openai-whisper &>/dev/null; then
    log "⬇️ Installing Whisper and PyTorch..."
    pip install --upgrade pip setuptools wheel
    pip install openai-whisper
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    echo "whisper" >> "$INSTALL_TRACKER"
else
    log "✅ Whisper already installed."
fi

# ✅ Install Ollama
if ! command -v ollama &>/dev/null; then
    log "⬇️ Installing Ollama..."
    brew install ollama
    echo "ollama" >> "$INSTALL_TRACKER"
else
    log "✅ Ollama already installed."
fi

# ✅ Pull the Mistral Model for Summarization
if ! ollama list | grep -q "mistral"; then
    log "⬇️ Downloading Ollama model (mistral)..."
    ollama pull mistral
    echo "mistral" >> "$INSTALL_TRACKER"
else
    log "✅ Mistral model already downloaded."
fi

# ✅ Install fswatch
if ! command -v fswatch &>/dev/null; then
    log "⬇️ Installing fswatch..."
    brew install fswatch
    echo "fswatch" >> "$INSTALL_TRACKER"
else
    log "✅ fswatch already installed."
fi

# ✅ Ensure watch_whisper.sh is in place
if [ ! -f "$WATCH_SCRIPT" ]; then
    log "📂 Copying watch_whisper.sh into scripts directory..."
    cp "$(dirname "$0")/scripts/watch_whisper.sh" "$WATCH_SCRIPT"
else
    log "✅ watch_whisper.sh already exists, skipping copy."
fi
chmod +x "$WATCH_SCRIPT"

# ✅ Unload and remove any previous LaunchAgent to prevent duplicates
if launchctl list | grep -q "com.user.fswatch.whisper"; then
    log "🛑 Unloading existing WhisperScribe watcher..."
    launchctl unload "$LAUNCH_AGENT"
fi

rm -f "$LAUNCH_AGENT"

# ✅ Create a fresh LaunchAgent
log "📂 Creating LaunchAgent for automatic startup..."
cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.user.fswatch.whisper</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/bash</string>
            <string>-c</string>
            <string>if ! pgrep -f watch_whisper.sh > /dev/null; then /Users/oldsoul/WhisperScribe/scripts/watch_whisper.sh; fi</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>StandardOutPath</key>
        <string>$LOGS_DIR/fswatch.log</string>
        <key>StandardErrorPath</key>
        <string>$LOGS_DIR/fswatch_error.log</string>
    </dict>
</plist>
EOF
log "✅ LaunchAgent created."

# ✅ Load the LaunchAgent
log "🚀 Loading new LaunchAgent..."
launchctl load "$LAUNCH_AGENT" && log "✅ LaunchAgent successfully loaded!" || log "❌ Failed to load LaunchAgent!"

# ✅ Make uninstall script executable for easier removal
chmod +x "$ROOT_DIR/uninstall.sh"

# ✅ Move setup.sh to scripts directory after installation
if [ "$0" != "$SCRIPTS_DIR/setup.sh" ]; then
    log "📦 Moving setup.sh to scripts directory..."
    mv "$0" "$SCRIPTS_DIR/setup.sh"
fi

log "🎉 WhisperScribe Setup Complete! Drop audio files into $ROOT_DIR to start processing."