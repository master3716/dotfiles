#!/usr/bin/env bash
# ==============================================================================
# Dotfiles & Hyprland Rice Installer for Ubuntu (24.04 LTS / 24.10+)
# ==============================================================================
set -uo pipefail

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info() {
    printf "%b[INFO]%b %s\n" "${BLUE}" "${NC}" "$1"
}

log_success() {
    printf "%b[SUCCESS]%b %s\n" "${GREEN}" "${NC}" "$1"
}

log_warn() {
    printf "%b[WARN]%b %s\n" "${YELLOW}" "${NC}" "$1"
}

log_error() {
    printf "%b[ERROR]%b %s\n" "${RED}" "${NC}" "$1" >&2
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

OFFLINE_MODE=false
INSTALL_APPS="ask"
APPS_ONLY=false
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            cat <<'EOF'
Usage: ./install-ubuntu.sh [OPTION]

Ubuntu / Debian Dotfiles & Hyprland installer.

Options:
  -h, --help            Show this help message
      --apps            Install optional desktop apps via Flatpak (Zen Browser, Vesktop, ZapZap, Spotify, etc.)
      --apps-only       Run only the optional Flatpak desktop apps stage
      --no-apps         Skip the optional Flatpak desktop apps stage
      --no-flatpak      Alias for --no-apps
      --offline, --local  Install strictly from apt (e.g. Artifactory) + local vendor/ (skips external PPAs/Flatpak)
EOF
            exit 0
            ;;
        --offline|--local)
            OFFLINE_MODE=true
            INSTALL_APPS="no"
            ;;
        --apps|--with-apps|--flatpak)
            INSTALL_APPS="yes"
            ;;
        --no-apps|--no-flatpak)
            INSTALL_APPS="no"
            ;;
        --apps-only)
            APPS_ONLY=true
            INSTALL_APPS="yes"
            ;;
    esac
done

FAILED_ITEMS=()

has_vendor_archive() {
    local base="$1"
    [ -f "$base" ] || compgen -G "${base}.part-*" >/dev/null 2>&1
}

extract_vendor_archive() {
    local base="$1"
    local dest="$2"
    local use_sudo="${3:-}"

    if [ "$use_sudo" = "sudo" ] && has_cmd sudo; then
        sudo mkdir -p "$dest" 2>/dev/null || return 1
        if [ -f "$base" ]; then
            sudo tar -xJf "$base" -C "$dest" 2>/dev/null
            return $?
        elif compgen -G "${base}.part-*" >/dev/null 2>&1; then
            cat "${base}".part-* | sudo tar -xJf - -C "$dest" 2>/dev/null
            return $?
        fi
    else
        mkdir -p "$dest" 2>/dev/null || return 1
        if [ -f "$base" ]; then
            tar -xJf "$base" -C "$dest" 2>/dev/null
            return $?
        elif compgen -G "${base}.part-*" >/dev/null 2>&1; then
            cat "${base}".part-* | tar -xJf - -C "$dest" 2>/dev/null
            return $?
        fi
    fi
    return 1
}

record_failure() {
    local category="$1"
    local item="$2"
    local reason="${3:-not available or installation failed}"
    local entry="[${category}] ${item} (${reason})"
    local existing
    for existing in "${FAILED_ITEMS[@]}"; do
        [ "$existing" = "$entry" ] && return 0
    done
    FAILED_ITEMS+=("$entry")
}

print_summary() {
    if [ "${#FAILED_ITEMS[@]}" -eq 0 ]; then
        log_success "All packages, tools, and applications installed successfully!"
        return 0
    fi

    printf "\n%b=================================================================%b\n" "${YELLOW}${BOLD}" "${NC}"
    printf "%b Summary: Items Not Installed                                    %b\n" "${YELLOW}${BOLD}" "${NC}"
    printf "%b=================================================================%b\n" "${YELLOW}${BOLD}" "${NC}"
    log_warn "Setup continued and finished the remaining steps, but these items could not be installed:"
    local item
    for item in "${FAILED_ITEMS[@]}"; do
        printf "  %b-%b %s\n" "${YELLOW}" "${NC}" "$item"
    done
    printf "\nYou can install or retry any missing items manually later.\n"
}

# Ensure script runs on Ubuntu / Debian
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"ubuntu"* && "$ID" != "debian" ]]; then
        log_warn "This script is tailored for Ubuntu/Debian. Detected: $NAME"
        read -rp "Do you want to proceed anyway? [y/N]: " proceed
        [[ "$proceed" =~ ^[Yy]$ ]] || exit 1
    fi
