#!/bin/bash
# MiniMax/DeepSeek Tracker v0.3.0
# Display MiniMax usage and/or DeepSeek balance in Claude Code status bar

VERSION="0.3.0"
DATA_DIR="$HOME/.minimax-tracker"
MM_DATA_FILE="$DATA_DIR/usage.json"
DS_DATA_FILE="$DATA_DIR/ds_balance.json"
DS_DAILY_FILE="$DATA_DIR/ds_daily.json"
API_KEY="${MINIMAX_API_KEY:-}"
DS_API_KEY="${DEEPSEEK_API_KEY:-${ANTHROPIC_AUTH_TOKEN:-}}"
MODEL_FILTER='^MiniMax-M'
REFRESH_INTERVAL_MINUTES=3

# Which services are configured
has_minimax() { [[ -n "$API_KEY" ]]; }
has_deepseek() { [[ -n "$DS_API_KEY" ]]; }

# ── MiniMax ──────────────────────────────────────────────

# Fetch MiniMax usage via mmx quota show
fetch_minimax() {
    [[ -z "$API_KEY" ]] && return 1
    response=$(mmx quota show --output json)
    [[ -z "$response" ]] && echo "MiniMax: mmx returned empty response" >&2 && return 1

    used=$(echo "$response" | jq -r --arg model "$MODEL_FILTER" '
        [.model_remains[] | select(
            (.model_name | test($model))
        ) | .current_interval_usage_count] | add // 0
    ' 2>/dev/null)

    total=$(echo "$response" | jq -r --arg model "$MODEL_FILTER" '
        [.model_remains[] | select(
            (.model_name | test($model))
        ) | .current_interval_total_count] | add // 0
    ' 2>/dev/null)

    remains_ms=$(echo "$response" | jq -r --arg model "$MODEL_FILTER" '
        [.model_remains[] | select(.model_name | test($model)) | .remains_time] | add // 0
    ' 2>/dev/null)

    [[ -z "$used" || "$used" == "null" || -z "$total" || "$total" == "null" || "$total" -eq 0 || -z "$remains_ms" || "$remains_ms" == "null" ]] && echo "MiniMax: failed to parse mmx response" >&2 && return 1

    secs=$(( remains_ms / 1000 ))
    h=$(( secs / 3600 ))
    m=$(( (secs % 3600) / 60 ))
    [[ $h -gt 0 ]] && reset_in="${h}小时${m}分" || reset_in="${m}分"

    echo "{\"used\":$used,\"total\":$total,\"reset_in\":\"$reset_in\",\"updated\":\"$(date '+%Y-%m-%d %H:%M')\"}" > "$MM_DATA_FILE.tmp" && mv "$MM_DATA_FILE.tmp" "$MM_DATA_FILE"
}

# Render MiniMax progress bar
render_minimax() {
    PERCENT=$(awk -v used="$1" -v total="$2" 'BEGIN {printf "%.0f", (total > 0) ? used * 100 / total : 0}')
    BAR_LEN=20
    FILL_LEN=$((PERCENT * BAR_LEN / 100))
    [[ $FILL_LEN -gt $BAR_LEN ]] && FILL_LEN=$BAR_LEN
    EMPTY_LEN=$((BAR_LEN - FILL_LEN))
    BAR=$(printf "%${FILL_LEN}s" | tr ' ' '█')
    EMPTY=$(printf "%${EMPTY_LEN}s" | tr ' ' '░')

    if [[ $PERCENT -le 50 ]]; then
        STATUS="LOW"
    elif [[ $PERCENT -le 80 ]]; then
        STATUS="MED"
    else
        STATUS="HIGH"
    fi

    echo -n "MiniMax: [${BAR}${EMPTY}] ${PERCENT}% ${STATUS} $1/$2"
    if [[ -n "$3" && "$3" != "null" ]]; then
        echo " (${3}后重置)"
    fi
}

# ── DeepSeek ─────────────────────────────────────────────

# Fetch DeepSeek balance via API
fetch_deepseek() {
    [[ -z "$DS_API_KEY" ]] && return 1
    response=$(curl -s -L -X GET 'https://api.deepseek.com/user/balance' \
        -H 'Accept: application/json' \
        -H "Authorization: Bearer $DS_API_KEY" 2>/dev/null)
    [[ -z "$response" ]] && echo "DeepSeek: API returned empty response" >&2 && return 1

    available=$(echo "$response" | jq -r '.is_available // false' 2>/dev/null)
    balance=$(echo "$response" | jq -r '.balance_infos[0].total_balance // empty' 2>/dev/null)
    currency=$(echo "$response" | jq -r '.balance_infos[0].currency // empty' 2>/dev/null)

    [[ "$available" != "true" || -z "$balance" ]] && echo "DeepSeek: failed to parse balance" >&2 && return 1

    echo "{\"balance\":\"$balance\",\"currency\":\"$currency\",\"updated\":\"$(date '+%Y-%m-%d %H:%M')\"}" > "$DS_DATA_FILE.tmp" && mv "$DS_DATA_FILE.tmp" "$DS_DATA_FILE"

    # Update daily record
    today=$(date '+%Y-%m-%d')
    if [[ -f "$DS_DAILY_FILE" ]]; then
        daily=$(cat "$DS_DAILY_FILE")
    else
        daily="{}"
    fi
    daily=$(echo "$daily" | jq --arg d "$today" --arg b "$balance" '. + {($d): $b}' | jq 'to_entries | sort_by(.key) | .[-7:] | from_entries')
    echo "$daily" > "$DS_DAILY_FILE.tmp" && mv "$DS_DAILY_FILE.tmp" "$DS_DAILY_FILE"
}

# Render DeepSeek balance
render_deepseek() {
    result="DeepSeek: ¥$1"
    if [[ -f "$DS_DAILY_FILE" ]]; then
        today=$(date '+%Y-%m-%d')
        prev_balance=$(jq -r --arg t "$today" 'to_entries | sort_by(.key) | .[] | select(.key != $t) | .value' "$DS_DAILY_FILE" 2>/dev/null | tail -1)
        if [[ -n "$prev_balance" && "$prev_balance" != "null" ]]; then
            diff=$(awk -v cur="$1" -v prev="$prev_balance" 'BEGIN {printf "%.2f", cur - prev}')
            if awk -v d="$diff" 'BEGIN {exit !(d > 0)}'; then
                result="$result (↑¥${diff})"
            elif awk -v d="$diff" 'BEGIN {exit !(d < 0)}'; then
                result="$result (↓¥${diff#-})"
            fi
        fi
    fi
    echo -n "$result"
}

# ── Shared ───────────────────────────────────────────────

parse_timestamp() {
    if [[ "$(uname)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d %H:%M" "$1" +%s 2>/dev/null
    else
        date -d "$1" +%s 2>/dev/null
    fi
}

data_age_minutes() {
    [[ -z "$1" || "$1" == "null" ]] && echo "?" && return
    last_ts=$(parse_timestamp "$1")
    [[ -z "$last_ts" ]] && echo "?" && return
    now_ts=$(date +%s)
    diff=$((now_ts - last_ts))
    [[ $diff -lt 0 ]] && diff=0
    echo $((diff / 60))
}

# ── Main ─────────────────────────────────────────────────

if ! has_minimax && ! has_deepseek; then
    exit 0
fi

mkdir -p "$DATA_DIR"

# Determine which service is active based on current model
ACTIVE_SERVICE=""
current_model="${ANTHROPIC_MODEL:-}"
if [[ "$current_model" == *deepseek* ]]; then
    has_deepseek && ACTIVE_SERVICE="deepseek"
elif [[ "$current_model" == *MiniMax* || "$current_model" == *minimax* ]]; then
    has_minimax && ACTIVE_SERVICE="minimax"
fi
# Fallback: if model doesn't match either, prefer whichever key is set
if [[ -z "$ACTIVE_SERVICE" ]]; then
    if has_deepseek; then
        ACTIVE_SERVICE="deepseek"
    elif has_minimax; then
        ACTIVE_SERVICE="minimax"
    fi
fi

# First run: fetch immediately
if [[ "$ACTIVE_SERVICE" == "minimax" && ! -f "$MM_DATA_FILE" ]]; then
    fetch_minimax
fi
if [[ "$ACTIVE_SERVICE" == "deepseek" && ! -f "$DS_DATA_FILE" ]]; then
    fetch_deepseek
fi

# Read cache
if [[ "$ACTIVE_SERVICE" == "minimax" ]]; then
    MM_USED=$(jq -r '.used // empty' "$MM_DATA_FILE" 2>/dev/null)
    MM_TOTAL=$(jq -r '.total // empty' "$MM_DATA_FILE" 2>/dev/null)
    MM_RESET=$(jq -r '.reset_in // empty' "$MM_DATA_FILE" 2>/dev/null)
    MM_UPDATED=$(jq -r '.updated // empty' "$MM_DATA_FILE" 2>/dev/null)
elif [[ "$ACTIVE_SERVICE" == "deepseek" ]]; then
    DS_BALANCE=$(jq -r '.balance // empty' "$DS_DATA_FILE" 2>/dev/null)
    DS_UPDATED=$(jq -r '.updated // empty' "$DS_DATA_FILE" 2>/dev/null)
fi

# Determine if refresh is needed
mm_refresh=false
ds_refresh=false
if [[ "$ACTIVE_SERVICE" == "minimax" && -n "$MM_UPDATED" && "$MM_UPDATED" != "null" ]]; then
    age=$(data_age_minutes "$MM_UPDATED")
    [[ "$age" != "?" ]] && [[ $age -ge $REFRESH_INTERVAL_MINUTES ]] && mm_refresh=true
fi
if [[ "$ACTIVE_SERVICE" == "deepseek" && -n "$DS_UPDATED" && "$DS_UPDATED" != "null" ]]; then
    age=$(data_age_minutes "$DS_UPDATED")
    [[ "$age" != "?" ]] && [[ $age -ge $REFRESH_INTERVAL_MINUTES ]] && ds_refresh=true
fi

# Build output
output=""
if [[ "$ACTIVE_SERVICE" == "minimax" ]]; then
    if [[ -z "$MM_USED" || "$MM_USED" == "null" || -z "$MM_TOTAL" || "$MM_TOTAL" == "null" ]]; then
        output="MiniMax: --"
    else
        output=$(render_minimax "$MM_USED" "$MM_TOTAL" "$MM_RESET")
    fi
elif [[ "$ACTIVE_SERVICE" == "deepseek" ]]; then
    if [[ -z "$DS_BALANCE" || "$DS_BALANCE" == "null" ]]; then
        output="DeepSeek: --"
    else
        output="$(render_deepseek "$DS_BALANCE")"
    fi
fi

# Add age info
age="?"
if [[ "$ACTIVE_SERVICE" == "minimax" && -n "$MM_UPDATED" ]]; then
    age=$(data_age_minutes "$MM_UPDATED")
elif [[ "$ACTIVE_SERVICE" == "deepseek" && -n "$DS_UPDATED" ]]; then
    age=$(data_age_minutes "$DS_UPDATED")
fi
age_str=$([[ "$age" == "?" ]] && echo "未知前" || echo "${age}分钟前")

echo "${output} (${age_str})"

# Background refresh
$mm_refresh && fetch_minimax &
$ds_refresh && fetch_deepseek &
wait

exit 0
