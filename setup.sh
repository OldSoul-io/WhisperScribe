#!/bin/bash

ROOT_DIR="$HOME/WhisperScribe"
SCRIPTS_DIR="$ROOT_DIR/scripts"
LOGS_DIR="$ROOT_DIR/logs"
OUTPUT_DIR="$ROOT_DIR/transcripts"
ARCHIVE_DIR="$ROOT_DIR/archive"
VENV_DIR="$ROOT_DIR/whisper-env"
WATCH_SCRIPT="$SCRIPTS_DIR/watch_whisper.sh"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.user.fswatch.whisper.plist"

mkdir -p "$SCRIPTS_DIR" "$LOGS_DIR" "$OUTPUT_DIR" "$ARCHIVE_DIR"

echo "📦 Setting up WhisperScribe on macOS..."

# ✅ Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "🔧 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew already installed."
fi

# ✅ Install Python 3.11
if ! brew list python@3.11 &>/dev/null; then
    echo "🔧 Installing Python 3.11..."
    brew install python@3.11
else
    echo "✅ Python 3.11 already installed."
fi

PYTHON_BIN="$(brew --prefix python@3.11)/bin/python3.11"

# ✅ Create Virtual Environment
if [ ! -d "$VENV_DIR" ]; then
    echo "🛠 Creating Python virtual environment..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# ✅ Install Whisper & Dependencies
if ! pip show openai-whisper &>/dev/null; then
    echo "⬇️ Installing Whisper and PyTorch..."
    pip install --upgrade pip setuptools wheel
    pip install openai-whisper
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
else
    echo "✅ Whisper already installed."
fi

# ✅ Install Ollama
if ! command -v ollama &>/dev/null; then
    echo "⬇️ Installing Ollama..."
    brew install ollama
else
    echo "✅ Ollama already installed."
fi

# ✅ Pull the Mistral Model for Summarization
if ! ollama list | grep -q "mistral"; then
    echo "⬇️ Downloading Ollama model (mistral)..."
    ollama pull mistral
else
    echo "✅ Mistral model already downloaded."
fi

# ✅ Install fswatch
if ! command -v fswatch &>/dev/null; then
    echo "⬇️ Installing fswatch..."
    brew install fswatch
else
    echo "✅ fswatch already installed."
fi

# ✅ Copy scripts
cp "$(dirname "$0")/scripts/watch_whisper.sh" "$WATCH_SCRIPT"
chmod +x "$WATCH_SCRIPT"

# ✅ Set up LaunchAgent for automatic startup
cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.user.fswatch.whisper</string>
        <key>ProgramArguments</key>
        <array>
            <string>$WATCH_SCRIPT</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>$LOGS_DIR/fswatch.log</string>
        <key>StandardErrorPath</key>
        <string>$LOGS_DIR/fswatch_error.log</string>
    </dict>
</plist>
EOF

launchctl load "$LAUNCH_AGENT"

echo "🎉 WhisperScribe Setup Complete! Drop audio files into $ROOT_DIR to start processing."

echo "The Setup Script is being moved into the scripts directory, and can be re-run if needed."
mv ./setup.sh ./scripts/
echo "Setup Script has been successfully moved."
echo "<end/>"
