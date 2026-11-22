#!/usr/bin/env bash
# ==============================================================================
# Dotfiles & Hyprland Rice Installer for Ubuntu (24.04 LTS / 24.10+)
# ==============================================================================
set -euo pipefail

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

# ------------------------------------------------------------------------------
# 1. System Update & Repositories
# ------------------------------------------------------------------------------
log_info "Updating package lists..."
sudo apt-get update -y

sudo apt-get install -y --no-install-recommends \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gpg

# Hyprland PPA for Ubuntu (cppiber/hyprland provides modern builds)
if ! grep -rq "cppiber/hyprland" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    log_info "Adding Hyprland community PPA (ppa:cppiber/hyprland)..."
    sudo add-apt-repository -y ppa:cppiber/hyprland || log_warn "Could not add ppa:cppiber/hyprland. Will try default repositories."
    sudo apt-get update -y
fi

# ------------------------------------------------------------------------------
# 2. Install Packages
# ------------------------------------------------------------------------------
log_info "Installing core packages, Hyprland, and audio/Wayland stack..."
APT_PACKAGES=(
    # Shell & essentials
    zsh git curl wget unzip tar tree jq tmux fontconfig direnv
    build-essential gcc g++ make cmake pkg-config
    python3 python3-pip python3-venv pipx
    # Wayland, Compositor, Portals
    hyprland hypridle hyprlock
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    wayland-protocols libwayland-dev
    # Audio & Media
    pipewire pipewire-pulse wireplumber pavucontrol libspa-0.2-bluetooth
    playerctl brightnessctl
    # Wayland utilities
    wl-clipboard cliphist grim slurp
    # Modern CLI tools in apt
    ripgrep fd-find bat fzf udisks2
    # Fonts
    fonts-font-awesome
)

# Install packages allowing failures for optional ones
for pkg in "${APT_PACKAGES[@]}"; do
    sudo apt-get install -y "$pkg" 2>/dev/null || log_warn "Optional package $pkg could not be installed via apt."
done

# Fix Ubuntu command name quirks
mkdir -p "$BIN"
if has_cmd batcat && ! has_cmd bat; then
    ln -sf "$(command -v batcat)" "$BIN/bat"
fi
if has_cmd fdfind && ! has_cmd fd; then
    ln -sf "$(command -v fdfind)" "$BIN/fd"
fi

# ------------------------------------------------------------------------------
# 3. Modern CLI Tools (eza, zoxide, zellij, lazygit, neovim, ghostty)
# ------------------------------------------------------------------------------
# eza
if ! has_cmd eza && [ ! -f "$BIN/eza" ]; then
    log_info "Configuring eza repository..."
    sudo mkdir -p /etc/apt/keyrings
    if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
        sudo apt-get update -qq || true
        sudo apt-get install -y eza 2>/dev/null || true
    fi
fi

# zoxide
if ! has_cmd zoxide; then
    log_info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || true
fi

# zellij
if ! has_cmd zellij && [ ! -f "$BIN/zellij" ]; then
    log_info "Installing Zellij..."
    ARCH="$(uname -m)"
    ZJ_TAR="zellij-${ARCH}-unknown-linux-musl.tar.gz"
    curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/${ZJ_TAR}" -o "/tmp/${ZJ_TAR}" 2>/dev/null || true
    if [ -f "/tmp/${ZJ_TAR}" ]; then
        tar -xzf "/tmp/${ZJ_TAR}" -C "$BIN" 2>/dev/null || true
        chmod +x "$BIN/zellij" 2>/dev/null || true
        rm -f "/tmp/${ZJ_TAR}"
    fi
fi

# lazygit
if ! has_cmd lazygit && [ ! -f "$BIN/lazygit" ]; then
    log_info "Installing lazygit..."
    LG_VER="$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")"
    ARCH="$(uname -m)"
    [ "$ARCH" = "aarch64" ] && LG_ARCH="arm64" || LG_ARCH="x86_64"
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" -o /tmp/lazygit.tar.gz 2>/dev/null || true
    if [ -f /tmp/lazygit.tar.gz ]; then
        tar -xzf /tmp/lazygit.tar.gz -C "$BIN" lazygit 2>/dev/null || true
        chmod +x "$BIN/lazygit" 2>/dev/null || true
        rm -f /tmp/lazygit.tar.gz
    fi
fi

