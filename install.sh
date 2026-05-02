#!/bin/bash
# MiniMax/DeepSeek Tracker Install Script

set -e

echo "=== MiniMax/DeepSeek Tracker Installation ==="

# 1. Check environment variables
echo ""
echo "1. Checking API keys..."
has_mm=false
has_ds=false
[ -n "$MINIMAX_API_KEY" ] && has_mm=true
[ -n "$DEEPSEEK_API_KEY" ] && has_ds=true

if ! $has_mm && ! $has_ds; then
    echo "   ✗ Neither MINIMAX_API_KEY nor DEEPSEEK_API_KEY is set"
    echo ""
    echo "   Set at least one:"
    echo '   export MINIMAX_API_KEY="sk-cp-your-key"'
    echo '   export DEEPSEEK_API_KEY="sk-your-key"'
    echo ""
    echo "   Add to ~/.zshrc or ~/.bashrc for permanent access"
    exit 1
fi
$has_mm && echo "   ✓ MINIMAX_API_KEY is set"
$has_ds && echo "   ✓ DEEPSEEK_API_KEY is set"

# 2. Check mmx-cli (only if MiniMax key is set)
if $has_mm; then
    echo ""
    echo "2. Checking mmx-cli..."
    if command -v mmx &> /dev/null; then
        echo "   ✓ mmx-cli installed: $(mmx --version)"
    else
        echo "   ✗ mmx-cli not found, installing..."
        npm install -g mmx-cli
        echo "   ✓ Installation complete"
    fi
    step=3
else
    step=2
fi

# N. Check jq
echo ""
echo "$step. Checking jq..."
if command -v jq &> /dev/null; then
    echo "   ✓ jq installed"
else
    echo "   ✗ jq not found, please install: brew install jq"
    exit 1
fi
step=$((step + 1))

# N+1. Create directory
echo ""
echo "$step. Creating config directory..."
mkdir -p ~/.minimax-tracker
echo "   ✓ Directory: ~/.minimax-tracker"

# N+2. Copy script
echo ""
echo "$((step + 1)). Copying script..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/status-bar.sh" ~/.minimax-tracker/
chmod +x ~/.minimax-tracker/status-bar.sh
echo "   ✓ Copied to ~/.minimax-tracker/status-bar.sh"

# N+3. Configure Claude Code
echo ""
echo "$((step + 2)). Configuring Claude Code status bar..."
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    if grep -q '"statusLine"' "$SETTINGS_FILE"; then
        echo "   ⚠ statusLine already exists, skipping"
    else
        USER_ESC=$(printf '%s\n' "$USER" | sed 's/[\/&]/\\&/g')
        SED_CMD='s/"model": "haiku"/"model": "haiku",\n  "statusLine": {\n    "type": "command",\n    "command": "\/Users\/'"$USER_ESC"'\/.minimax-tracker\/status-bar.sh"\n  }/'
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' -e "$SED_CMD" "$SETTINGS_FILE"
        else
            sed -i -e "$SED_CMD" "$SETTINGS_FILE"
        fi
        echo "   ✓ Added to $SETTINGS_FILE"
    fi
else
    echo "   ✗ settings.json not found, please configure manually"
fi

# N+4. Test
echo ""
echo "$((step + 3)). Testing..."
~/.minimax-tracker/status-bar.sh || echo "   ⚠ Test produced non-zero exit (see above)"

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Restart Claude Code to see the status bar."
echo "To add another service later, set its API key and re-run this script."
