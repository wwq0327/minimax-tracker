# MiniMax Tracker v0.2.0

Display MiniMax monthly subscription's 5-hour usage progress bar in Claude Code status bar.

[English](README_en.md) | [中文](README.md)

## Background

MiniMax is a monthly subscription with 5 hours of usage quota. Checking usage requires opening the website and refreshing, which is cumbersome.

Seeing the usage progress bar directly while working in Claude Code is more convenient. This script was created using vibe coding - describing requirements throughout without writing a single line of code manually.

## Features

- Real-time usage progress bar display
- Color levels (green below 50%, yellow below 80%, red above 80%)
- On-demand fetching (refreshes only when Claude Code is active)
- Uses official `mmx` CLI for accurate data

## Dependencies

- `mmx-cli` (npm install -g mmx-cli)
- `jq`
- Environment variable `MINIMAX_API_KEY`

## Installation

### 1. Set environment variable

```bash
export MINIMAX_API_KEY="sk-cp-your-key"
```

Add to `~/.zshrc` or `~/.bashrc` for permanent access:

```bash
echo 'export MINIMAX_API_KEY="sk-cp-your-key"' >> ~/.zshrc
```

### 2. Run install script

```bash
./install.sh
```

### 3. Restart Claude Code

## Configuration

- API Key is read from environment variable `MINIMAX_API_KEY` (not hardcoded)
- Script saved at `~/.minimax-tracker/status-bar.sh`
- Data cached at `~/.minimax-tracker/usage.json`

## Progress Bar Style

```
MiniMax: [██░░░░░░░░░░░░░░░░░] 30% 450/1500 (2h until reset, 0min ago)
```

## Color Levels

| Usage | Color |
|-------|-------|
| 0-50% | Green |
| 51-80% | Yellow |
| 81%+ | Red |

## Uninstall

1. Remove `statusLine` config from `~/.claude/settings.json`
2. Delete `~/.minimax-tracker/` directory