else
    log_error "Could not detect operating system (/etc/os-release not found)."
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN="$HOME/.local/bin"

mkdir -p "$BIN" "$CONF" "$DATA" "$HOME/bin"
export PATH="$BIN:$HOME/bin:$PATH"

log_info "Setting up Dotfiles & Hyprland for Ubuntu from: ${DOTFILES_DIR}"

link_file() {
    local src="$1" dest="$2"
    [ ! -e "$src" ] && return 0
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)" || true
    fi
    ln -s "$src" "$dest" || { log_warn "Could not link $dest"; return 1; }
    log_success "Linked: $dest -> $src"
}

# Deploy critical configs up front so Hyprland never falls back to autogenerated config
log_info "Linking core configurations..."
chmod +x "${DOTFILES_DIR}/config/scripts/"*.sh 2>/dev/null || true
link_file "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
link_file "${DOTFILES_DIR}/zsh/.zshenv" "$HOME/.zshenv"
link_file "${DOTFILES_DIR}/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
link_file "${DOTFILES_DIR}/config/nvim" "$CONF/nvim"
link_file "${DOTFILES_DIR}/config/ghostty/config" "$CONF/ghostty/config"
link_file "${DOTFILES_DIR}/config/zellij/config.kdl" "$CONF/zellij/config.kdl"
link_file "${DOTFILES_DIR}/config/hypr" "$CONF/hypr"
if [ -L "$CONF/quickshell" ]; then
    rm -f "$CONF/quickshell"
fi
mkdir -p "$CONF/quickshell"
link_file "${DOTFILES_DIR}/config/quickshell/nothing" "$CONF/quickshell/nothing"
link_file "${DOTFILES_DIR}/config/scripts" "$CONF/scripts"
link_file "${DOTFILES_DIR}/config/theme" "$CONF/theme"
link_file "${DOTFILES_DIR}/config/fastfetch" "$CONF/fastfetch"
link_file "${DOTFILES_DIR}/config/starship.toml" "$CONF/starship.toml"

# ------------------------------------------------------------------------------
# 1. System Update & Repositories
# ------------------------------------------------------------------------------
log_info "Updating package lists..."
sudo apt-get update -y || log_warn "apt-get update returned warnings."

for prereq in software-properties-common apt-transport-https ca-certificates curl wget gpg; do
    sudo apt-get install -y --no-install-recommends "$prereq" >/dev/null 2>&1 || \
        record_failure "apt prerequisite" "$prereq"
done

# Hyprland & Quickshell PPAs for Ubuntu (only if online and not already in configured/Artifactory repos)
if [ "$OFFLINE_MODE" = false ] && has_cmd add-apt-repository; then
    ppa_added=false
    if ! apt-cache show hyprland >/dev/null 2>&1 && ! grep -rq "cppiber/hyprland" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        log_info "Adding Hyprland community PPA (ppa:cppiber/hyprland)..."
        if sudo add-apt-repository -y ppa:cppiber/hyprland; then
            ppa_added=true
        else
            log_warn "Could not add ppa:cppiber/hyprland. Will try default repositories."
            record_failure "apt PPA" "ppa:cppiber/hyprland" "failed to add"
        fi
    fi
    if ! apt-cache show quickshell >/dev/null 2>&1 && ! grep -rq "avengemedia/danklinux" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        log_info "Adding Quickshell PPA (ppa:avengemedia/danklinux)..."
        if sudo add-apt-repository -y ppa:avengemedia/danklinux; then
            ppa_added=true
        else
            log_warn "Could not add ppa:avengemedia/danklinux."
            record_failure "apt PPA" "ppa:avengemedia/danklinux" "failed to add"
        fi
    fi
    [ "$ppa_added" = true ] && { sudo apt-get update -y || true; }
fi

