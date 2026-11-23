#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & System Setup
# Multi-distro support: Arch Linux, Fedora / RHEL, Ubuntu / Debian / WSL
# One-command complete workstation setup: Shell, Hyprland, Rice, Flatpaks & Tools
# ==============================================================================
set -e

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

# Resolve directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If executed remotely without repo files present, clone first
if [ ! -f "${SCRIPT_DIR}/zsh/.zshrc" ]; then
    log_info "Dotfiles repository not found locally. Cloning into ~/.dotfiles..."
    if [ -d "$HOME/.dotfiles" ]; then
        log_info "Updating existing ~/.dotfiles repo..."
        git -C "$HOME/.dotfiles" pull --rebase || true
    else
        git clone -b nought https://github.com/master3716/dotfiles.git "$HOME/.dotfiles" 2>/dev/null || \
            git clone https://github.com/master3716/dotfiles.git "$HOME/.dotfiles"
    fi
    SCRIPT_DIR="$HOME/.dotfiles"
fi

DOTFILES_DIR="$SCRIPT_DIR"

# Ensure ~/.local/bin and standard paths are in PATH
mkdir -p "$HOME/.local/bin" "$HOME/bin"
export PATH="$HOME/.local/bin:$HOME/bin:/opt/nvim-linux-x86_64/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. Deploy Configuration Files (Safe backup & symlink)
# ------------------------------------------------------------------------------
link_file() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ]; then
        log_warn "Source file does not exist: $src"
        return 0
    fi

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        log_info "Link already in place: $dest -> $src"
        return 0
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local backup_path
        backup_path="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        log_warn "Backing up existing ${dest} to ${backup_path}"
        mv "$dest" "$backup_path"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log_success "Linked: $dest -> $src"
}

