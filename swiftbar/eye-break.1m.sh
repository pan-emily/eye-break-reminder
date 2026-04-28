#!/bin/zsh
set -eu

PATH="/usr/bin:/bin:/usr/sbin:/sbin"

label="com.local.eye-break-reminder"
interval_seconds=1800
script_path="$0"
state_dir="$HOME/.local/state/eye-break-reminder"
reminder_script="$HOME/.local/bin/eye-break-reminder.sh"
domain="gui/$(/usr/bin/id -u)"
plist="$HOME/Library/LaunchAgents/$label.plist"

is_enabled() {
  /bin/launchctl print "$domain/$label" >/dev/null 2>&1
}

next_break_text() {
  local now ref next remaining minutes

  now=$(/bin/date +%s)

  if [[ -f "$state_dir/last_start_at" ]]; then
    ref=$(<"$state_dir/last_start_at")
  elif [[ -f "$state_dir/enabled_at" ]]; then
    ref=$(<"$state_dir/enabled_at")
  else
    ref="$now"
  fi

  next=$((ref + interval_seconds))
  while (( next <= now )); do
    next=$((next + interval_seconds))
  done

  remaining=$((next - now))
  minutes=$(((remaining + 59) / 60))

  if (( minutes <= 1 )); then
    echo "about 1 minute"
  else
    echo "about $minutes minutes"
  fi
}

pause_reminder() {
  /bin/launchctl bootout "$domain" "$plist" 2>/dev/null || true
}

resume_reminder() {
  if [[ ! -f "$plist" ]]; then
    /usr/bin/osascript -e 'display notification "Eye break reminder is not installed yet." with title "Eye break" sound name "Basso"'
    exit 1
  fi

  /bin/mkdir -p "$state_dir"
  /bin/date +%s > "$state_dir/enabled_at"
  pause_reminder
  /bin/launchctl bootstrap "$domain" "$plist"
}

run_now() {
  if [[ -x "$reminder_script" ]]; then
    "$reminder_script" >/dev/null 2>&1 &
  else
    /usr/bin/osascript -e 'display notification "Eye break reminder script was not found." with title "Eye break" sound name "Basso"'
  fi
}

case "${1:-menu}" in
  pause)
    pause_reminder
    exit 0
    ;;
  resume)
    resume_reminder
    exit 0
    ;;
  run-now)
    run_now
    exit 0
    ;;
esac

if is_enabled; then
  next_text="$(next_break_text)"
  echo "Eye ${next_text#about }"
  echo "---"
  echo "Status: ON"
  echo "Next break: $next_text"
  echo "---"
  echo "Pause | bash=\"$script_path\" param1=pause terminal=false refresh=true"
  echo "Run now | bash=\"$script_path\" param1=run-now terminal=false refresh=true"
else
  echo "Eye Off"
  echo "---"
  echo "Status: OFF"
  echo "---"
  echo "Resume | bash=\"$script_path\" param1=resume terminal=false refresh=true"
fi

echo "---"
echo "Open installed scripts | bash=\"/usr/bin/open\" param1=\"$HOME/.local/bin\" terminal=false"
echo "Refresh | refresh=true"
