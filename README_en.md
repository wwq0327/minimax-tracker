# MiniMax/DeepSeek Tracker v0.3.0

Display MiniMax usage or DeepSeek balance in Claude Code status bar.

## Features

- MiniMax usage progress bar + status levels
- DeepSeek balance display + daily diff (compared with last balance from previous day)
- Auto-switch based on current model (deepseek → DeepSeek, minimax → MiniMax)
- On-demand fetching (refreshes when stale, every 3 minutes)
- Uses official APIs for accurate data

## Dependencies

- `mmx-cli` (MiniMax only)
- `jq`
- At least one of `MINIMAX_API_KEY` or `DEEPSEEK_API_KEY`

## Installation

### 1. Set environment variable

```bash
# MiniMax
export MINIMAX_API_KEY="sk-cp-your-key"

# DeepSeek
export DEEPSEEK_API_KEY="sk-your-key"
```

### 2. Run install script

```bash
./install.sh
```

### 3. Restart Claude Code

## Display

```
# MiniMax (when current model is MiniMax)
MiniMax: [████░░░░] 30% LOW 450/1500 (50min until reset) (3min ago)

# DeepSeek (when current model is DeepSeek)
DeepSeek: ¥121.50 (3min ago)

# DeepSeek with daily diff
DeepSeek: ¥120.38 (↓¥1.62) (3min ago)   # Balance decreased (usage)
DeepSeek: ¥130.00 (↑¥10.00) (3min ago)  # Balance increased (top-up)
```

## DeepSeek Daily Diff

- Balance is recorded per day in `~/.minimax-tracker/ds_daily.json` (last 7 days kept)
- Diff is calculated against the most recent non-today balance
- Decrease shown as `↓¥x.xx`, increase as `↑¥x.xx`, no change or no history → hidden

## Data Files (~/.minimax-tracker/)

| File | Description |
|------|-------------|
| `usage.json` | MiniMax usage cache |
| `ds_balance.json` | DeepSeek balance cache |
| `ds_daily.json` | DeepSeek daily balance record (7 days) |

## Env vars

| Variable | Service |
|----------|---------|
| `MINIMAX_API_KEY` | MiniMax |
| `DEEPSEEK_API_KEY` | DeepSeek |

At least one required.

## Uninstall

1. Remove `statusLine` config from `~/.claude/settings.json`
2. Delete `~/.minimax-tracker/` directory
