#!/usr/bin/env bash
# Launch the best available terminal emulator (Ghostty primary, with Wayland/X11 fallbacks)
for term in ghostty foot alacritty wezterm kitty gnome-terminal xterm; do
    if command -v "$term" >/dev/null 2>&1; then
        exec "$term" "$@"
    fi
done
notify-send "No terminal found" "Install ghostty, foot, or alacritty." 2>/dev/null || true
exit 1