# ------------------------------------------------------------------------------
# 2. Install Packages
# ------------------------------------------------------------------------------
log_info "Installing core packages, Hyprland, and audio/Wayland stack..."
APT_PACKAGES=(
    # Shell & essentials
    zsh git curl wget unzip tar tree jq tmux fontconfig direnv
    build-essential gcc g++ make cmake pkg-config
    python3 python3-pip python3-venv python3-pil python3-numpy pipx
    # Wayland, Compositor, Shell, Portals & Fallbacks
    hyprland hypridle hyprlock hyprland-guiutils quickshell
    qml6-module-qtquick-layouts qml6-module-qtquick-controls qml6-module-qt5compat-graphicaleffects qml6-module-qtquick-effects
    qt6-gtk-platformtheme qt6ct qt6-svg-plugins qt6-image-formats-plugins
    swaybg waybar wofi foot libnotify-bin
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    wayland-protocols libwayland-dev
    # Audio & Media
    pipewire pipewire-pulse wireplumber pavucontrol libspa-0.2-bluetooth
    playerctl brightnessctl
    # Wayland utilities
    wl-clipboard cliphist grim slurp
    # Modern CLI tools & Flatpak in apt
    ripgrep fd-find bat fzf udisks2 flatpak
    # Fonts & Icon Themes
    fonts-font-awesome papirus-icon-theme adwaita-icon-theme hicolor-icon-theme yaru-theme-icon
)

install_optional_apps() {
    log_info "Starting optional stage: Desktop Applications (Flatpak)..."

    if ! has_cmd flatpak; then
        log_info "Installing flatpak..."
        sudo apt-get install -y flatpak 2>/dev/null || true
    fi

    if ! has_cmd flatpak; then
        log_warn "Flatpak is not available. Skipping optional desktop applications."
        record_failure "Flatpak" "All optional apps" "flatpak could not be installed"
        return 0
    fi

    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || \
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

    local flatpak_apps=(
        dev.vencord.Vesktop
        app.zen_browser.zen
        com.rtosta.zapzap
        com.spotify.Client
        com.stremio.Stremio
        com.discordapp.Discord
        io.github.Foldex.AdwSteamGtk
        org.prismlauncher.PrismLauncher
    )

    local app
    for app in "${flatpak_apps[@]}"; do
        if ! flatpak info "$app" >/dev/null 2>&1; then
            log_info "Installing Flatpak: $app..."
            if ! flatpak install -y --noninteractive flathub "$app" 2>/dev/null && \
               ! flatpak install --user -y --noninteractive flathub "$app" 2>/dev/null; then
                log_warn "Could not install $app."
                record_failure "Flatpak" "$app"
            fi
        else
            log_info "Flatpak $app is already installed."
        fi
    done

    # Deploy Vesktop & ZapZap configs and cursor overrides
    local VESKTOP_DIR="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"
    mkdir -p "$VESKTOP_DIR/themes" "$VESKTOP_DIR/settings" "$CONF/vesktop"
    [ -f "${DOTFILES_DIR}/config/vesktop/settings.json" ] && [ ! -f "$VESKTOP_DIR/settings.json" ] && \
        cp "${DOTFILES_DIR}/config/vesktop/settings.json" "$VESKTOP_DIR/settings.json" 2>/dev/null || true
    [ -f "${DOTFILES_DIR}/config/vesktop/settings/settings.json" ] && [ ! -f "$VESKTOP_DIR/settings/settings.json" ] && \
        cp "${DOTFILES_DIR}/config/vesktop/settings/settings.json" "$VESKTOP_DIR/settings/settings.json" 2>/dev/null || true
    [ -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" ] && \
        cp -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" "$VESKTOP_DIR/themes/nothing.theme.css" 2>/dev/null || true

    local ZAPZAP_DIR="$HOME/.var/app/com.rtosta.zapzap/config/ZapZap"
    mkdir -p "$ZAPZAP_DIR" "$CONF/ZapZap"
    if [ -f "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" ]; then
        [ ! -f "$ZAPZAP_DIR/ZapZap.conf" ] && cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$ZAPZAP_DIR/ZapZap.conf" 2>/dev/null || true
        [ ! -f "$CONF/ZapZap/ZapZap.conf" ] && cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$CONF/ZapZap/ZapZap.conf" 2>/dev/null || true
    fi

    flatpak override --user --env=XCURSOR_THEME=Adwaita --env=XCURSOR_SIZE=24 2>/dev/null || true
}

if [ "$APPS_ONLY" = true ]; then
    install_optional_apps
    printf "\n%b=================================================================%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%b Optional Desktop Apps Stage Completed! %b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%b=================================================================%b\n\n" "${GREEN}${BOLD}" "${NC}"
    print_summary
    exit 0
fi

# Install packages allowing failures for optional ones
if ! sudo apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}" 2>/dev/null; then
    for pkg in "${APT_PACKAGES[@]}"; do
        if ! sudo apt-get install -y "$pkg" 2>/dev/null; then
            log_warn "Optional package $pkg could not be installed via apt."
            record_failure "apt" "$pkg"
        fi
    done