deploy_configs() {
    log_info "Deploying dotfiles and configuration files..."

    local CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
    local DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

    # Zsh configs
    link_file "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
    link_file "${DOTFILES_DIR}/zsh/.zshenv" "$HOME/.zshenv"
    link_file "${DOTFILES_DIR}/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    # Zellij config
    link_file "${DOTFILES_DIR}/config/zellij/config.kdl" "${CONF}/zellij/config.kdl"

    # Neovim (LazyVim starter + custom plugins)
    link_file "${DOTFILES_DIR}/config/nvim" "${CONF}/nvim"

    # Ghostty Terminal Config
    link_file "${DOTFILES_DIR}/config/ghostty/config" "${CONF}/ghostty/config"

    # CLI Executables & Wrappers
    mkdir -p "$HOME/.local/bin" "$DATA/dragonball-neofetch" "$DATA/applications"
    for bin_file in "${DOTFILES_DIR}/bin"/*; do
        [ -e "$bin_file" ] || continue
        local bname
        bname="$(basename "$bin_file")"
        link_file "$bin_file" "$HOME/.local/bin/$bname"
    done

    # Steam wrapper & desktop file
    link_file "${DOTFILES_DIR}/config/steam/steam.desktop" "$DATA/applications/steam.desktop"

    # Dragon Ball fetch data
    link_file "${DOTFILES_DIR}/data/dragonball/ascii" "$DATA/dragonball-neofetch/ascii"
    link_file "${DOTFILES_DIR}/data/dragonball/manifest.json" "$DATA/dragonball-neofetch/manifest.json"

    # Ptyxis Terminal Palettes
    mkdir -p "$DATA/org.gnome.Ptyxis/palettes"
    link_file "${DOTFILES_DIR}/config/ptyxis/palettes/tokyo-night.palette" "$DATA/org.gnome.Ptyxis/palettes/tokyo-night.palette"

    # Nothing OS Desktop Shell Config
    if [ -f "${DOTFILES_DIR}/config/nothing/config.json" ]; then
        mkdir -p "${CONF}/nothing"
        if [ ! -f "${CONF}/nothing/config.json" ]; then
            cp "${DOTFILES_DIR}/config/nothing/config.json" "${CONF}/nothing/config.json"
            log_success "Created ${CONF}/nothing/config.json"
        fi
    fi

    # Vesktop App Configurations
    if [ -d "${DOTFILES_DIR}/config/vesktop" ]; then
        local HOST_VESKTOP="${CONF}/vesktop"
        local FLATPAK_VESKTOP="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"

        mkdir -p "$FLATPAK_VESKTOP/settings" "$FLATPAK_VESKTOP/themes"

        [ -f "${DOTFILES_DIR}/config/vesktop/settings.json" ] && [ ! -f "$FLATPAK_VESKTOP/settings.json" ] && \
            cp "${DOTFILES_DIR}/config/vesktop/settings.json" "$FLATPAK_VESKTOP/settings.json"
        [ -f "${DOTFILES_DIR}/config/vesktop/settings/settings.json" ] && [ ! -f "$FLATPAK_VESKTOP/settings/settings.json" ] && \
            cp "${DOTFILES_DIR}/config/vesktop/settings/settings.json" "$FLATPAK_VESKTOP/settings/settings.json"
        [ -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" ] && \
            cp -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" "$FLATPAK_VESKTOP/themes/nothing.theme.css"

        if [ ! -e "$HOST_VESKTOP" ] && [ ! -L "$HOST_VESKTOP" ]; then
            ln -s "$FLATPAK_VESKTOP" "$HOST_VESKTOP" 2>/dev/null || true
        fi
    fi

    # ZapZap Config
    if [ -f "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" ]; then
        local FLATPAK_ZAP="$HOME/.var/app/com.rtosta.zapzap/config/ZapZap"
        mkdir -p "$FLATPAK_ZAP" "${CONF}/ZapZap"
        [ ! -f "$FLATPAK_ZAP/ZapZap.conf" ] && cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$FLATPAK_ZAP/ZapZap.conf" 2>/dev/null || true
        [ ! -f "${CONF}/ZapZap/ZapZap.conf" ] && cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "${CONF}/ZapZap/ZapZap.conf" 2>/dev/null || true
    fi

    # GNOME Dash to Panel & Desktop Settings (if dconf exists)
    if has_cmd dconf; then
        [ -f "${DOTFILES_DIR}/config/gnome/dash-to-panel.dconf" ] && dconf load /org/gnome/shell/extensions/dash-to-panel/ < "${DOTFILES_DIR}/config/gnome/dash-to-panel.dconf" 2>/dev/null || true
        [ -f "${DOTFILES_DIR}/config/gnome/shell-keybindings.dconf" ] && dconf load /org/gnome/shell/keybindings/ < "${DOTFILES_DIR}/config/gnome/shell-keybindings.dconf" 2>/dev/null || true
        [ -f "${DOTFILES_DIR}/config/gnome/mutter.dconf" ] && dconf load /org/gnome/mutter/ < "${DOTFILES_DIR}/config/gnome/mutter.dconf" 2>/dev/null || true
        [ -f "${DOTFILES_DIR}/config/gnome/input-sources.dconf" ] && dconf load /org/gnome/desktop/input-sources/ < "${DOTFILES_DIR}/config/gnome/input-sources.dconf" 2>/dev/null || true
        [ -f "${DOTFILES_DIR}/config/gnome/wm-keybindings.dconf" ] && dconf load /org/gnome/desktop/wm/keybindings/ < "${DOTFILES_DIR}/config/gnome/wm-keybindings.dconf" 2>/dev/null || true
    fi

    # Dash to Panel Super toggle patch (Super opens App Drawer, second press closes directly)
    local DTP_DIR="$HOME/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com"
    if [ -f "${DTP_DIR}/overview.js" ] && [ -f "${DOTFILES_DIR}/config/gnome/dash-to-panel-apps-toggle.patch" ]; then
        if ! grep -q "_adaptAppsPageToggle" "${DTP_DIR}/overview.js"; then
            patch -p1 -d "${DTP_DIR}" < "${DOTFILES_DIR}/config/gnome/dash-to-panel-apps-toggle.patch" 2>/dev/null || true
        fi
    fi
}

# ------------------------------------------------------------------------------
# 2. Zsh, Oh My Zsh, Powerlevel10k & Plugins
# ------------------------------------------------------------------------------
install_zsh_ecosystem() {
    log_info "Setting up Oh My Zsh, Powerlevel10k, and plugins..."

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Cloning Oh My Zsh..."
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || log_warn "Could not clone Oh My Zsh."
    else
        log_info "Oh My Zsh is already present."
    fi

    local CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Powerlevel10k theme
    if [ ! -d "${CUSTOM_DIR}/themes/powerlevel10k" ]; then
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${CUSTOM_DIR}/themes/powerlevel10k" || log_warn "Could not clone powerlevel10k."
    fi

    # Plugins
    mkdir -p "${CUSTOM_DIR}/plugins"

    if [ ! -d "${CUSTOM_DIR}/plugins/zsh-autosuggestions" ]; then
        log_info "Installing zsh-autosuggestions plugin..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${CUSTOM_DIR}/plugins/zsh-autosuggestions" || true
    fi

    if [ ! -d "${CUSTOM_DIR}/plugins/zsh-syntax-highlighting" ]; then
        log_info "Installing zsh-syntax-highlighting plugin..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${CUSTOM_DIR}/plugins/zsh-syntax-highlighting" || true
    fi

    if [ ! -d "${CUSTOM_DIR}/plugins/fzf-tab" ]; then
        log_info "Installing fzf-tab plugin..."
        git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git "${CUSTOM_DIR}/plugins/fzf-tab" || true
    fi
}

# ------------------------------------------------------------------------------
# 3. MesloLGS NF Font (Recommended for Powerlevel10k)
# ------------------------------------------------------------------------------
install_meslo_font() {
    log_info "Installing MesloLGS NF fonts for Powerlevel10k..."
    local font_dir="$HOME/.local/share/fonts/MesloLGS_NF"
    mkdir -p "$font_dir"

    local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
    local font_files=(
        "MesloLGS NF Regular.ttf"
        "MesloLGS NF Bold.ttf"
        "MesloLGS NF Italic.ttf"
        "MesloLGS NF Bold Italic.ttf"
    )

    for font in "${font_files[@]}"; do
        local dest="${font_dir}/${font}"
        if [ ! -f "$dest" ]; then
            log_info "Downloading ${font}..."
            local encoded_font="${font// /%20}"
            curl -fsSL "${base_url}/${encoded_font}" -o "$dest" 2>/dev/null || log_warn "Failed to download ${font}"
        fi
    done

    # Refresh system font cache if fc-cache exists
    if has_cmd fc-cache; then
        log_info "Updating font cache..."
        fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi
    log_success "MesloLGS NF fonts installed in ${font_dir}."
}

# ------------------------------------------------------------------------------
# 4. System Packages (Arch Linux, Fedora / RHEL, Debian / Ubuntu)
# ------------------------------------------------------------------------------
install_system_packages() {
    if has_cmd pacman; then
        log_info "Detected Arch Linux (pacman). Updating package databases and installing packages..."
        sudo pacman -Sy --noconfirm 2>/dev/null || true

        local arch_pkgs=(
            # Build essentials & core
            base-devel git zsh curl wget unzip tar tree jq tmux cmake fontconfig direnv shellcheck
            # Python ecosystem
            python python-pip python-pipx python-pillow python-numpy
            # Modern CLI replacements
            ripgrep fd bat fzf eza zoxide zellij lazygit fastfetch starship neovim
            # Hyprland & Wayland stack
            hyprland hypridle hyprlock hyprpicker hyprsunset quickshell
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            # Audio & PipeWire stack
            pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol playerctl
            # Desktop utilities & media
            brightnessctl wl-clipboard cliphist grim slurp swappy wf-recorder zenity dconf chafa ffmpeg mpv nautilus
            # Polkit
            polkit-kde-agent
            # Fonts
            noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome ttf-inter
            # Flatpak
            flatpak
        )
        sudo pacman -S --noconfirm --needed "${arch_pkgs[@]}" || log_warn "Some pacman packages failed to install."

    elif has_cmd dnf; then
        log_info "Detected Fedora / RHEL (dnf). Configuring repositories..."

        # Enable Coprs for Hyprland, Quickshell, and Ghostty
        if has_cmd sudo; then
            sudo dnf copr enable -y ashbuk/Hyprland-Fedora 2>/dev/null || true
            sudo dnf copr enable -y errornointernet/quickshell 2>/dev/null || true
            sudo dnf copr enable -y scottames/ghostty 2>/dev/null || true
        fi

        local fedora_pkgs=(
            # Shell, build tools, essentials
            zsh git curl wget unzip tar ripgrep fd-find bat fzf tree jq tmux
            python3 python3-pip python3-pillow python3-numpy pipx direnv
            gcc gcc-c++ make cmake fontconfig util-linux-user eza shellcheck flatpak
            # Hyprland & Quickshell
            hyprland hypridle hyprlock quickshell
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            # Audio & utilities
            pipewire wireplumber pavucontrol playerctl brightnessctl
            wl-clipboard cliphist grim slurp swappy wf-recorder zenity dconf chafa ffmpeg mpv nautilus
        )
        sudo dnf install -y --setopt=strict=0 --skip-broken "${fedora_pkgs[@]}" || log_warn "Some core dnf packages failed to install."

    elif has_cmd apt-get; then
        log_info "Detected Debian / Ubuntu (apt). Updating package list..."
        sudo apt-get update -y || true

        # Hyprland & Quickshell PPAs for Ubuntu
        if has_cmd add-apt-repository; then
            if ! grep -rq "cppiber/hyprland" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
                sudo add-apt-repository -y ppa:cppiber/hyprland 2>/dev/null || true
            fi
            if ! grep -rq "avengemedia/danklinux" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
                sudo add-apt-repository -y ppa:avengemedia/danklinux 2>/dev/null || true
            fi
            sudo apt-get update -qq || true
        fi

        local deb_pkgs=(
            zsh git curl wget unzip tar build-essential ripgrep fd-find bat fzf tree jq tmux
            python3 python3-pip python3-venv python3-pil python3-numpy pipx shellcheck direnv
            gcc g++ make cmake fontconfig flatpak
            hyprland hypridle hyprlock quickshell xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl
            wl-clipboard cliphist grim slurp swappy wf-recorder zenity dconf chafa ffmpeg mpv nautilus
        )
        sudo apt-get install -y --no-install-recommends "${deb_pkgs[@]}" || log_warn "Some apt packages failed to install."

        # Setup eza repo if missing
        if ! has_cmd eza; then
            sudo mkdir -p /etc/apt/keyrings
            if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
                sudo apt-get update -qq || true
                sudo apt-get install -y eza 2>/dev/null || true
            fi
        fi
    else
        log_warn "No recognized package manager (pacman, dnf, apt-get) found. Please install core packages manually."
    fi
}

# ------------------------------------------------------------------------------
# 5. Arch Linux AUR Setup (Quickshell, Ghostty)
# ------------------------------------------------------------------------------
install_arch_aur() {
    if ! has_cmd pacman; then
        return 0
    fi

    log_info "Checking Arch Linux AUR packages (Quickshell, Ghostty)..."

    local aur_cmd=""
    if has_cmd yay; then
        aur_cmd="yay"
    elif has_cmd paru; then
        aur_cmd="paru"
    else
        log_info "No AUR helper found. Bootstrapping yay-bin from AUR..."
        local tmpdir="/tmp/yay-bin"
        rm -rf "$tmpdir"
        if git clone https://aur.archlinux.org/yay-bin.git "$tmpdir" 2>/dev/null; then
            (cd "$tmpdir" && makepkg -si --noconfirm) || log_warn "Could not build yay-bin automatically."
            rm -rf "$tmpdir"
            has_cmd yay && aur_cmd="yay"
        fi
    fi

    if [ -n "$aur_cmd" ]; then
        if ! has_cmd quickshell; then
            log_info "Installing quickshell from AUR ($aur_cmd)..."
            $aur_cmd -S --noconfirm --needed quickshell-git 2>/dev/null || $aur_cmd -S --noconfirm --needed quickshell 2>/dev/null || log_warn "Quickshell AUR installation failed."
        fi
        if ! has_cmd ghostty; then
            log_info "Installing ghostty from AUR ($aur_cmd)..."
            $aur_cmd -S --noconfirm --needed ghostty 2>/dev/null || $aur_cmd -S --noconfirm --needed ghostty-bin 2>/dev/null || true
        fi
    else
        log_warn "No AUR helper available. Please install 'quickshell-git' and 'ghostty' manually from the Arch User Repository."
    fi
}

# ------------------------------------------------------------------------------
# 6. Modern CLI Utilities (Standalones & Fallbacks)
# ------------------------------------------------------------------------------
install_modern_tools() {
    local ARCH
    ARCH="$(uname -m)"

    # Fallback for eza: download official release binary if package manager missed it
    if ! has_cmd eza && [ ! -f "$HOME/.local/bin/eza" ] && [ "$ARCH" = "x86_64" ]; then
        log_info "Installing eza standalone binary..."
        curl -fsSL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -o /tmp/eza.tar.gz 2>/dev/null || true
        if [ -f /tmp/eza.tar.gz ]; then
            tar -xzf /tmp/eza.tar.gz -C "$HOME/.local/bin" 2>/dev/null || true
            chmod +x "$HOME/.local/bin/eza" 2>/dev/null || true
            rm -f /tmp/eza.tar.gz
        fi
    fi

    # Zoxide (smarter cd command)
    if ! has_cmd zoxide; then
        log_info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || true
    fi

    # Zellij (terminal multiplexer)
    if ! has_cmd zellij && [ ! -f "$HOME/.local/bin/zellij" ]; then
        log_info "Installing Zellij..."
        local ZJ_URL=""
        if [ "$ARCH" = "x86_64" ]; then
            ZJ_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
        elif [ "$ARCH" = "aarch64" ]; then
            ZJ_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-unknown-linux-musl.tar.gz"
        fi

        if [ -n "$ZJ_URL" ]; then
            curl -fsSL "$ZJ_URL" -o /tmp/zellij.tar.gz 2>/dev/null || true
            if [ -f /tmp/zellij.tar.gz ]; then
                tar -xzf /tmp/zellij.tar.gz -C "$HOME/.local/bin" 2>/dev/null || true
                chmod +x "$HOME/.local/bin/zellij" 2>/dev/null || true
                rm -f /tmp/zellij.tar.gz
            fi
        fi
    fi

    # Lazygit
    if ! has_cmd lazygit && [ ! -f "$HOME/.local/bin/lazygit" ]; then
        log_info "Installing Lazygit..."
        local LG_ARCH="x86_64"
        [ "$ARCH" = "aarch64" ] && LG_ARCH="arm64"
        local LG_VER
        LG_VER="$(curl -sI https://github.com/jesseduffield/lazygit/releases/latest 2>/dev/null | grep -i "^location:" | sed -E 's/.*tag\/(v[0-9.]+).*/\1/' | tr -d '\r\n' || echo "")"
        if [ -z "$LG_VER" ]; then
            LG_VER="$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")"
        fi
        if [ -n "$LG_VER" ]; then
            curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LG_VER}/lazygit_${LG_VER#v}_Linux_${LG_ARCH}.tar.gz" 2>/dev/null || true
            if [ -f /tmp/lazygit.tar.gz ]; then
                tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit 2>/dev/null || true
                install -m 755 /tmp/lazygit "$HOME/.local/bin/lazygit" 2>/dev/null || true
                rm -f /tmp/lazygit /tmp/lazygit.tar.gz
            fi
        fi
    fi

    # Neovim (Ensure version >= 0.10)
    local NEED_NVIM=0
    if ! has_cmd nvim; then
        NEED_NVIM=1
    else
        local NVIM_RAW_VER
        NVIM_RAW_VER="$(nvim --version 2>/dev/null | head -n1 || echo "")"
        if [[ "$NVIM_RAW_VER" =~ v0\.([0-9]+) ]]; then
            if [ "${BASH_REMATCH[1]}" -lt 10 ]; then
                log_info "Existing Neovim version is older than 0.10. Upgrading..."
                NEED_NVIM=1
            fi
        fi
    fi

    if [ "$NEED_NVIM" -eq 1 ] && [ "$ARCH" = "x86_64" ]; then
        log_info "Installing latest Neovim prebuilt release..."
        curl -fsSL -o /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz 2>/dev/null || true
        if [ -f /tmp/nvim-linux-x86_64.tar.gz ]; then
            if has_cmd sudo; then
                sudo rm -rf /opt/nvim-linux-x86_64
                sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz 2>/dev/null || true
                ln -sf /opt/nvim-linux-x86_64/bin/nvim "$HOME/.local/bin/nvim" 2>/dev/null || true
            else
                mkdir -p "$HOME/.local/opt"
                rm -rf "$HOME/.local/opt/nvim-linux-x86_64"
                tar -C "$HOME/.local/opt" -xzf /tmp/nvim-linux-x86_64.tar.gz 2>/dev/null || true
                ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim" 2>/dev/null || true
            fi
            rm -f /tmp/nvim-linux-x86_64.tar.gz
        fi
    fi

    # Pipx tools (IPython)
    if has_cmd pipx; then
        pipx ensurepath >/dev/null 2>&1 || true
        if ! has_cmd ipython; then
            log_info "Installing ipython via pipx..."
            pipx install ipython >/dev/null 2>&1 || true
        fi
    fi

    # Rust & Cargo (rustup)
    if ! has_cmd rustup; then
        log_info "Installing Rust toolchain (rustup)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>/dev/null || true
    fi
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.cargo/env"
    fi
}

