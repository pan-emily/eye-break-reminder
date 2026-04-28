# Eye Break Reminder

A tiny macOS reminder that nudges you every 30 minutes to slow blink, look away, and defocus for 20 seconds.

It uses built-in macOS tools only:

- `launchctl` to schedule the reminder
- `say` for the spoken prompt
- `afplay` for soft once-per-second beats during the 20-second break
- `osascript` for notifications and the pause/resume dialog

No app install, no account, no background service beyond a local macOS LaunchAgent.

## What It Does

Every 30 minutes, it:

1. Shows a macOS notification.
2. Speaks a short eye break prompt.
3. Plays a soft beat once per second for 20 seconds.
4. Says: "Nice. Back to it."

## Install

Clone this repo, then run:

```zsh
chmod +x install.sh
./install.sh
```

The reminder starts on the next 30-minute schedule. It does not speak immediately on install.

## Pause Or Resume

Pause reminders:

```zsh
./install.sh pause
```

Resume reminders:

```zsh
./install.sh resume
```

Check status:

```zsh
./install.sh status
```

## Optional Dock Toggle

The installer also creates this toggle script:

```zsh
~/.local/bin/eye-break-toggle.sh
```

To make it clickable:

1. Open the macOS **Shortcuts** app.
2. Create a new shortcut.
3. Add **Run Shell Script**.
4. Use this command:

   ```zsh
   ~/.local/bin/eye-break-toggle.sh
   ```

5. Add the shortcut to your Dock.

When clicked, it shows whether reminders are currently ON or OFF and lets you pause or resume.
When reminders are on, it also shows an approximate countdown until the next break.

## Optional Menu Bar Toggle

For a live menu-bar countdown and quick actions, install [SwiftBar](https://swiftbar.app/).

With Homebrew:

```zsh
brew install --cask swiftbar
```

Then copy the plugin into SwiftBar's plugins folder:

```zsh
mkdir -p "$HOME/Library/Application Support/SwiftBar/Plugins"
cp swiftbar/eye-break.1m.sh "$HOME/Library/Application Support/SwiftBar/Plugins/"
chmod +x "$HOME/Library/Application Support/SwiftBar/Plugins/eye-break.1m.sh"
open -a SwiftBar
```

The menu bar item shows the next break countdown, plus actions for pause, resume, and run now.

## Uninstall

```zsh
./install.sh uninstall
```

This removes the LaunchAgent and the installed scripts.

## Files Installed

The installer creates:

- `~/.local/bin/eye-break-reminder.sh`
- `~/.local/bin/eye-break-toggle.sh`
- `~/Library/LaunchAgents/com.local.eye-break-reminder.plist`

## Requirements

- macOS
- `zsh`, which is included by default on modern macOS

