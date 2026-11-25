#!/usr/bin/env bash
# Hyprland session startup helper for Hyprlang (Ubuntu / Hyprland < 0.56)
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

udisksctl mount -b /dev/disk/by-label/HardDrive 2>/dev/null || true
udisksctl mount -b /dev/disk/by-label/SSD 2>/dev/null || true
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources" 2>/dev/null || true

dbus-update-activation-environment --systemd --all 2>/dev/null || true
systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE 2>/dev/null || true
[ -x "$HOME/.config/scripts/setup-portals.sh" ] && "$HOME/.config/scripts/setup-portals.sh" 2>/dev/null &

hyprctl setcursor Adwaita 24 2>/dev/null || true

# Start Quickshell Nothing shell; verify it stays alive, else fall back to swaybg + waybar
QS_STARTED=false
if command -v qs >/dev/null 2>&1 && [ -f "$HOME/.config/quickshell/nothing/shell.qml" ]; then
    if pidof -s quickshell >/dev/null 2>&1; then
        QS_STARTED=true
    else
        qs -p "$HOME/.config/quickshell/nothing" >/tmp/quickshell-nothing.log 2>&1 &
        QS_PID=$!
        sleep 1.5
        if kill -0 "$QS_PID" 2>/dev/null; then
            QS_STARTED=true
        fi
    fi
fi

if [ "$QS_STARTED" = false ]; then
    if command -v swaybg >/dev/null 2>&1 && [ -f "$HOME/.config/hypr/wallpaper.png" ] && ! pidof -s swaybg >/dev/null 2>&1; then
        swaybg -i "$HOME/.config/hypr/wallpaper.png" -m fill >/dev/null 2>&1 &
    fi
    if command -v waybar >/dev/null 2>&1 && ! pidof -s waybar >/dev/null 2>&1; then
        waybar >/dev/null 2>&1 &
    fi
fi

if command -v hypridle >/dev/null 2>&1 && ! pidof -s hypridle >/dev/null 2>&1; then
    HYPRIDLE_CONF="$HOME/.config/nothing/hypridle.conf"
    [ -f "$HYPRIDLE_CONF" ] || HYPRIDLE_CONF="$HOME/.config/hypr/hypridle.conf"
    [ -f "$HYPRIDLE_CONF" ] && hypridle -c "$HYPRIDLE_CONF" >/dev/null 2>&1 &
fi

command -v gnome-keyring-daemon >/dev/null 2>&1 && gnome-keyring-daemon --start --components=secrets >/dev/null 2>&1 &
[ -x "$HOME/.config/scripts/ensure-cliphist.sh" ] && "$HOME/.config/scripts/ensure-cliphist.sh" >/dev/null 2>&1 &