fi

# Fix Ubuntu command name quirks
mkdir -p "$BIN"
if has_cmd batcat && ! has_cmd bat; then
    ln -sf "$(command -v batcat)" "$BIN/bat"
fi
if has_cmd fdfind && ! has_cmd fd; then
    ln -sf "$(command -v fdfind)" "$BIN/fd"
fi

# ------------------------------------------------------------------------------
# 3. Modern CLI Tools (Local Vendor First, Online Fallback)
# ------------------------------------------------------------------------------
ARCH="$(uname -m)"
VENDOR_BIN="${DOTFILES_DIR}/vendor/bin/${ARCH}"

# eza
if ! has_cmd eza && [ ! -f "$BIN/eza" ]; then
    if has_vendor_archive "${VENDOR_BIN}/eza.tar.xz"; then
        log_info "Installing eza from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/eza.tar.xz" "$BIN" && chmod +x "$BIN/eza" 2>/dev/null || true
    elif apt-cache show eza >/dev/null 2>&1; then
        sudo apt-get install -y eza 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Configuring eza repository..."
        sudo mkdir -p /etc/apt/keyrings 2>/dev/null || true
        if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null || true
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
            sudo apt-get update -qq || true
            sudo apt-get install -y eza 2>/dev/null || true
        fi
    fi
fi
if ! has_cmd eza && [ ! -f "$BIN/eza" ]; then
    record_failure "CLI tool" "eza"
fi

# zoxide
if ! has_cmd zoxide && [ ! -f "$BIN/zoxide" ]; then
    if has_vendor_archive "${VENDOR_BIN}/zoxide.tar.xz"; then
        log_info "Installing zoxide from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/zoxide.tar.xz" "$BIN" && chmod +x "$BIN/zoxide" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || true
    fi
fi
if ! has_cmd zoxide && [ ! -f "$BIN/zoxide" ]; then
    record_failure "CLI tool" "zoxide"
fi

# zellij
if ! has_cmd zellij && [ ! -f "$BIN/zellij" ]; then
    if has_vendor_archive "${VENDOR_BIN}/zellij.tar.xz"; then
        log_info "Installing zellij from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/zellij.tar.xz" "$BIN" && chmod +x "$BIN/zellij" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing Zellij..."
        ZJ_TAR="zellij-${ARCH}-unknown-linux-musl.tar.gz"
        curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/${ZJ_TAR}" -o "/tmp/${ZJ_TAR}" 2>/dev/null || true
        if [ -f "/tmp/${ZJ_TAR}" ]; then
            tar -xzf "/tmp/${ZJ_TAR}" -C "$BIN" 2>/dev/null || true
            chmod +x "$BIN/zellij" 2>/dev/null || true
            rm -f "/tmp/${ZJ_TAR}"
        fi
    fi
fi
if ! has_cmd zellij && [ ! -f "$BIN/zellij" ]; then
    record_failure "CLI tool" "zellij"
fi

# lazygit
if ! has_cmd lazygit && [ ! -f "$BIN/lazygit" ]; then
    if has_vendor_archive "${VENDOR_BIN}/lazygit.tar.xz"; then
        log_info "Installing lazygit from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/lazygit.tar.xz" "$BIN" && chmod +x "$BIN/lazygit" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing lazygit..."
        LG_VER="$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")"
        [ "$ARCH" = "aarch64" ] && LG_ARCH="arm64" || LG_ARCH="x86_64"
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" -o /tmp/lazygit.tar.gz 2>/dev/null || true
        if [ -f /tmp/lazygit.tar.gz ]; then
            tar -xzf /tmp/lazygit.tar.gz -C "$BIN" lazygit 2>/dev/null || true
            chmod +x "$BIN/lazygit" 2>/dev/null || true
            rm -f /tmp/lazygit.tar.gz
        fi
    fi
fi
if ! has_cmd lazygit && [ ! -f "$BIN/lazygit" ]; then
    record_failure "CLI tool" "lazygit"
fi

# Neovim (Latest release tarball - Ubuntu's apt version is usually outdated)
NEED_NVIM=0
if ! has_cmd nvim; then
    NEED_NVIM=1
else
    NVIM_RAW_VER="$(nvim --version 2>/dev/null | head -n1 || echo "")"
    if [[ "$NVIM_RAW_VER" =~ v0\.([0-9]+) ]] && [ "${BASH_REMATCH[1]}" -lt 10 ]; then
        NEED_NVIM=1
    fi
