#!/bin/zsh
set -eu

label="com.local.eye-break-reminder"
script_dir="$HOME/.local/bin"
script_path="$script_dir/eye-break-reminder.sh"
toggle_path="$script_dir/eye-break-toggle.sh"
plist_dir="$HOME/Library/LaunchAgents"
plist_path="$plist_dir/$label.plist"
domain="gui/$(/usr/bin/id -u)"

usage() {
  cat <<EOF
Usage: $0 [install|pause|resume|toggle|status|uninstall]

Commands:
  install    Install and enable the 30-minute eye break reminder
  pause      Pause reminders
  resume     Resume reminders
  toggle     Show an ON/OFF dialog and pause or resume
  status     Show whether reminders are currently enabled
  uninstall  Remove the reminder
EOF
}

install_files() {
  /bin/mkdir -p "$script_dir" "$plist_dir"

  /bin/cat > "$script_path" <<'EOF'
#!/bin/zsh
set -eu

PATH="/usr/bin:/bin:/usr/sbin:/sbin"

message="Slow blink break. Look away from your screen and focus on something far away. I will keep time for 20 seconds."
title="Eye break"
beat_sound="/System/Library/Sounds/Tink.aiff"

/usr/bin/osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\""
/usr/bin/say "$message"

for _ in {1..20}; do
  /usr/bin/afplay -v 0.18 "$beat_sound" >/dev/null 2>&1 &
  /bin/sleep 1
done

/usr/bin/say "Nice. Back to it."
EOF

  /bin/cat > "$toggle_path" <<'EOF'
#!/bin/zsh
set -eu

PATH="/usr/bin:/bin:/usr/sbin:/sbin"

label="com.local.eye-break-reminder"
plist="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(/usr/bin/id -u)"

if /bin/launchctl print "$domain/$label" >/dev/null 2>&1; then
  choice=$(/usr/bin/osascript -e 'button returned of (display dialog "Eye break reminders are currently ON." with title "Eye break" buttons {"Leave On", "Pause"} default button "Pause" cancel button "Leave On")')

  if [[ "$choice" == "Pause" ]]; then
    /bin/launchctl bootout "$domain" "$plist"
    /usr/bin/osascript -e 'display notification "Eye break reminders are paused." with title "Eye break" sound name "Submarine"'
  fi
else
  choice=$(/usr/bin/osascript -e 'button returned of (display dialog "Eye break reminders are currently OFF." with title "Eye break" buttons {"Leave Off", "Turn On"} default button "Turn On" cancel button "Leave Off")')

  if [[ "$choice" == "Turn On" ]]; then
    /bin/launchctl bootstrap "$domain" "$plist"
    /usr/bin/osascript -e 'display notification "Eye break reminders are enabled. The next reminder will run on the 30-minute schedule." with title "Eye break" sound name "Glass"'
  fi
fi
EOF

  /bin/chmod +x "$script_path" "$toggle_path"

  /bin/cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>

  <key>ProgramArguments</key>
  <array>
    <string>$script_path</string>
  </array>

  <key>StartInterval</key>
  <integer>1800</integer>

  <key>RunAtLoad</key>
  <false/>

  <key>StandardOutPath</key>
  <string>/tmp/$label.out.log</string>

  <key>StandardErrorPath</key>
  <string>/tmp/$label.err.log</string>
</dict>
</plist>
EOF
}

pause_reminder() {
  /bin/launchctl bootout "$domain" "$plist_path" 2>/dev/null || true
}

resume_reminder() {
  /usr/bin/plutil -lint "$plist_path" >/dev/null
  pause_reminder
  /bin/launchctl bootstrap "$domain" "$plist_path"
}

status_reminder() {
  if /bin/launchctl print "$domain/$label" >/dev/null 2>&1; then
    echo "Eye break reminders are ON."
  else
    echo "Eye break reminders are OFF."
  fi
}

uninstall_reminder() {
  pause_reminder
  /bin/rm -f "$script_path" "$toggle_path" "$plist_path"
  echo "Eye break reminder removed."
}

command="${1:-install}"

case "$command" in
  install)
    install_files
    resume_reminder
    echo "Installed. Eye break reminders will run every 30 minutes."
    echo "Toggle script: $toggle_path"
    ;;
  pause)
    pause_reminder
    echo "Paused."
    ;;
  resume)
    resume_reminder
    echo "Resumed."
    ;;
  toggle)
    "$toggle_path"
    ;;
  status)
    status_reminder
    ;;
  uninstall)
    uninstall_reminder
    ;;
  *)
    usage
    exit 1
    ;;
esac
