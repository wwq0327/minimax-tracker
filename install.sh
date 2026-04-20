#!/bin/bash
# MiniMax Tracker Install Script

set -e

echo "=== MiniMax Tracker Installation ==="

# 1. Check mmx-cli
echo ""
echo "1. Checking mmx-cli..."
if command -v mmx &> /dev/null; then
    echo "   ✓ mmx-cli installed: $(mmx --version)"
else
    echo "   ✗ mmx-cli not found, installing..."
    npm install -g mmx-cli
    echo "   ✓ Installation complete"
fi

# 2. Check jq
echo ""
echo "2. Checking jq..."
if command -v jq &> /dev/null; then
    echo "   ✓ jq installed"
else
    echo "   ✗ jq not found, please install: brew install jq"
    exit 1
fi

# 3. Check environment variable
echo ""
echo "3. Checking MINIMAX_API_KEY..."
if [ -n "$MINIMAX_API_KEY" ]; then
    echo "   ✓ MINIMAX_API_KEY is set"
else
    echo "   ✗ MINIMAX_API_KEY not set"
    echo ""
    echo "   Please set the environment variable first:"
    echo '   export MINIMAX_API_KEY="sk-cp-your-key"'
    echo ""
    echo "   Add to ~/.zshrc or ~/.bashrc for permanent access"
    exit 1
fi

# 4. Create directory
echo ""
echo "4. Creating config directory..."
mkdir -p ~/.minimax-tracker
echo "   ✓ Directory: ~/.minimax-tracker"

# 5. Copy script
echo ""
echo "5. Copying script..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/status-bar.sh" ~/.minimax-tracker/
chmod +x ~/.minimax-tracker/status-bar.sh
echo "   ✓ Copied to ~/.minimax-tracker/status-bar.sh"

# 6. Configure Claude Code
echo ""
echo "6. Configuring Claude Code status bar..."
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    # Check if statusLine already exists
    if grep -q '"statusLine"' "$SETTINGS_FILE"; then
        echo "   ⚠ statusLine already exists, skipping"
    else
        # Add statusLine
        sed -i '' 's/"model": "haiku"/"model": "haiku",\n  "statusLine": {\n    "type": "command",\n    "command": "\/Users\/'"$USER"'\/.minimax-tracker\/status-bar.sh"\n  }/' "$SETTINGS_FILE"
        echo "   ✓ Added to $SETTINGS_FILE"
    fi
else
    echo "   ✗ settings.json not found, please configure manually"
fi

# 7. Test
echo ""
echo "7. Testing..."
~/.minimax-tracker/status-bar.sh

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Make sure MINIMAX_API_KEY is set, then restart Claude Code"