fi
if [ "$NEED_NVIM" -eq 1 ]; then
    if has_vendor_archive "${VENDOR_BIN}/nvim-linux-x86_64.tar.xz"; then
        log_info "Installing Neovim from local repo..."
        if has_cmd sudo; then
            sudo rm -rf /opt/nvim-linux-x86_64 2>/dev/null || true
            extract_vendor_archive "${VENDOR_BIN}/nvim-linux-x86_64.tar.xz" "/opt" "sudo" && \
                ln -sf /opt/nvim-linux-x86_64/bin/nvim "$BIN/nvim" 2>/dev/null || true
        else
            rm -rf "$HOME/.local/opt/nvim-linux-x86_64" 2>/dev/null || true
            extract_vendor_archive "${VENDOR_BIN}/nvim-linux-x86_64.tar.xz" "$HOME/.local/opt" && \
                ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$BIN/nvim" 2>/dev/null || true
        fi
    elif [ "$OFFLINE_MODE" = false ] && [ "$ARCH" = "x86_64" ]; then
        log_info "Installing Neovim (v0.10+ binary for LazyVim compatibility)..."
        curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz 2>/dev/null || true
        if [ -f /tmp/nvim.tar.gz ]; then
            sudo rm -rf /opt/nvim-linux-x86_64 2>/dev/null || true
            sudo tar -C /opt -xzf /tmp/nvim.tar.gz 2>/dev/null || true
            sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim 2>/dev/null || true
            ln -sf /usr/local/bin/nvim "$BIN/nvim" 2>/dev/null || true
            rm -f /tmp/nvim.tar.gz
        fi
    fi
fi
if ! has_cmd nvim; then
    record_failure "Editor" "neovim"
fi

# Ghostty terminal (apt/Artifactory first, deb.griffo.io, Snap fallback)
if ! has_cmd ghostty; then
    log_info "Installing Ghostty terminal..."
    if apt-cache show ghostty >/dev/null 2>&1; then
        sudo apt-get install -y ghostty 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        if has_cmd sudo; then
            sudo install -d -m 0755 /etc/apt/keyrings 2>/dev/null || true
            if curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg 2>/dev/null; then
                echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list >/dev/null 2>&1 || true
                sudo apt-get update -qq 2>/dev/null || true
                sudo apt-get install -y ghostty 2>/dev/null || true
            fi
        fi
        if ! has_cmd ghostty && has_cmd snap; then
            sudo snap install ghostty --classic 2>/dev/null || true
        fi
    fi
fi
if ! has_cmd ghostty; then
    record_failure "Terminal" "ghostty"
fi

# Antigravity CLI (agy)
if ! has_cmd agy && [ ! -f "$BIN/agy" ]; then
    if has_vendor_archive "${VENDOR_BIN}/agy.tar.xz"; then
        log_info "Installing Antigravity CLI (agy) from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/agy.tar.xz" "$BIN" && chmod +x "$BIN/agy" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing Antigravity CLI (agy)..."
        curl -fsSL https://antigravity.google/cli/install.sh | bash 2>/dev/null || \
            curl -fsSL https://antigravity.dev/install.sh | bash 2>/dev/null || true
    fi
    if ! has_cmd agy && [ ! -f "$BIN/agy" ]; then
        log_warn "Could not install Antigravity CLI automatically."
        record_failure "Developer tool" "Antigravity CLI (agy)"
    fi
fi

# Astral uv
if ! has_cmd uv && [ ! -f "$BIN/uv" ]; then
    if has_vendor_archive "${VENDOR_BIN}/uv.tar.xz"; then
        log_info "Installing Astral uv from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/uv.tar.xz" "$BIN" && chmod +x "$BIN/uv" "$BIN/uvx" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing Astral uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || true
    fi
fi
if ! has_cmd uv && [ ! -f "$BIN/uv" ]; then
    record_failure "Python tool" "uv"
fi

# Cloudflare Tunnel (cloudflared)
if ! has_cmd cloudflared && [ ! -f "$BIN/cloudflared" ]; then
    if has_vendor_archive "${VENDOR_BIN}/cloudflared.tar.xz"; then
        log_info "Installing cloudflared from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/cloudflared.tar.xz" "$BIN" && chmod +x "$BIN/cloudflared" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing cloudflared..."
        CF_ARCH="amd64"
        [ "$ARCH" = "aarch64" ] && CF_ARCH="arm64"
        if curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o "/tmp/cloudflared" 2>/dev/null; then
            install -m 755 /tmp/cloudflared "$BIN/cloudflared" 2>/dev/null || true
            rm -f /tmp/cloudflared
        else
            rm -f /tmp/cloudflared
        fi
    fi
