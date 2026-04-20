#!/bin/bash
# MiniMax Tracker v0.1.0
# Display MiniMax usage progress bar in Claude Code status bar
# Uses mmx quota show to get accurate data

VERSION="0.1.0"
DATA_FILE="$HOME/.minimax-tracker/usage.json"
API_KEY="${MINIMAX_API_KEY:-}"

# Read cached data
read_data() {
    USED=$(jq -r '.used' "$DATA_FILE" 2>/dev/null)
    TOTAL=$(jq -r '.total' "$DATA_FILE" 2>/dev/null)
    RESET_IN=$(jq -r '.reset_in' "$DATA_FILE" 2>/dev/null)
    UPDATED=$(jq -r '.updated' "$DATA_FILE" 2>/dev/null)
}

# Fetch new data via mmx quota show
do_fetch() {
    [[ -z "$API_KEY" ]] && return 1
    response=$(mmx quota show --api-key "$API_KEY" --output json 2>/dev/null)

    [[ -z "$response" ]] && return 1

    # Parse mmx output - filter MiniMax-M* text model
    used=$(echo "$response" | jq -r '
        [.model_remains[] | select(
            (.model_name | test("MiniMax-M"))
        ) | .current_interval_usage_count] | add
    ' 2>/dev/null)

    total=1500

    # remains_time is in milliseconds
    remains_ms=$(echo "$response" | jq -r '.model_remains[] | select(.model_name | test("MiniMax-M")) | .remains_time' 2>/dev/null)

    [[ -z "$used" || "$used" == "null" || -z "$remains_ms" ]] && return 1

    # Calculate reset time
    secs=$(( remains_ms / 1000 ))
    h=$(( secs / 3600 ))
    m=$(( (secs % 3600) / 60 ))
    [[ $h -gt 0 ]] && reset_in="${h}小时${m}分" || reset_in="${m}分"

    # Write to cache
    echo "{\"used\":$used,\"total\":$total,\"reset_in\":\"$reset_in\",\"updated\":\"$(date '+%Y-%m-%d %H:%M')\"}" > "$DATA_FILE"
}

# Calculate data age in minutes
data_age_minutes() {
    [[ -z "$UPDATED" || "$UPDATED" == "null" ]] && echo "?" && return
    last_ts=$(date -j -f "%Y-%m-%d %H:%M" "$UPDATED" +%s 2>/dev/null)
    [[ -z "$last_ts" ]] && echo "?" && return
    now_ts=$(date +%s)
    echo $(( (now_ts - last_ts) / 60 ))
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
    last_ts=$(date -j -f "%Y-%m-%d %H:%M" "$UPDATED" +%s 2>/dev/null)
    if [[ -n "$last_ts" ]]; then
        now_ts=$(date +%s)
        diff_minutes=$(( (now_ts - last_ts) / 60 ))
        [[ $diff_minutes -ge 3 ]] && need_refresh=true
    fi
fi

# Calculate percentage
PERCENT=$((TOTAL > 0 ? USED * 100 / TOTAL : 0))

# Choose color based on percentage
if [[ $PERCENT -le 50 ]]; then
    COLOR='\033[32m'      # Green
elif [[ $PERCENT -le 80 ]]; then
    COLOR='\033[33m'      # Yellow
elif [[ $PERCENT -le 90 ]]; then
    COLOR='\033[33m'      # Yellow
else
    COLOR='\033[31m'      # Red
fi
COLOR_RESET='\033[0m'

# Progress bar
BAR_LEN=20
FILL_LEN=$((PERCENT * BAR_LEN / 100))
EMPTY_LEN=$((BAR_LEN - FILL_LEN))
BAR=$(printf '%*s' "$FILL_LEN" | tr ' ' '█')
EMPTY=$(printf '%*s' "$EMPTY_LEN" | tr ' ' '░')

# Display
age=$(data_age_minutes)
if [[ -n "$RESET_IN" && "$RESET_IN" != "null" ]]; then
    echo -e "MiniMax: [${COLOR}${BAR}${COLOR_RESET}${EMPTY}] ${PERCENT}% ${USED}/${TOTAL} (${RESET_IN}后重置, ${age}分钟前)"
else
    echo -e "MiniMax: [${COLOR}${BAR}${COLOR_RESET}${EMPTY}] ${PERCENT}% ${USED}/${TOTAL} (${age}分钟前)"
fi

# Refresh on demand (older than 3 minutes or no data)
[[ "$need_refresh" == "true" ]] && do_fetch
exit 0
