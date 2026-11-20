#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & System Setup
# Multi-distro support: Fedora / RHEL, Ubuntu / Debian / WSL, Arch Linux
# ==============================================================================

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
        git clone https://github.com/master3716/dotfiles.git "$HOME/.dotfiles"
    fi
    SCRIPT_DIR="$HOME/.dotfiles"
fi

DOTFILES_DIR="$SCRIPT_DIR"
log_info "Using dotfiles from: ${DOTFILES_DIR}"

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

    # Zsh configs
    link_file "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
    link_file "${DOTFILES_DIR}/zsh/.zshenv" "$HOME/.zshenv"
    link_file "${DOTFILES_DIR}/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    # Zellij config
    link_file "${DOTFILES_DIR}/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

    # Neovim (LazyVim starter + custom plugins)
    link_file "${DOTFILES_DIR}/config/nvim" "$HOME/.config/nvim"

    # Neofetch & Dragon Ball fetch
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/dragonball-neofetch" "$HOME/.local/share/applications"
    link_file "${DOTFILES_DIR}/bin/neofetch" "$HOME/.local/bin/neofetch"
    link_file "${DOTFILES_DIR}/bin/dbfetch" "$HOME/.local/bin/dbfetch"
    link_file "${DOTFILES_DIR}/bin/steam" "$HOME/.local/bin/steam"
    link_file "${DOTFILES_DIR}/config/steam/steam.desktop" "$HOME/.local/share/applications/steam.desktop"
    link_file "${DOTFILES_DIR}/data/dragonball/ascii" "$HOME/.local/share/dragonball-neofetch/ascii"
    link_file "${DOTFILES_DIR}/data/dragonball/manifest.json" "$HOME/.local/share/dragonball-neofetch/manifest.json"

    # Ptyxis Terminal Palettes
    mkdir -p "$HOME/.local/share/org.gnome.Ptyxis/palettes"
    link_file "${DOTFILES_DIR}/config/ptyxis/palettes/tokyo-night.palette" "$HOME/.local/share/org.gnome.Ptyxis/palettes/tokyo-night.palette"

    # Ghostty Terminal Config
    link_file "${DOTFILES_DIR}/config/ghostty/config" "$HOME/.config/ghostty/config"

    # GNOME Dash to Panel & Desktop Settings
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

    # Direct git clone of Oh My Zsh (fast, reliable, no prompt conflicts)
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
# 4. System Packages (APT / DNF / Pacman)
# ------------------------------------------------------------------------------
install_system_packages() {
    if has_cmd dnf; then
        log_info "Detected Fedora / RHEL (dnf). Installing packages..."
        local fedora_pkgs=(
            zsh
            git
            curl
            wget
            unzip
            ripgrep
            fd-find
            bat
            fzf
            tree
            jq
            tmux
            python3
            python3-pip
            pipx
            direnv
            gcc
            gcc-c++
            make
            cmake
            fontconfig
            util-linux-user
        )
        # Use --setopt=strict=0 and --skip-broken so unavailable optional packages do not abort installation
        sudo dnf install -y --setopt=strict=0 --skip-broken "${fedora_pkgs[@]}" || log_warn "Some core dnf packages failed to install."

        # Try installing optional packages individually
        sudo dnf install -y --setopt=strict=0 --skip-broken eza 2>/dev/null || true
        sudo dnf install -y --setopt=strict=0 --skip-broken ShellCheck 2>/dev/null || sudo dnf install -y --setopt=strict=0 --skip-broken shellcheck 2>/dev/null || true
        sudo dnf install -y --setopt=strict=0 --skip-broken fd 2>/dev/null || true

    elif has_cmd apt-get; then
        log_info "Detected Debian / Ubuntu (apt). Updating package list..."
        sudo apt-get update -y || true

        local deb_pkgs=(
            zsh
            git
            curl
            wget
            unzip
            build-essential
            ripgrep
            fd-find
            bat
            fzf
            tree
            jq
            tmux
            python3
            python3-pip
            python3-venv
            pipx
            shellcheck
            direnv
            gcc
            g++
            make
            cmake
            fontconfig
        )

        log_info "Installing core system packages..."
        sudo apt-get install -y "${deb_pkgs[@]}" || log_warn "Some apt packages failed to install."

        # Setup eza repo if not already installed
        if ! has_cmd eza; then
            log_info "Configuring eza package repository..."
            sudo mkdir -p /etc/apt/keyrings
            if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
                sudo apt-get update -qq || true
                sudo apt-get install -y eza 2>/dev/null || true
            fi
        fi

    elif has_cmd pacman; then
        log_info "Detected Arch Linux (pacman). Installing packages..."
        local arch_pkgs=(
            zsh
            git
            curl
            wget
            unzip
            base-devel
            ripgrep
            fd
            bat
            fzf
            tree
            jq
            tmux
            python
            python-pip
            python-pipx
            shellcheck
            direnv
            cmake
            eza
            fontconfig
        )
        sudo pacman -S --noconfirm --needed "${arch_pkgs[@]}" || log_warn "Some pacman packages failed to install."
    else
        log_warn "No recognized package manager (dnf, apt-get, pacman) found. Please install core packages manually."
    fi
}