# ------------------------------------------------------------------------------
# 7. Ghostty Terminal Emulator
# ------------------------------------------------------------------------------
install_ghostty() {
    if has_cmd ghostty || [ -f "$HOME/.local/bin/ghostty" ]; then
        log_info "Ghostty is already installed."
        return 0
    fi

    log_info "Installing Ghostty terminal emulator..."

    if has_cmd pacman; then
        if has_cmd sudo; then
            sudo pacman -S --noconfirm --needed ghostty 2>/dev/null || true
        fi
        if ! has_cmd ghostty && (has_cmd yay || has_cmd paru); then
            local aur_cmd="yay"; has_cmd paru && aur_cmd="paru"
            $aur_cmd -S --noconfirm --needed ghostty 2>/dev/null || $aur_cmd -S --noconfirm --needed ghostty-bin 2>/dev/null || true
        fi
    elif has_cmd dnf; then
        if has_cmd sudo; then
            sudo dnf copr enable -y scottames/ghostty 2>/dev/null || true
            sudo dnf install -y ghostty 2>/dev/null || true
        fi
    elif has_cmd apt-get; then
        if has_cmd sudo; then
            sudo install -d -m 0755 /etc/apt/keyrings 2>/dev/null || true
            curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg 2>/dev/null || true
            echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list > /dev/null 2>&1 || true
            sudo apt-get update -qq 2>/dev/null || true
            sudo apt-get install -y ghostty 2>/dev/null || true
        fi
    fi

    if ! has_cmd ghostty && [ ! -f "$HOME/.local/bin/ghostty" ] && has_cmd snap; then
        sudo snap install ghostty --classic 2>/dev/null || true
    fi

    if has_cmd ghostty || [ -f "$HOME/.local/bin/ghostty" ]; then
        log_success "Ghostty installed successfully."
    else
        log_warn "Ghostty could not be installed automatically for this distro."
    fi
}

