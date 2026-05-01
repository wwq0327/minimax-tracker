#!/bin/bash
# MiniMax Tracker v0.2.0
# Display MiniMax usage progress bar in Claude Code status bar
# Uses mmx quota show to get accurate data

VERSION="0.2.0"
DATA_FILE="$HOME/.minimax-tracker/usage.json"
API_KEY="${MINIMAX_API_KEY:-}"
MODEL_FILTER='^MiniMax-M'
REFRESH_INTERVAL_MINUTES=3

# Read cached data
read_data() {
    USED=$(jq -r '.used' "$DATA_FILE" 2>/dev/null)
    TOTAL=$(jq -r '.total' "$DATA_FILE" 2>/dev/null)
    RESET_IN=$(jq -r '.reset_in' "$DATA_FILE" 2>/dev/null)
    UPDATED=$(jq -r '.updated' "$DATA_FILE" 2>/dev/null)
}

# Fetch new data via mmx quota show
do_fetch() {
    [[ -z "$API_KEY" ]] && echo "MiniMax: API key not set" >&2 && return 1
    response=$(mmx quota show --output json)
    [[ -z "$response" ]] && echo "MiniMax: mmx returned empty response" >&2 && return 1

    # Parse mmx output - filter MiniMax-M text model
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

    # remains_time is in milliseconds
    remains_ms=$(echo "$response" | jq -r --arg model "$MODEL_FILTER" '
        [.model_remains[] | select(.model_name | test($model)) | .remains_time] | add // 0
    ' 2>/dev/null)

    [[ -z "$used" || "$used" == "null" || -z "$total" || "$total" == "null" || "$total" -eq 0 || -z "$remains_ms" || "$remains_ms" == "null" ]] && echo "MiniMax: failed to parse mmx response" >&2 && return 1

    # Calculate reset time
    secs=$(( remains_ms / 1000 ))
    h=$(( secs / 3600 ))
    m=$(( (secs % 3600) / 60 ))
    [[ $h -gt 0 ]] && reset_in="${h}小时${m}分" || reset_in="${m}分"

    # Write to cache (atomic write)
    echo "{\"used\":$used,\"total\":$total,\"reset_in\":\"$reset_in\",\"updated\":\"$(date '+%Y-%m-%d %H:%M')\"}" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
}

# Parse timestamp to seconds (macOS: date -j -f; Linux: date -d)
parse_timestamp() {
    if [[ "$(uname)" == "Darwin" ]]; then
        date -j -f "%Y-%m-%d %H:%M" "$1" +%s 2>/dev/null
    else
        date -d "$1" +%s 2>/dev/null
    fi
}

# Calculate data age in minutes
data_age_minutes() {
    [[ -z "$UPDATED" || "$UPDATED" == "null" ]] && echo "?" && return
    last_ts=$(parse_timestamp "$UPDATED")
    [[ -z "$last_ts" ]] && echo "?" && return
    now_ts=$(date +%s)
    diff=$((now_ts - last_ts))
    [[ $diff -lt 0 ]] && diff=0  # guard against clock skew
    echo $((diff / 60))
}

# Main logic
if [[ ! -f "$DATA_FILE" ]]; then
    echo "MiniMax: --"
    do_fetch
    exit 0
fi

read_data

if [[ -z "$USED" || "$USED" == "null" || -z "$TOTAL" || "$TOTAL" == "null" ]]; then
    echo "MiniMax: --"
    do_fetch
    exit 0
fi

# Check if refresh is needed (older than 3 minutes)
need_refresh=false
if [[ -n "$UPDATED" && "$UPDATED" != "null" ]]; then
    last_ts=$(parse_timestamp "$UPDATED")
    if [[ -n "$last_ts" ]]; then
        now_ts=$(date +%s)
        diff=$((now_ts - last_ts))
        [[ $diff -lt 0 ]] && diff=0
        diff_minutes=$((diff / 60))
        [[ $diff_minutes -ge $REFRESH_INTERVAL_MINUTES ]] && need_refresh=true
    fi
fi

# Calculate percentage (use awk for decimal precision)
PERCENT=$(awk -v used="$USED" -v total="$TOTAL" 'BEGIN {printf "%.0f", (total > 0) ? used * 100 / total : 0}')

# Progress bar
BAR_LEN=20
FILL_LEN=$((PERCENT * BAR_LEN / 100))
[[ $FILL_LEN -gt $BAR_LEN ]] && FILL_LEN=$BAR_LEN
EMPTY_LEN=$((BAR_LEN - FILL_LEN))
BAR=$(printf "%${FILL_LEN}s" | tr ' ' '█')
EMPTY=$(printf "%${EMPTY_LEN}s" | tr ' ' '░')

# Status indicator based on percentage
if [[ $PERCENT -le 50 ]]; then
    STATUS="LOW"
elif [[ $PERCENT -le 80 ]]; then
    STATUS="MED"
else
    STATUS="HIGH"
fi

# Display
age=$(data_age_minutes)
age_str=$([[ "$age" == "?" ]] && echo "未知前" || echo "${age}分钟前")
if [[ -n "$RESET_IN" && "$RESET_IN" != "null" ]]; then
    echo "MiniMax: [${BAR}${EMPTY}] ${PERCENT}% ${STATUS} ${USED}/${TOTAL} (${RESET_IN}后重置, ${age_str})"
else
    echo "MiniMax: [${BAR}${EMPTY}] ${PERCENT}% ${STATUS} ${USED}/${TOTAL} (${age_str})"
fi

# Refresh on demand (older than 3 minutes or no data)
[[ "$need_refresh" == "true" ]] && do_fetch
exit 0