# ------------------------------------------------------------------------------
# 4. Modern CLI Utilities
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

    # Neovim (Latest official prebuilt release)
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
    if has_cmd rustup; then
        log_info "Configuring Rust components (rust-src, rust-analyzer, clippy, rustfmt)..."
        rustup component add rust-src rust-analyzer clippy rustfmt >/dev/null 2>&1 || true
    fi
}

# ------------------------------------------------------------------------------
# 5. Ghostty Terminal Emulator
# ------------------------------------------------------------------------------
install_ghostty() {
    if has_cmd ghostty || [ -f "$HOME/.local/bin/ghostty" ]; then
        log_info "Ghostty is already installed."
        return 0
    fi

    log_info "Installing Ghostty terminal emulator..."

    if has_cmd dnf; then
        if has_cmd sudo; then
            sudo dnf copr enable -y scottames/ghostty 2>/dev/null || true
            sudo dnf install -y ghostty 2>/dev/null || true
        fi
    elif has_cmd pacman; then
        if has_cmd sudo; then
            sudo pacman -S --noconfirm --needed ghostty 2>/dev/null || true
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
# 6. Set Default Shell to Zsh
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
        # Try standard chsh first
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
# 7. Nought (Nothing OS) Rice & Theme Integration
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
EOF
        log_info "Saved current theme settings to ${BACKUP_ENV}"
    fi

    # OS Theme Decisions (Rule: Stick with repo's version for OS theme)
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

    # GNOME Theme via gsettings
    if has_cmd gsettings; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Nothing' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name 'Inter Variable 10' 2>/dev/null || true
    fi

    # Nought Desktop & Compositor Configs
    log_info "Deploying Hyprland and Quickshell configs..."
    link_file "${DOTFILES_DIR}/config/hypr" "${CONF}/hypr"
    mkdir -p "${CONF}/quickshell"
    link_file "${DOTFILES_DIR}/config/quickshell/nothing" "${CONF}/quickshell/nothing"
    link_file "${DOTFILES_DIR}/config/scripts" "${CONF}/scripts"
    link_file "${DOTFILES_DIR}/config/theme" "${CONF}/theme"
    link_file "${DOTFILES_DIR}/config/fastfetch" "${CONF}/fastfetch"
    link_file "${DOTFILES_DIR}/config/kitty" "${CONF}/kitty"
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
    log_info "To revert at any time, run: ./revert-nought.sh (or ./install.sh --revert-nought)"
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

Dotfiles installer with multi-distro and Nought (Nothing OS) rice support.

Options:
  -h, --help            Show this help message
  -n, --nought          Deploy Nought (Nothing OS) desktop rice and theme
      --revert-nought   Revert Nought theme and configs back to original state
  -a, --all             Run full dotfiles installation and deploy Nought rice
      --revert          Alias for --revert-nought

Without options, installs core dotfiles, shell, fonts, and terminal tools.
EOF
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    local RUN_NOUGHT=false
    local RUN_REVERT_NOUGHT=false
    local RUN_CORE=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--nought)
                RUN_NOUGHT=true
                RUN_CORE=false
                shift
                ;;
            --revert-nought|--revert)
                RUN_REVERT_NOUGHT=true
                RUN_CORE=false
                shift
                ;;
            -a|--all)
                RUN_CORE=true
                RUN_NOUGHT=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ "$RUN_REVERT_NOUGHT" = true ]; then
        revert_nought
        exit 0
    fi

    if [ "$RUN_CORE" = true ]; then
        printf "\n%b========================================%b\n" "${BOLD}" "${NC}"
        printf "%b   Installing Dotfiles & Shell Setup    %b\n" "${BOLD}" "${NC}"
        printf "%b========================================%b\n\n" "${BOLD}" "${NC}"

        # Step 1: Deploy configs first so your settings are immediately staged
        deploy_configs

        # Step 2: Install Oh My Zsh + Powerlevel10k + plugins
        install_zsh_ecosystem

        # Step 3: Install MesloLGS NF fonts (for Powerlevel10k & icon glyphs)
        install_meslo_font

        # Step 4: Install core system packages
        install_system_packages

        # Step 5: Install modern CLI utilities (eza, zellij, lazygit, neovim, etc.)
        install_modern_tools

        # Step 6: Install Ghostty terminal emulator
        install_ghostty

        # Step 7: Switch shell to Zsh
        set_default_shell
    fi

    if [ "$RUN_NOUGHT" = true ]; then
        deploy_nought
    fi

    printf "\n%b========================================%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%bSetup completed successfully!%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%b========================================%b\n\n" "${GREEN}${BOLD}" "${NC}"
    printf "MesloLGS NF fonts have been installed to %b~/.local/share/fonts%b.\n" "${BOLD}" "${NC}"
    printf "(In your terminal emulator settings, select font: %bMesloLGS NF%b)\n\n" "${BOLD}" "${NC}"
    printf "To start using your new environment right now, run:\n"
    printf "  %bexec zsh%b\n\n" "${BOLD}" "${NC}"
    if [ "$RUN_NOUGHT" = false ]; then
        printf "%bTip:%b To deploy the Nothing OS rice and theme, run: %b./install.sh --nought%b\n" "${YELLOW}" "${NC}" "${BOLD}" "${NC}"
        printf "     To revert at any time, run: %b./revert-nought.sh%b\n\n" "${BOLD}" "${NC}"
    fi
}

main "$@"