fi
if ! has_cmd cloudflared && [ ! -f "$BIN/cloudflared" ]; then
    record_failure "CLI tool" "cloudflared"
fi

# Rclone
if ! has_cmd rclone && [ ! -f "$BIN/rclone" ]; then
    if has_vendor_archive "${VENDOR_BIN}/rclone.tar.xz"; then
        log_info "Installing rclone from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/rclone.tar.xz" "$BIN" && chmod +x "$BIN/rclone" 2>/dev/null || true
    elif [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing rclone..."
        curl -fsSL https://rclone.org/install.sh | sudo bash 2>/dev/null || true
    fi
fi
if ! has_cmd rclone && [ ! -f "$BIN/rclone" ]; then
    record_failure "CLI tool" "rclone"
fi

# Fastfetch
if ! has_cmd fastfetch && [ ! -f "$BIN/fastfetch" ]; then
    if has_vendor_archive "${VENDOR_BIN}/fastfetch.tar.xz"; then
        log_info "Installing fastfetch from local repo..."
        extract_vendor_archive "${VENDOR_BIN}/fastfetch.tar.xz" "$BIN" && chmod +x "$BIN/fastfetch" 2>/dev/null || true
    fi
fi
if ! has_cmd fastfetch && [ ! -f "$BIN/fastfetch" ]; then
    record_failure "CLI tool" "fastfetch"
fi

# Podman Docker compatibility symlink
if ! has_cmd docker && has_cmd podman; then
    log_info "Configuring docker -> podman symlink..."
    ln -sf "$(command -v podman)" "$BIN/docker" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 4. Fonts (Local Vendor First)
# ------------------------------------------------------------------------------
log_info "Installing MesloLGS NF and Inter fonts..."
FONT_DIR="$DATA/fonts"
mkdir -p "$FONT_DIR/MesloLGS_NF"
has_vendor_archive "${DOTFILES_DIR}/vendor/fonts/MesloLGS_NF.tar.xz" && \
    extract_vendor_archive "${DOTFILES_DIR}/vendor/fonts/MesloLGS_NF.tar.xz" "$FONT_DIR" || true
[ ! -d "${FONT_DIR}/Inter" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/fonts/Inter.tar.xz" && \
    extract_vendor_archive "${DOTFILES_DIR}/vendor/fonts/Inter.tar.xz" "$FONT_DIR" || true

MESLO_URLS=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
)
for url in "${MESLO_URLS[@]}"; do
    fname="$(basename "$url" | sed 's/%20/ /g')"
    if [ ! -f "${FONT_DIR}/${fname}" ] && [ ! -f "${FONT_DIR}/MesloLGS_NF/${fname}" ]; then
        if [ "$OFFLINE_MODE" = true ]; then
            record_failure "Font" "$fname" "missing in offline mode"
        elif ! curl -fsSL "$url" -o "${FONT_DIR}/MesloLGS_NF/${fname}" 2>/dev/null; then
            rm -f "${FONT_DIR}/MesloLGS_NF/${fname}"
            record_failure "Font" "$fname" "download failed"
        fi
    fi
done
has_cmd fc-cache && fc-cache -f "$FONT_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Finalize Configs, Icons, Themes & Zsh
# ------------------------------------------------------------------------------
log_info "Finalizing desktop configurations and themes..."

# Vendored LazyVim plugins
if [ ! -d "${DATA}/nvim/lazy/lazy.nvim" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/nvim/lazy.tar.xz"; then
    log_info "Restoring vendored LazyVim plugins..."
    extract_vendor_archive "${DOTFILES_DIR}/vendor/nvim/lazy.tar.xz" "${DATA}/nvim" || true
fi

# Bin wrappers (dbfetch, vesktop, zen, etc.) & Dragon Ball fetch data
chmod +x "${DOTFILES_DIR}/bin/neofetch" "${DOTFILES_DIR}/bin/dbfetch" 2>/dev/null || true
for bin_file in "${DOTFILES_DIR}/bin"/*; do
    [ -e "$bin_file" ] || continue
    link_file "$bin_file" "$BIN/$(basename "$bin_file")"
done
mkdir -p "$DATA/dragonball-neofetch"
link_file "${DOTFILES_DIR}/data/dragonball/ascii" "$DATA/dragonball-neofetch/ascii"
link_file "${DOTFILES_DIR}/data/dragonball/manifest.json" "$DATA/dragonball-neofetch/manifest.json"

# Nothing OS Desktop Shell Config & Wallpapers
if [ -f "${DOTFILES_DIR}/config/nothing/config.json" ]; then
    mkdir -p "$CONF/nothing"
    if [ ! -f "$CONF/nothing/config.json" ]; then
        cp "${DOTFILES_DIR}/config/nothing/config.json" "$CONF/nothing/config.json" 2>/dev/null || true
    elif grep -q '"/home/oferg/HardDrive/Downloads/goku.jpg"' "$CONF/nothing/config.json" 2>/dev/null && [ ! -f "/home/oferg/HardDrive/Downloads/goku.jpg" ]; then
        sed -i 's|"/home/oferg/HardDrive/Downloads/goku.jpg"|"~/.config/hypr/wallpapers/goku.jpg"|g' "$CONF/nothing/config.json" 2>/dev/null || true
    fi
fi
mkdir -p "$HOME/Pictures/Wallpapers"
for wp in goku.jpg kame.jpg; do
    [ -f "${DOTFILES_DIR}/config/hypr/wallpapers/${wp}" ] && [ ! -f "$HOME/Pictures/Wallpapers/${wp}" ] && \
        cp "${DOTFILES_DIR}/config/hypr/wallpapers/${wp}" "$HOME/Pictures/Wallpapers/${wp}" 2>/dev/null || true
done

# GTK, Qt & KDE icon theme configs
mkdir -p "$CONF/gtk-3.0" "$CONF/gtk-4.0" "$CONF/qt6ct"
link_file "${DOTFILES_DIR}/config/gtk-3.0/settings.ini" "$CONF/gtk-3.0/settings.ini"
link_file "${DOTFILES_DIR}/config/gtk-3.0/gtk.css" "$CONF/gtk-3.0/gtk.css"
link_file "${DOTFILES_DIR}/config/gtk-4.0/settings.ini" "$CONF/gtk-4.0/settings.ini"
link_file "${DOTFILES_DIR}/config/gtk-4.0/gtk.css" "$CONF/gtk-4.0/gtk.css"
link_file "${DOTFILES_DIR}/config/theme/kde/kdeglobals" "$CONF/kdeglobals"
if [ ! -f "$CONF/qt6ct/qt6ct.conf" ]; then
    printf '[Appearance]\nicon_theme=Nothing\n' > "$CONF/qt6ct/qt6ct.conf"
fi

# Nothing Icon Theme & App Icons (Vesktop, Discord, Nothing X)
mkdir -p "$DATA/icons/Nothing" "$DATA/icons/hicolor/scalable/apps" "$DATA/applications"
link_file "${DOTFILES_DIR}/config/theme/icons/Nothing/index.theme" "$DATA/icons/Nothing/index.theme"
if [ -f "${DOTFILES_DIR}/config/scripts/build-nothing-icons.py" ] && python3 -c "import numpy, PIL" 2>/dev/null; then
    python3 "${DOTFILES_DIR}/config/scripts/build-nothing-icons.py" "$DATA/icons/Nothing" 2>/dev/null || true
fi
if [ ! -d "$DATA/icons/Nothing/scalable" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/icons/Nothing.tar.xz"; then
    extract_vendor_archive "${DOTFILES_DIR}/vendor/icons/Nothing.tar.xz" "$DATA/icons" || true
fi
for icon_svg in "${DOTFILES_DIR}/icons/hicolor/scalable/apps"/*.svg; do
    [ -e "$icon_svg" ] || continue
    link_file "$icon_svg" "$DATA/icons/hicolor/scalable/apps/$(basename "$icon_svg")"
done
link_file "${DOTFILES_DIR}/applications/nothing-x.desktop" "$DATA/applications/nothing-x.desktop"
has_cmd gtk-update-icon-cache && { gtk-update-icon-cache -f "$DATA/icons/Nothing" 2>/dev/null || true; gtk-update-icon-cache -f "$DATA/icons/hicolor" 2>/dev/null || true; }
has_cmd update-desktop-database && update-desktop-database "$DATA/applications" 2>/dev/null || true

# Xresources & default cursor
mkdir -p "$DATA/icons/default" "$HOME/.icons/default"
cat << 'EOF' > "$DATA/icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Adwaita
EOF
cp "$DATA/icons/default/index.theme" "$HOME/.icons/default/index.theme"

cat << 'EOF' > "$HOME/.Xresources"
Xcursor.theme: Adwaita
Xcursor.size: 24
EOF

if has_cmd gsettings; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Nothing' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
fi

if has_cmd flatpak; then
    flatpak override --user --env=XCURSOR_THEME=Adwaita --env=XCURSOR_SIZE=24 2>/dev/null || true
fi

# Portals
mkdir -p "$CONF/xdg-desktop-portal"
link_file "${DOTFILES_DIR}/config/theme/xdg-desktop-portal/hyprland-portals.conf" "$CONF/xdg-desktop-portal/hyprland-portals.conf"
link_file "${DOTFILES_DIR}/config/theme/xdg-desktop-portal/portals.conf" "$CONF/xdg-desktop-portal/portals.conf"

# Oh My Zsh + Powerlevel10k + plugins (Local Vendor First)
if [ ! -d "$HOME/.oh-my-zsh" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/zsh/oh-my-zsh.tar.xz"; then
    log_info "Installing Oh My Zsh, Powerlevel10k, and plugins from local repo..."
    extract_vendor_archive "${DOTFILES_DIR}/vendor/zsh/oh-my-zsh.tar.xz" "$HOME" || true
fi
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if [ "$OFFLINE_MODE" = true ]; then
        record_failure "Zsh" "oh-my-zsh" "missing in offline mode"
    else
        log_info "Installing Oh My Zsh..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null; then
            # Restore link to our zshrc
            ln -sf "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc" 2>/dev/null || true
        else
            record_failure "Zsh" "oh-my-zsh" "install failed"
        fi
    fi
fi

# Zsh plugins & theme
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    [ "$OFFLINE_MODE" = true ] && record_failure "Zsh" "powerlevel10k" || { git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || record_failure "Zsh" "powerlevel10k"; }
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    [ "$OFFLINE_MODE" = true ] && record_failure "Zsh plugin" "zsh-autosuggestions" || { git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || record_failure "Zsh plugin" "zsh-autosuggestions"; }
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    [ "$OFFLINE_MODE" = true ] && record_failure "Zsh plugin" "zsh-syntax-highlighting" || { git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || record_failure "Zsh plugin" "zsh-syntax-highlighting"; }
fi
if [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]; then
    [ "$OFFLINE_MODE" = true ] && record_failure "Zsh plugin" "fzf-tab" || { git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab" 2>/dev/null || record_failure "Zsh plugin" "fzf-tab"; }
fi

# Set default shell to Zsh
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "${SHELL:-}" != "$ZSH_BIN" ]; then
    log_info "Switching default shell to Zsh..."
    sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null || chsh -s "$ZSH_BIN" 2>/dev/null || true
fi

# Optional Stage: Desktop Applications (Zen Browser, Vesktop, ZapZap, Spotify, etc.)
if [ "$INSTALL_APPS" = "yes" ]; then
    install_optional_apps
elif [ "$INSTALL_APPS" = "ask" ] && [ "$OFFLINE_MODE" = false ] && [ -t 0 ]; then
    printf "\n"
    read -rp "Optional stage: install desktop apps via Flatpak (Zen Browser, Vesktop, ZapZap, Spotify, Stremio, Discord, PrismLauncher)? [y/N]: " install_apps_ans
    if [[ "$install_apps_ans" =~ ^[Yy]$ ]]; then
        install_optional_apps
    else
        log_info "Skipped optional Flatpak apps. You can install them anytime with: ./install-ubuntu.sh --apps-only"
    fi
elif [ "$INSTALL_APPS" = "ask" ] && [ "$OFFLINE_MODE" = false ]; then
    log_info "Skipped optional Flatpak apps (non-interactive). Run './install-ubuntu.sh --apps' or './install-ubuntu.sh --apps-only' to install them."
fi

printf "\n%b=================================================================%b\n" "${GREEN}${BOLD}" "${NC}"
printf "%b Ubuntu Dotfiles & Hyprland Setup Completed! %b\n" "${GREEN}${BOLD}" "${NC}"
printf "%b=================================================================%b\n\n" "${GREEN}${BOLD}" "${NC}"
print_summary
printf "\nTo start using your new environment, log out and select '%bHyprland%b' at your login screen,\n" "${BOLD}" "${NC}"
printf "or run: %bexec zsh%b\n\n" "${BOLD}" "${NC}"
