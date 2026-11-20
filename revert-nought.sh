#!/usr/bin/env bash
# ==============================================================================
# Revert Nought (Nothing OS) Rice & Theme
# Restores original OS theme settings, GTK/Qt configurations, and removes
# Nought-specific desktop configs and links.
# ==============================================================================

set -euo pipefail

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { printf "%b[INFO]%b %s\n" "${BLUE}" "${NC}" "$1"; }
log_success() { printf "%b[SUCCESS]%b %s\n" "${GREEN}" "${NC}" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "${YELLOW}" "${NC}" "$1"; }

CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ENV="${CONF}/nought-theme-backup.env"

restore_backup() {
    local target="$1"
    if [ -L "$target" ]; then
        rm -f "$target"
        log_info "Removed link: $target"
    elif [ -e "$target" ]; then
        rm -rf "$target"
        log_info "Removed: $target"
    fi

    local last_bak
    last_bak="$(ls -1d "${target}".bak-* 2>/dev/null | sort | tail -n 1 || true)"
    if [ -n "$last_bak" ] && [ -e "$last_bak" ]; then
        mv "$last_bak" "$target"
        log_success "Restored backup: $target <- $(basename "$last_bak")"
    fi
}

echo -e "\n${BOLD}====================================================${NC}"
echo -e "${BOLD}         Reverting Nought (Nothing OS) Rice         ${NC}"
echo -e "${BOLD}====================================================${NC}\n"

# 1. Restore OS Theme via gsettings
log_info "Restoring GNOME / OS Interface Theme Settings..."
if [ -f "$BACKUP_ENV" ]; then
    # shellcheck source=/dev/null
    source "$BACKUP_ENV"
    [ -n "${SAVED_COLOR_SCHEME:-}" ] && gsettings set org.gnome.desktop.interface color-scheme "$SAVED_COLOR_SCHEME" 2>/dev/null || true
    [ -n "${SAVED_GTK_THEME:-}" ]    && gsettings set org.gnome.desktop.interface gtk-theme "$SAVED_GTK_THEME" 2>/dev/null || true
    [ -n "${SAVED_ICON_THEME:-}" ]   && gsettings set org.gnome.desktop.interface icon-theme "$SAVED_ICON_THEME" 2>/dev/null || true
    [ -n "${SAVED_FONT_NAME:-}" ]    && gsettings set org.gnome.desktop.interface font-name "$SAVED_FONT_NAME" 2>/dev/null || true
    [ -n "${SAVED_ACCENT_COLOR:-}" ] && gsettings set org.gnome.desktop.interface accent-color "$SAVED_ACCENT_COLOR" 2>/dev/null || true
    rm -f "$BACKUP_ENV"
    log_success "Restored GNOME theme settings from backup file."
else
    # Default fallbacks
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface accent-color 2>/dev/null || true
    log_success "Reset GNOME theme settings to system defaults (Adwaita)."
fi

# 2. Restore GTK 3 & 4 Themes
log_info "Restoring GTK 3 and GTK 4 themes..."
restore_backup "${CONF}/gtk-3.0/settings.ini"
restore_backup "${CONF}/gtk-3.0/gtk.css"
restore_backup "${CONF}/gtk-4.0/settings.ini"
restore_backup "${CONF}/gtk-4.0/gtk.css"

# 3. Restore Qt / KDE Themes
log_info "Restoring Qt/KDE themes..."
restore_backup "${CONF}/kdeglobals"
restore_backup "${CONF}/darklyrc"
rm -f "${DATA}/color-schemes/Nothing.colors"

# 4. Remove Nothing Icon Theme & App Desktops
log_info "Removing Nothing icons and desktop entries..."
rm -rf "${DATA}/icons/Nothing"
rm -f "${DATA}/applications/nothing-x.desktop"
rm -f "${DATA}/icons/hicolor/scalable/apps/nothing-x.svg"
rm -f "${DATA}/kio/servicemenus/nothing-set-wallpaper.desktop"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f "${DATA}/icons/hicolor" 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DATA}/applications" 2>/dev/null || true
fi

# 5. Restore Fontconfig & Portals
log_info "Restoring Fontconfig & XDG Portals..."
restore_backup "${CONF}/fontconfig"
restore_backup "${CONF}/xdg-desktop-portal/hyprland-portals.conf"
restore_backup "${CONF}/xdg-desktop-portal/portals.conf"
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 || true
fi

# 6. Remove Nought Compositor & Shell Configs
log_info "Removing Nought Hyprland, Quickshell, scripts, and theme copies..."
restore_backup "${CONF}/hypr"
restore_backup "${CONF}/quickshell/nothing"
rmdir "${CONF}/quickshell" 2>/dev/null || true
restore_backup "${CONF}/scripts"
restore_backup "${CONF}/theme"
restore_backup "${CONF}/fastfetch"
restore_backup "${CONF}/kitty"
restore_backup "${CONF}/fish/conf.d/nothing.fish"
rm -f "${CONF}/starship.toml"

# 7. Reload User GNOME Desktop Dconf Settings
if command -v dconf >/dev/null 2>&1; then
    log_info "Reloading user GNOME dconf settings..."
    [ -f "${DOTFILES_DIR}/config/gnome/dash-to-panel.dconf" ] && dconf load /org/gnome/shell/extensions/dash-to-panel/ < "${DOTFILES_DIR}/config/gnome/dash-to-panel.dconf" 2>/dev/null || true
    [ -f "${DOTFILES_DIR}/config/gnome/mutter.dconf" ] && dconf load /org/gnome/mutter/ < "${DOTFILES_DIR}/config/gnome/mutter.dconf" 2>/dev/null || true
    [ -f "${DOTFILES_DIR}/config/gnome/shell-keybindings.dconf" ] && dconf load /org/gnome/shell/keybindings/ < "${DOTFILES_DIR}/config/gnome/shell-keybindings.dconf" 2>/dev/null || true
    [ -f "${DOTFILES_DIR}/config/gnome/wm-keybindings.dconf" ] && dconf load /org/gnome/desktop/wm/keybindings/ < "${DOTFILES_DIR}/config/gnome/wm-keybindings.dconf" 2>/dev/null || true
    [ -f "${DOTFILES_DIR}/config/gnome/input-sources.dconf" ] && dconf load /org/gnome/desktop/input-sources/ < "${DOTFILES_DIR}/config/gnome/input-sources.dconf" 2>/dev/null || true
fi

# 8. Unpatch Vesktop / Spotify if applicable
if [ -f "${CONF}/vesktop/themes/nothing.theme.css" ]; then
    rm -f "${CONF}/vesktop/themes/nothing.theme.css"
    log_info "Removed Vesktop Nothing theme."
fi
if command -v spicetify >/dev/null 2>&1; then
    spicetify restore >/dev/null 2>&1 || true
    log_info "Restored Spicetify Spotify configuration."
fi

echo -e "\n${GREEN}${BOLD}✓ Nought has been successfully reverted!${NC}"
echo -e "Your system theme and configurations have been restored.\n"
echo -e "${YELLOW}Note on Git:${NC}"
echo -e "  To revert your dotfiles repository back to before Nought was added, run:"
echo -e "    ${BOLD}git checkout main${NC}  (or: ${BOLD}git checkout backup-before-nought${NC})\n"