# ------------------------------------------------------------------------------
# 8. Flatpak Desktop Applications (Vesktop, Zen, ZapZap, Spotify, etc.)
# ------------------------------------------------------------------------------
install_flatpaks() {
    log_info "Configuring Flatpak and core desktop applications..."

    if ! has_cmd flatpak; then
        log_warn "Flatpak is not installed. Skipping flatpak app installations."
        return 0
    fi

    # Add Flathub remote
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

    for app in "${flatpak_apps[@]}"; do
        if ! flatpak info "$app" >/dev/null 2>&1; then
            log_info "Installing Flatpak: $app..."
            flatpak install -y --noninteractive flathub "$app" 2>/dev/null || \
                flatpak install --user -y --noninteractive flathub "$app" 2>/dev/null || \
                log_warn "Could not install $app."
        else
            log_info "Flatpak $app is already installed."
        fi
    done

    # Ensure application configuration directories exist and deploy configs
    local VESKTOP_DIR="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"
    mkdir -p "$VESKTOP_DIR/themes" "$VESKTOP_DIR/settings" "$HOME/.config/vesktop"
    if [ -f "${DOTFILES_DIR}/config/vesktop/settings.json" ]; then
        [ ! -f "$VESKTOP_DIR/settings.json" ] && cp "${DOTFILES_DIR}/config/vesktop/settings.json" "$VESKTOP_DIR/settings.json" 2>/dev/null || true
    fi
    if [ -f "${DOTFILES_DIR}/config/vesktop/settings/settings.json" ]; then
        [ ! -f "$VESKTOP_DIR/settings/settings.json" ] && cp "${DOTFILES_DIR}/config/vesktop/settings/settings.json" "$VESKTOP_DIR/settings/settings.json" 2>/dev/null || true
    fi
    if [ -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" ]; then
        cp -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" "$VESKTOP_DIR/themes/nothing.theme.css" 2>/dev/null || true
    fi

    # ZapZap Config
    local ZAPZAP_DIR="$HOME/.var/app/com.rtosta.zapzap/config/ZapZap"
    mkdir -p "$ZAPZAP_DIR" "$HOME/.config/ZapZap"
    if [ -f "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" ]; then
        [ ! -f "$ZAPZAP_DIR/ZapZap.conf" ] && cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$ZAPZAP_DIR/ZapZap.conf" 2>/dev/null || true
        [ ! -f "$HOME/.config/ZapZap/ZapZap.conf" ] && cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$HOME/.config/ZapZap/ZapZap.conf" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 9. Set Default Shell to Zsh
# ------------------------------------------------------------------------------
set_default_shell() {
    if ! has_cmd zsh; then
        log_warn "zsh is not installed. Skipping default shell change."
        return 0
    fi

    local ZSH_PATH
    ZSH_PATH="$(which zsh)"

    if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
        log_info "Setting default shell to ${ZSH_PATH}..."
        if chsh -s "$ZSH_PATH" 2>/dev/null; then
            log_success "Default shell changed to Zsh via chsh."
        elif has_cmd sudo && sudo usermod -s "$ZSH_PATH" "$USER" 2>/dev/null; then
            log_success "Default shell changed to Zsh via usermod."
        else
            log_warn "Could not change shell automatically. Run: chsh -s ${ZSH_PATH} (or sudo usermod -s ${ZSH_PATH} \$USER)"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 10. Nought (Nothing OS) Rice & Theme Integration
# ------------------------------------------------------------------------------
deploy_nought() {
    log_info "Deploying Nought (Nothing OS) Rice & Theme..."

    local CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
    local DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
    local BACKUP_ENV="${CONF}/nought-theme-backup.env"

    # Backup current GNOME / OS theme settings before changing them
    if [ ! -f "$BACKUP_ENV" ]; then
        mkdir -p "$CONF"
        cat <<EOF > "$BACKUP_ENV"
SAVED_COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'prefer-dark'")
SAVED_GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'Adwaita'")
SAVED_ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "'Adwaita'")
SAVED_FONT_NAME=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo "'Adwaita Sans 11'")
SAVED_ACCENT_COLOR=$(gsettings get org.gnome.desktop.interface accent-color 2>/dev/null || echo "''")
SAVED_PICTURE_URI=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || echo "''")
SAVED_PICTURE_URI_DARK=$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null || echo "''")
SAVED_WALLPAPER_ENGINE_ENABLED=$(has_cmd gnome-extensions && gnome-extensions list --enabled 2>/dev/null | grep -q "gnome-wallpaper-engine" && echo "true" || echo "false")
EOF
        log_info "Saved current theme settings to ${BACKUP_ENV}"
    fi

    # OS Theme Decisions
    log_info "Applying Nothing OS theme (GTK, Qt/KDE, Icons, Fonts)..."

    # GTK 3 & GTK 4
    mkdir -p "${CONF}/gtk-3.0" "${CONF}/gtk-4.0"
    link_file "${DOTFILES_DIR}/config/gtk-3.0/settings.ini" "${CONF}/gtk-3.0/settings.ini"
    link_file "${DOTFILES_DIR}/config/gtk-3.0/gtk.css" "${CONF}/gtk-3.0/gtk.css"
    link_file "${DOTFILES_DIR}/config/gtk-4.0/settings.ini" "${CONF}/gtk-4.0/settings.ini"
    link_file "${DOTFILES_DIR}/config/gtk-4.0/gtk.css" "${CONF}/gtk-4.0/gtk.css"

    # Qt / KDE (Dolphin, etc.)
    mkdir -p "${DATA}/color-schemes"
    link_file "${DOTFILES_DIR}/config/theme/kde/color-schemes/Nothing.colors" "${DATA}/color-schemes/Nothing.colors"
    link_file "${DOTFILES_DIR}/config/theme/kde/kdeglobals" "${CONF}/kdeglobals"
    link_file "${DOTFILES_DIR}/config/theme/kde/darklyrc" "${CONF}/darklyrc"

    # Nothing Icon Theme
    mkdir -p "${DATA}/icons/Nothing"
    link_file "${DOTFILES_DIR}/config/theme/icons/Nothing/index.theme" "${DATA}/icons/Nothing/index.theme"
    if [ -f "${DOTFILES_DIR}/config/scripts/build-nothing-icons.py" ]; then
        if python3 -c "import numpy, PIL" 2>/dev/null; then
            log_info "Building Nothing icon theme..."
            python3 "${DOTFILES_DIR}/config/scripts/build-nothing-icons.py" "${DATA}/icons/Nothing" 2>/dev/null || true
        else
            log_warn "Python numpy/pillow not installed; skipping full icon generation."
        fi
    fi
    has_cmd gtk-update-icon-cache && gtk-update-icon-cache -f "${DATA}/icons/hicolor" 2>/dev/null || true

    # Desktop Portals
    mkdir -p "${CONF}/xdg-desktop-portal"
    link_file "${DOTFILES_DIR}/config/theme/xdg-desktop-portal/hyprland-portals.conf" "${CONF}/xdg-desktop-portal/hyprland-portals.conf"
    link_file "${DOTFILES_DIR}/config/theme/xdg-desktop-portal/portals.conf" "${CONF}/xdg-desktop-portal/portals.conf"

    # Fontconfig
    link_file "${DOTFILES_DIR}/config/fontconfig" "${CONF}/fontconfig"
    has_cmd fc-cache && fc-cache -f "${CONF}/fontconfig" 2>/dev/null || true

    # GNOME Theme via gsettings (if running GNOME)
    if has_cmd gsettings; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Nothing' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name 'Inter Variable 10' 2>/dev/null || true

        # Wallpaper
        log_info "Applying Nothing OS wallpaper..."
        gsettings set org.gnome.desktop.background picture-uri "file://${DOTFILES_DIR}/config/hypr/wallpaper.png" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${DOTFILES_DIR}/config/hypr/wallpaper.png" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-options "zoom" 2>/dev/null || true
        if has_cmd gnome-extensions && gnome-extensions list --enabled 2>/dev/null | grep -q "gnome-wallpaper-engine"; then
            gnome-extensions disable gnome-wallpaper-engine@gjs.com 2>/dev/null || true
        fi
    fi

    # Nought Desktop & Compositor Configs
    log_info "Deploying Hyprland and Quickshell configs..."
    link_file "${DOTFILES_DIR}/config/hypr" "${CONF}/hypr"
    mkdir -p "${CONF}/quickshell"
    link_file "${DOTFILES_DIR}/config/quickshell/nothing" "${CONF}/quickshell/nothing"
    link_file "${DOTFILES_DIR}/config/scripts" "${CONF}/scripts"
    link_file "${DOTFILES_DIR}/config/theme" "${CONF}/theme"
    link_file "${DOTFILES_DIR}/config/fastfetch" "${CONF}/fastfetch"
    link_file "${DOTFILES_DIR}/config/starship.toml" "${CONF}/starship.toml"
    mkdir -p "${CONF}/fish/conf.d"
    link_file "${DOTFILES_DIR}/config/fish/conf.d/nothing.fish" "${CONF}/fish/conf.d/nothing.fish"

    # Applications and Icons
    mkdir -p "${DATA}/applications" "${DATA}/icons/hicolor/scalable/apps" "${DATA}/kio/servicemenus"
    link_file "${DOTFILES_DIR}/applications/nothing-x.desktop" "${DATA}/applications/nothing-x.desktop"
    link_file "${DOTFILES_DIR}/icons/hicolor/scalable/apps/nothing-x.svg" "${DATA}/icons/hicolor/scalable/apps/nothing-x.svg"
    link_file "${DOTFILES_DIR}/applications/servicemenus/nothing-set-wallpaper.desktop" "${DATA}/kio/servicemenus/nothing-set-wallpaper.desktop"

    has_cmd update-desktop-database && update-desktop-database "${DATA}/applications" 2>/dev/null || true

    log_success "Nought (Nothing OS) Rice & Theme deployed successfully!"
}