# Neovim (Latest release tarball - Ubuntu's apt version is usually outdated)
if ! has_cmd nvim || [ "$("$BIN/nvim" --version 2>/dev/null | head -n1 | grep -o '0\.[0-9]*' || echo '0.0')" \< "0.10" ]; then
    log_info "Installing Neovim (v0.10+ appimage/binary for LazyVim compatibility)..."
    ARCH="$(uname -m)"
    if [ "$ARCH" = "x86_64" ]; then
        curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o /tmp/nvim.tar.gz 2>/dev/null || true
        if [ -f /tmp/nvim.tar.gz ]; then
            sudo rm -rf /opt/nvim-linux-x86_64
            sudo tar -C /opt -xzf /tmp/nvim.tar.gz 2>/dev/null || true
            sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
            ln -sf /usr/local/bin/nvim "$BIN/nvim"
            rm -f /tmp/nvim.tar.gz
        fi
    fi
fi

# Ghostty terminal (Snap/PPA/binary fallback)
if ! has_cmd ghostty; then
    log_info "Installing Ghostty terminal..."
    if has_cmd snap; then
        sudo snap install ghostty --classic 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 4. Fonts
# ------------------------------------------------------------------------------
log_info "Installing MesloLGS NF and JetBrains Mono fonts..."
FONT_DIR="$DATA/fonts"
mkdir -p "$FONT_DIR"
MESLO_URLS=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
)
for url in "${MESLO_URLS[@]}"; do
    fname="$(basename "$url" | sed 's/%20/ /g')"
    if [ ! -f "${FONT_DIR}/${fname}" ]; then
        curl -fsSL "$url" -o "${FONT_DIR}/${fname}" 2>/dev/null || true
    fi
done
has_cmd fc-cache && fc-cache -f "$FONT_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 5. Link Configs
# ------------------------------------------------------------------------------
log_info "Deploying configurations..."

link_file() {
    local src="$1" dest="$2"
    [ ! -e "$src" ] && return 0
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    [ -e "$dest" ] || [ -L "$dest" ] && mv "$dest" "${dest}.bak.$(date +%s)"
    ln -s "$src" "$dest"
    log_success "Linked: $dest -> $src"
}

# Zsh & Prompt
link_file "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
link_file "${DOTFILES_DIR}/zsh/.zshenv" "$HOME/.zshenv"
link_file "${DOTFILES_DIR}/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Neovim (Tokyo Night)
link_file "${DOTFILES_DIR}/config/nvim" "$CONF/nvim"

# Terminals
link_file "${DOTFILES_DIR}/config/ghostty/config" "$CONF/ghostty/config"
link_file "${DOTFILES_DIR}/config/zellij/config.kdl" "$CONF/zellij/config.kdl"

# Hyprland & Desktop
link_file "${DOTFILES_DIR}/config/hypr" "$CONF/hypr"
link_file "${DOTFILES_DIR}/config/quickshell" "$CONF/quickshell"
link_file "${DOTFILES_DIR}/config/scripts" "$CONF/scripts"
link_file "${DOTFILES_DIR}/config/theme" "$CONF/theme"
link_file "${DOTFILES_DIR}/config/fastfetch" "$CONF/fastfetch"
link_file "${DOTFILES_DIR}/config/starship.toml" "$CONF/starship.toml"

# GTK Themes (Adwaita cursor)
mkdir -p "$CONF/gtk-3.0" "$CONF/gtk-4.0"
link_file "${DOTFILES_DIR}/config/gtk-3.0/settings.ini" "$CONF/gtk-3.0/settings.ini"
link_file "${DOTFILES_DIR}/config/gtk-4.0/settings.ini" "$CONF/gtk-4.0/settings.ini"

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

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
    # Restore link to our zshrc
    ln -sf "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
fi

# Zsh plugins & theme
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || true
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab" 2>/dev/null || true

# Set default shell to Zsh
if [ "$SHELL" != "$(command -v zsh)" ]; then
    log_info "Switching default shell to Zsh..."
    sudo chsh -s "$(command -v zsh)" "$USER" 2>/dev/null || chsh -s "$(command -v zsh)" 2>/dev/null || true
fi

printf "\n%b=================================================================%b\n" "${GREEN}${BOLD}" "${NC}"
printf "%b Ubuntu Dotfiles & Hyprland Setup Completed Successfully! %b\n" "${GREEN}${BOLD}" "${NC}"
printf "%b=================================================================%b\n\n" "${GREEN}${BOLD}" "${NC}"
printf "To start using your new environment, log out and select '%bHyprland%b' at your login screen,\n" "${BOLD}" "${NC}"
printf "or run: %bexec zsh%b\n\n" "${BOLD}" "${NC}"