revert_nought() {
    if [ -f "${DOTFILES_DIR}/revert-nought.sh" ]; then
        bash "${DOTFILES_DIR}/revert-nought.sh"
    else
        log_error "revert-nought.sh not found."
    fi
}

show_help() {
    cat <<'EOF'
Usage: ./install.sh [OPTION]

One-command Dotfiles, Hyprland rice, and desktop application installer.
Supports Arch Linux, Fedora, and Debian / Ubuntu.

By default (with no options), runs the complete setup:
  - Deploys dotfiles & symlinks
  - Installs Zsh + Oh My Zsh + Powerlevel10k + plugins
  - Installs MesloLGS NF fonts
  - Installs system packages & desktop dependencies
  - Bootstraps AUR helper (yay) & installs Quickshell / Ghostty on Arch Linux
  - Installs modern CLI utilities (Neovim, Zellij, Lazygit, eza, zoxide, etc.)
  - Installs Flatpak desktop apps (Vesktop, Zen Browser, ZapZap, Spotify, etc.)
  - Deploys Nought (Nothing OS) Hyprland desktop rice & theme
  - Sets default shell to Zsh

Options:
  -h, --help            Show this help message
  -u, --ubuntu          Run Ubuntu-specific script (install-ubuntu.sh)
      --core-only       Install CLI tools and configs only (skip desktop rice and flatpaks)
      --no-flatpak      Skip Flatpak desktop application installations
  -n, --nought          Deploy Nought rice and themes only
      --revert-nought   Revert Nought theme and configs back to original state
  -a, --all             Run full dotfiles installation (default behavior)

EOF
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    local RUN_UBUNTU=false
    local RUN_NOUGHT=true
    local RUN_FLATPAK=true
    local RUN_CORE=true
    local RUN_REVERT_NOUGHT=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -u|--ubuntu)
                RUN_UBUNTU=true
                RUN_CORE=false
                RUN_NOUGHT=false
                RUN_FLATPAK=false
                shift
                ;;
            --core-only)
                RUN_CORE=true
                RUN_NOUGHT=false
                RUN_FLATPAK=false
                shift
                ;;
            --no-flatpak)
                RUN_FLATPAK=false
                shift
                ;;
            -n|--nought)
                RUN_NOUGHT=true
                RUN_CORE=false
                RUN_FLATPAK=false
                shift
                ;;
            --revert-nought|--revert)
                RUN_REVERT_NOUGHT=true
                RUN_CORE=false
                RUN_NOUGHT=false
                RUN_FLATPAK=false
                shift
                ;;
            -a|--all)
                RUN_CORE=true
                RUN_NOUGHT=true
                RUN_FLATPAK=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ "$RUN_UBUNTU" = true ]; then
        if [ -f "${DOTFILES_DIR}/install-ubuntu.sh" ]; then
            bash "${DOTFILES_DIR}/install-ubuntu.sh"
            exit 0
        else
            log_error "install-ubuntu.sh not found."
            exit 1
        fi
    fi

    if [ "$RUN_REVERT_NOUGHT" = true ]; then
        revert_nought
        exit 0
    fi

    if [ "$RUN_CORE" = true ]; then
        printf "\n%b========================================%b\n" "${BOLD}" "${NC}"
        printf "%b   Installing Complete Dotfiles Setup   %b\n" "${BOLD}" "${NC}"
        printf "%b========================================%b\n\n" "${BOLD}" "${NC}"
        log_info "Using dotfiles from: ${DOTFILES_DIR}"

        # Step 1: Deploy configs first so settings are immediately staged
        deploy_configs

        # Step 2: Install Oh My Zsh + Powerlevel10k + plugins
        install_zsh_ecosystem

        # Step 3: Install MesloLGS NF fonts (for Powerlevel10k & icons)
        install_meslo_font

        # Step 4: Install core & desktop system packages (Arch / Fedora / Ubuntu)
        install_system_packages

        # Step 5: Arch Linux AUR packages (Quickshell, Ghostty)
        install_arch_aur

        # Step 6: Install modern CLI utilities (eza, zellij, lazygit, neovim, etc.)
        install_modern_tools

        # Step 7: Install Ghostty terminal emulator
        install_ghostty

        # Step 8: Switch shell to Zsh
        set_default_shell
    fi

    if [ "$RUN_FLATPAK" = true ]; then
        # Step 9: Install Flatpak apps & configurations (Vesktop, Zen, ZapZap, Spotify, etc.)
        install_flatpaks
    fi

    if [ "$RUN_NOUGHT" = true ]; then
        # Step 10: Deploy Nought (Nothing OS) desktop rice, icons, and themes
        deploy_nought
    fi

    printf "\n%b========================================%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%bSetup completed successfully!%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%b========================================%b\n\n" "${GREEN}${BOLD}" "${NC}"
    printf "MesloLGS NF fonts have been installed to %b~/.local/share/fonts%b.\n" "${BOLD}" "${NC}"
    printf "Applications configured: Vesktop, Zen Browser, ZapZap, Ghostty, Neovim, Nothing OS Rice.\n\n"
    printf "To start using your new environment right now, run:\n"
    printf "  %bexec zsh%b\n\n" "${BOLD}" "${NC}"
}

main "$@"
