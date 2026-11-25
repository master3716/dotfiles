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

OFFLINE_MODE=false
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

    printf "\n%b========================================%b\n" "${YELLOW}${BOLD}" "${NC}"
    printf "%b   Summary: Items Not Installed         %b\n" "${YELLOW}${BOLD}" "${NC}"
    printf "%b========================================%b\n" "${YELLOW}${BOLD}" "${NC}"
    log_warn "The installer continued and finished the remaining setup, but these items could not be installed:"
    local item
    for item in "${FAILED_ITEMS[@]}"; do
        printf "  %b-%b %s\n" "${YELLOW}" "${NC}" "$item"
    done
    printf "\nYou can install or retry any missing items manually later.\n"
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

    # Neovim (LazyVim starter + custom plugins + offline plugin bundle)
    link_file "${DOTFILES_DIR}/config/nvim" "${CONF}/nvim"
    if [ ! -d "${DATA}/nvim/lazy/lazy.nvim" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/nvim/lazy.tar.xz"; then
        log_info "Restoring vendored LazyVim plugins to ${DATA}/nvim/lazy..."
        extract_vendor_archive "${DOTFILES_DIR}/vendor/nvim/lazy.tar.xz" "${DATA}/nvim" || \
            log_warn "Could not extract vendored LazyVim plugins."
    fi

    # Ghostty Terminal Config
    link_file "${DOTFILES_DIR}/config/ghostty/config" "${CONF}/ghostty/config"

    # CLI Executables & Wrappers
    mkdir -p "$HOME/.local/bin" "$DATA/dragonball-neofetch" "$DATA/applications"
    chmod +x "${DOTFILES_DIR}/bin/"* 2>/dev/null || true
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

    # MPV Media Player Config
    [ -d "${DOTFILES_DIR}/config/mpv" ] && link_file "${DOTFILES_DIR}/config/mpv" "${CONF}/mpv"

    # Nothing OS Desktop Shell Config & Wallpapers
    if [ -f "${DOTFILES_DIR}/config/nothing/config.json" ]; then
        mkdir -p "${CONF}/nothing"
        if [ ! -f "${CONF}/nothing/config.json" ]; then
            cp "${DOTFILES_DIR}/config/nothing/config.json" "${CONF}/nothing/config.json" 2>/dev/null && \
                log_success "Created ${CONF}/nothing/config.json" || true
        elif grep -q '"/home/oferg/HardDrive/Downloads/goku.jpg"' "${CONF}/nothing/config.json" 2>/dev/null && [ ! -f "/home/oferg/HardDrive/Downloads/goku.jpg" ]; then
            sed -i 's|"/home/oferg/HardDrive/Downloads/goku.jpg"|"~/.config/hypr/wallpapers/goku.jpg"|g' "${CONF}/nothing/config.json" 2>/dev/null || true
        fi
    fi
    mkdir -p "$HOME/Pictures/Wallpapers"
    for wp in goku.jpg kame.jpg; do
        [ -f "${DOTFILES_DIR}/config/hypr/wallpapers/${wp}" ] && [ ! -f "$HOME/Pictures/Wallpapers/${wp}" ] && \
            cp "${DOTFILES_DIR}/config/hypr/wallpapers/${wp}" "$HOME/Pictures/Wallpapers/${wp}" 2>/dev/null || true
    done

    # Vesktop App Configurations
    if [ -d "${DOTFILES_DIR}/config/vesktop" ]; then
        local HOST_VESKTOP="${CONF}/vesktop"
        local FLATPAK_VESKTOP="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"

        mkdir -p "$FLATPAK_VESKTOP/settings" "$FLATPAK_VESKTOP/themes"

        if [ -f "${DOTFILES_DIR}/config/vesktop/settings.json" ] && [ ! -f "$FLATPAK_VESKTOP/settings.json" ]; then
            cp "${DOTFILES_DIR}/config/vesktop/settings.json" "$FLATPAK_VESKTOP/settings.json" 2>/dev/null || true
        fi
        if [ -f "${DOTFILES_DIR}/config/vesktop/settings/settings.json" ] && [ ! -f "$FLATPAK_VESKTOP/settings/settings.json" ]; then
            cp "${DOTFILES_DIR}/config/vesktop/settings/settings.json" "$FLATPAK_VESKTOP/settings/settings.json" 2>/dev/null || true
        fi
        if [ -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" ]; then
            cp -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" "$FLATPAK_VESKTOP/themes/nothing.theme.css" 2>/dev/null || true
        fi

        if [ ! -e "$HOST_VESKTOP" ] && [ ! -L "$HOST_VESKTOP" ]; then
            ln -s "$FLATPAK_VESKTOP" "$HOST_VESKTOP" 2>/dev/null || true
        fi
    fi

    # ZapZap Config
    if [ -f "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" ]; then
        local FLATPAK_ZAP="$HOME/.var/app/com.rtosta.zapzap/config/ZapZap"
        mkdir -p "$FLATPAK_ZAP" "${CONF}/ZapZap"
        [ ! -f "$FLATPAK_ZAP/ZapZap.conf" ] && { cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$FLATPAK_ZAP/ZapZap.conf" 2>/dev/null || true; }
        [ ! -f "${CONF}/ZapZap/ZapZap.conf" ] && { cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "${CONF}/ZapZap/ZapZap.conf" 2>/dev/null || true; }
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

    local VENDOR_OMZ="${DOTFILES_DIR}/vendor/zsh/oh-my-zsh.tar.xz"
    if [ ! -d "$HOME/.oh-my-zsh" ] && has_vendor_archive "$VENDOR_OMZ"; then
        log_info "Installing Oh My Zsh, Powerlevel10k, and plugins from local repo..."
        extract_vendor_archive "$VENDOR_OMZ" "$HOME" || log_warn "Could not extract vendored Oh My Zsh."
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        if [ "$OFFLINE_MODE" = true ]; then
            log_warn "Oh My Zsh missing and offline mode is enabled."
            record_failure "Zsh" "oh-my-zsh" "not found locally in offline mode"
            return 0
        fi
        log_info "Cloning Oh My Zsh..."
        if ! git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"; then
            log_warn "Could not clone Oh My Zsh."
            record_failure "Zsh" "oh-my-zsh" "git clone failed"
        fi
    else
        log_info "Oh My Zsh is ready."
    fi

    local CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Powerlevel10k theme
    if [ ! -d "${CUSTOM_DIR}/themes/powerlevel10k" ]; then
        if [ "$OFFLINE_MODE" = true ]; then
            record_failure "Zsh" "powerlevel10k" "missing in offline mode"
        else
            log_info "Installing Powerlevel10k theme..."
            if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${CUSTOM_DIR}/themes/powerlevel10k"; then
                log_warn "Could not clone powerlevel10k."
                record_failure "Zsh" "powerlevel10k" "git clone failed"
            fi
        fi
    fi

    # Plugins
    mkdir -p "${CUSTOM_DIR}/plugins"

    if [ ! -d "${CUSTOM_DIR}/plugins/zsh-autosuggestions" ]; then
        if [ "$OFFLINE_MODE" = true ]; then
            record_failure "Zsh plugin" "zsh-autosuggestions" "missing in offline mode"
        else
            log_info "Installing zsh-autosuggestions plugin..."
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${CUSTOM_DIR}/plugins/zsh-autosuggestions" || \
                record_failure "Zsh plugin" "zsh-autosuggestions" "git clone failed"
        fi
    fi

    if [ ! -d "${CUSTOM_DIR}/plugins/zsh-syntax-highlighting" ]; then
        if [ "$OFFLINE_MODE" = true ]; then
            record_failure "Zsh plugin" "zsh-syntax-highlighting" "missing in offline mode"
        else
            log_info "Installing zsh-syntax-highlighting plugin..."
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${CUSTOM_DIR}/plugins/zsh-syntax-highlighting" || \
                record_failure "Zsh plugin" "zsh-syntax-highlighting" "git clone failed"
        fi
    fi

    if [ ! -d "${CUSTOM_DIR}/plugins/fzf-tab" ]; then
        if [ "$OFFLINE_MODE" = true ]; then
            record_failure "Zsh plugin" "fzf-tab" "missing in offline mode"
        else
            log_info "Installing fzf-tab plugin..."
            git clone --depth=1 https://github.com/Aloxaf/fzf-tab.git "${CUSTOM_DIR}/plugins/fzf-tab" || \
                record_failure "Zsh plugin" "fzf-tab" "git clone failed"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. MesloLGS NF & Inter Fonts (Local-first, with online fallback)
# ------------------------------------------------------------------------------
install_meslo_font() {
    log_info "Installing MesloLGS NF and Inter fonts..."
    local fonts_root="$HOME/.local/share/fonts"
    local font_dir="${fonts_root}/MesloLGS_NF"
    mkdir -p "$font_dir"

    if has_vendor_archive "${DOTFILES_DIR}/vendor/fonts/MesloLGS_NF.tar.xz"; then
        extract_vendor_archive "${DOTFILES_DIR}/vendor/fonts/MesloLGS_NF.tar.xz" "$fonts_root" || true
    fi
    if [ ! -d "${fonts_root}/Inter" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/fonts/Inter.tar.xz"; then
        extract_vendor_archive "${DOTFILES_DIR}/vendor/fonts/Inter.tar.xz" "$fonts_root" || true
    fi

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
            if [ "$OFFLINE_MODE" = true ]; then
                record_failure "Font" "$font" "missing in offline mode"
                continue
            fi
            log_info "Downloading ${font}..."
            local encoded_font="${font// /%20}"
            if ! curl -fsSL "${base_url}/${encoded_font}" -o "$dest" 2>/dev/null; then
                rm -f "$dest"
                log_warn "Failed to download ${font}"
                record_failure "Font" "$font" "download failed"
            fi
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
            # Python ecosystem & package management
            python python-pip python-pipx python-pillow python-numpy uv
            # Modern CLI replacements, monitors & cloud/containers
            ripgrep fd bat fzf eza zoxide zellij lazygit fastfetch starship neovim htop btop
            podman podman-compose rclone tailscale
            # Hyprland & Wayland stack (quickshell handled via pacman/AUR in install_arch_aur)
            hyprland hypridle hyprlock hyprpicker hyprsunset
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            # Audio & PipeWire stack
            pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol playerctl
            # Desktop utilities & media
            brightnessctl wl-clipboard cliphist grim slurp swappy wf-recorder swaybg zenity dconf chafa ffmpeg mpv nautilus
            # Polkit
            polkit-kde-agent
            # Fonts & Icon Themes
            noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome ttf-inter papirus-icon-theme adwaita-icon-theme hicolor-icon-theme
            # Flatpak
            flatpak
        )
        if ! sudo pacman -S --noconfirm --needed "${arch_pkgs[@]}"; then
            log_warn "Bulk pacman install failed; retrying packages individually so remaining packages still install..."
            local pkg
            for pkg in "${arch_pkgs[@]}"; do
                if ! sudo pacman -S --noconfirm --needed "$pkg" >/dev/null 2>&1; then
                    log_warn "Failed to install pacman package: $pkg"
                    record_failure "pacman" "$pkg" "not found or install failed"
                fi
            done
        fi

    elif has_cmd dnf; then
        log_info "Detected Fedora / RHEL (dnf). Configuring repositories..."

        # Enable Coprs only if online and not already provided by local/Artifactory repos
        if [ "$OFFLINE_MODE" = false ] && has_cmd sudo; then
            local copr_pairs=(
                "hyprland:ashbuk/Hyprland-Fedora"
                "quickshell:errornointernet/quickshell"
                "ghostty:scottames/ghostty"
            )
            local pair check_pkg copr
            for pair in "${copr_pairs[@]}"; do
                check_pkg="${pair%%:*}"
                copr="${pair#*:}"
                if ! dnf list --available "$check_pkg" >/dev/null 2>&1; then
                    if ! sudo dnf copr enable -y "$copr" 2>/dev/null; then
                        log_warn "Could not enable Copr: $copr"
                        record_failure "dnf copr" "$copr" "repo enable failed"
                    fi
                fi
            done
        fi

        local fedora_pkgs=(
            # Shell, build tools, essentials
            zsh git curl wget unzip tar ripgrep fd-find bat fzf tree jq tmux
            python3 python3-pip python3-pillow python3-numpy pipx direnv uv
            gcc gcc-c++ make cmake fontconfig util-linux-user eza shellcheck flatpak
            # CLI tools, monitors, containers & cloud
            fastfetch htop btop rclone podman podman-compose tailscale
            # Hyprland & Quickshell
            hyprland hypridle hyprlock quickshell
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            # Audio & utilities
            pipewire wireplumber pavucontrol playerctl brightnessctl
            wl-clipboard cliphist grim slurp swappy wf-recorder swaybg zenity dconf chafa ffmpeg mpv nautilus papirus-icon-theme adwaita-icon-theme hicolor-icon-theme
        )
        sudo dnf install -y --setopt=strict=0 --skip-broken "${fedora_pkgs[@]}" || log_warn "Some core dnf packages failed to install."

        local pkg
        for pkg in "${fedora_pkgs[@]}"; do
            if ! rpm -q --whatprovides "$pkg" >/dev/null 2>&1 && ! has_cmd "$pkg"; then
                case "$pkg" in
                    eza|uv|rclone|fastfetch) ;; # vendored / standalone fallbacks handled in steps 6 & 7
                    *)
                        log_warn "Package not installed via dnf: $pkg"
                        record_failure "dnf" "$pkg" "skipped or not found in repos"
                        ;;
                esac
            fi
        done

    elif has_cmd apt-get; then
        log_info "Detected Debian / Ubuntu (apt). Updating package list..."
        sudo apt-get update -y || log_warn "apt-get update returned warnings."

        # Hyprland & Quickshell PPAs for Ubuntu (only if online and not already in configured/Artifactory repos)
        if [ "$OFFLINE_MODE" = false ] && has_cmd add-apt-repository; then
            local ppa_added=false
            if ! apt-cache show hyprland >/dev/null 2>&1 && ! grep -rq "cppiber/hyprland" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
                if sudo add-apt-repository -y ppa:cppiber/hyprland 2>/dev/null; then
                    ppa_added=true
                else
                    log_warn "Could not add ppa:cppiber/hyprland"
                    record_failure "apt PPA" "ppa:cppiber/hyprland" "failed to add"
                fi
            fi
            if ! apt-cache show quickshell >/dev/null 2>&1 && ! grep -rq "avengemedia/danklinux" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
                if sudo add-apt-repository -y ppa:avengemedia/danklinux 2>/dev/null; then
                    ppa_added=true
                else
                    log_warn "Could not add ppa:avengemedia/danklinux"
                    record_failure "apt PPA" "ppa:avengemedia/danklinux" "failed to add"
                fi
            fi
            [ "$ppa_added" = true ] && { sudo apt-get update -qq || true; }
        fi

        local deb_pkgs=(
            zsh git curl wget unzip tar build-essential ripgrep fd-find bat fzf tree jq tmux
            python3 python3-pip python3-venv python3-pil python3-numpy pipx shellcheck direnv
            gcc g++ make cmake fontconfig flatpak
            htop btop rclone podman podman-compose
            hyprland hypridle hyprlock hyprland-guiutils quickshell
            qml6-module-qtquick-layouts qml6-module-qtquick-controls qml6-module-qt5compat-graphicaleffects qml6-module-qtquick-effects
            swaybg waybar wofi foot libnotify-bin papirus-icon-theme adwaita-icon-theme hicolor-icon-theme yaru-theme-icon
            xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
            pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl
            wl-clipboard cliphist grim slurp swappy wf-recorder zenity dconf chafa ffmpeg mpv nautilus
        )
        if ! sudo apt-get install -y --no-install-recommends "${deb_pkgs[@]}"; then
            log_warn "Bulk apt install hit unavailable packages; retrying individually so remaining packages still install..."
            local pkg
            for pkg in "${deb_pkgs[@]}"; do
                if ! sudo apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1; then
                    case "$pkg" in
                        rclone) ;; # vendored / standalone fallback runs in install_developer_tools
                        *)
                            log_warn "Failed to install apt package: $pkg"
                            record_failure "apt" "$pkg" "not available or install failed"
                            ;;
                    esac
                fi
            done
        fi

        # Fix Ubuntu command name quirks (batcat -> bat, fdfind -> fd)
        if has_cmd batcat && ! has_cmd bat; then
            ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat" 2>/dev/null || true
        fi
        if has_cmd fdfind && ! has_cmd fd; then
            ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
        fi

        # Setup eza repo only if missing from apt/Artifactory and not vendored/offline
        if ! has_cmd eza; then
            if apt-cache show eza >/dev/null 2>&1; then
                sudo apt-get install -y eza 2>/dev/null || true
            elif [ "$OFFLINE_MODE" = false ] && ! has_vendor_archive "${DOTFILES_DIR}/vendor/bin/$(uname -m)/eza.tar.xz"; then
                sudo mkdir -p /etc/apt/keyrings
                if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
                    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
                    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
                    sudo apt-get update -qq || true
                    sudo apt-get install -y eza 2>/dev/null || true
                fi
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

    # Try official/extra/Artifactory pacman repo first for quickshell if available
    if ! has_cmd quickshell; then
        sudo pacman -S --noconfirm --needed quickshell 2>/dev/null || true
    fi

    local aur_cmd=""
    if has_cmd yay; then
        aur_cmd="yay"
    elif has_cmd paru; then
        aur_cmd="paru"
    elif [ "$OFFLINE_MODE" = false ]; then
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
    elif [ "$OFFLINE_MODE" = false ]; then
        log_warn "No AUR helper available. Please install 'quickshell-git' and 'ghostty' manually from the Arch User Repository."
        record_failure "AUR helper" "yay-bin" "bootstrap failed"
    fi

    if ! has_cmd quickshell; then
        record_failure "AUR" "quickshell" "installation failed"
    fi
}

# ------------------------------------------------------------------------------
# 6. Modern CLI Utilities (Local Vendor First, Online Fallback)
# ------------------------------------------------------------------------------
install_modern_tools() {
    local ARCH
    ARCH="$(uname -m)"
    local VENDOR_BIN="${DOTFILES_DIR}/vendor/bin/${ARCH}"

    # eza (vendor first, then upstream fallback)
    if ! has_cmd eza && [ ! -f "$HOME/.local/bin/eza" ]; then
        if has_vendor_archive "${VENDOR_BIN}/eza.tar.xz"; then
            log_info "Installing eza from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/eza.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/eza" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ] && [ "$ARCH" = "x86_64" ]; then
            log_info "Installing eza standalone binary..."
            curl -fsSL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -o /tmp/eza.tar.gz 2>/dev/null || true
            if [ -f /tmp/eza.tar.gz ]; then
                tar -xzf /tmp/eza.tar.gz -C "$HOME/.local/bin" 2>/dev/null || true
                chmod +x "$HOME/.local/bin/eza" 2>/dev/null || true
                rm -f /tmp/eza.tar.gz
            fi
        fi
    fi
    if ! has_cmd eza && [ ! -f "$HOME/.local/bin/eza" ]; then
        record_failure "CLI tool" "eza"
    fi

    # zoxide (vendor first, then upstream fallback)
    if ! has_cmd zoxide && [ ! -f "$HOME/.local/bin/zoxide" ]; then
        if has_vendor_archive "${VENDOR_BIN}/zoxide.tar.xz"; then
            log_info "Installing zoxide from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/zoxide.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/zoxide" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
            log_info "Installing zoxide..."
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null || true
        fi
    fi
    if ! has_cmd zoxide && [ ! -f "$HOME/.local/bin/zoxide" ]; then
        record_failure "CLI tool" "zoxide"
    fi

    # Zellij (vendor first, then upstream fallback)
    if ! has_cmd zellij && [ ! -f "$HOME/.local/bin/zellij" ]; then
        if has_vendor_archive "${VENDOR_BIN}/zellij.tar.xz"; then
            log_info "Installing zellij from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/zellij.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/zellij" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
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
    fi
    if ! has_cmd zellij && [ ! -f "$HOME/.local/bin/zellij" ]; then
        record_failure "CLI tool" "zellij"
    fi

    # Lazygit (vendor first, then upstream fallback)
    if ! has_cmd lazygit && [ ! -f "$HOME/.local/bin/lazygit" ]; then
        if has_vendor_archive "${VENDOR_BIN}/lazygit.tar.xz"; then
            log_info "Installing lazygit from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/lazygit.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/lazygit" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
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
    fi
    if ! has_cmd lazygit && [ ! -f "$HOME/.local/bin/lazygit" ]; then
        record_failure "CLI tool" "lazygit"
    fi

    # Neovim (Ensure version >= 0.10; vendor first, then upstream fallback)
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

    if [ "$NEED_NVIM" -eq 1 ]; then
        if has_vendor_archive "${VENDOR_BIN}/nvim-linux-x86_64.tar.xz"; then
            log_info "Installing Neovim from local repo..."
            if has_cmd sudo; then
                sudo rm -rf /opt/nvim-linux-x86_64 2>/dev/null || true
                extract_vendor_archive "${VENDOR_BIN}/nvim-linux-x86_64.tar.xz" "/opt" "sudo" && \
                    ln -sf /opt/nvim-linux-x86_64/bin/nvim "$HOME/.local/bin/nvim" 2>/dev/null || true
            else
                rm -rf "$HOME/.local/opt/nvim-linux-x86_64" 2>/dev/null || true
                extract_vendor_archive "${VENDOR_BIN}/nvim-linux-x86_64.tar.xz" "$HOME/.local/opt" && \
                    ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim" 2>/dev/null || true
            fi
        elif [ "$OFFLINE_MODE" = false ] && [ "$ARCH" = "x86_64" ]; then
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
    fi
    if ! has_cmd nvim; then
        record_failure "Editor" "neovim"
    fi

    # Pipx tools (IPython - uses configured PyPI / Artifactory if available)
    if has_cmd pipx; then
        pipx ensurepath >/dev/null 2>&1 || true
        if ! has_cmd ipython; then
            log_info "Installing ipython via pipx..."
            pipx install ipython >/dev/null 2>&1 || record_failure "Python tool" "ipython"
        fi
    else
        record_failure "Python tool" "ipython" "pipx not available"
    fi

    # Rust & Cargo (use distro cargo/rustc if installed; rustup only when online)
    if ! has_cmd rustup && [ "$OFFLINE_MODE" = false ]; then
        log_info "Installing Rust toolchain (rustup)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>/dev/null || true
    fi
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.cargo/env"
    fi
    if ! has_cmd rustup && ! has_cmd cargo; then
        record_failure "Toolchain" "rustup/cargo"
    fi
}

# ------------------------------------------------------------------------------
# 7. Antigravity CLI, Astral uv, and Developer Tools (Local Vendor First)
# ------------------------------------------------------------------------------
install_developer_tools() {
    log_info "Configuring Antigravity CLI, Astral uv, and developer tools..."
    local ARCH
    ARCH="$(uname -m)"
    local VENDOR_BIN="${DOTFILES_DIR}/vendor/bin/${ARCH}"

    # Antigravity CLI (agy)
    if ! has_cmd agy && [ ! -f "$HOME/.local/bin/agy" ]; then
        if has_vendor_archive "${VENDOR_BIN}/agy.tar.xz"; then
            log_info "Installing Antigravity CLI (agy) from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/agy.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/agy" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
            log_info "Installing Antigravity CLI (agy)..."
            curl -fsSL https://antigravity.google/cli/install.sh | bash 2>/dev/null || \
                curl -fsSL https://antigravity.dev/install.sh | bash 2>/dev/null || true
        fi
        if ! has_cmd agy && [ ! -f "$HOME/.local/bin/agy" ]; then
            log_warn "Could not install Antigravity CLI automatically."
            record_failure "Developer tool" "Antigravity CLI (agy)"
        fi
    else
        log_info "Antigravity CLI (agy) is already installed."
    fi

    # Astral uv (fast Python package and project manager)
    if ! has_cmd uv && [ ! -f "$HOME/.local/bin/uv" ]; then
        if has_vendor_archive "${VENDOR_BIN}/uv.tar.xz"; then
            log_info "Installing Astral uv from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/uv.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
            log_info "Installing Astral uv (fast Python package manager)..."
            curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || true
        fi
    else
        log_info "uv is already installed."
    fi
    if ! has_cmd uv && [ ! -f "$HOME/.local/bin/uv" ]; then
        record_failure "Python tool" "uv"
    fi

    # Cloudflare Tunnel daemon (cloudflared)
    if ! has_cmd cloudflared && [ ! -f "$HOME/.local/bin/cloudflared" ]; then
        if has_vendor_archive "${VENDOR_BIN}/cloudflared.tar.xz"; then
            log_info "Installing cloudflared from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/cloudflared.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/cloudflared" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
            log_info "Installing cloudflared tunnel daemon..."
            local CF_ARCH="amd64"
            [ "$ARCH" = "aarch64" ] && CF_ARCH="arm64"
            if curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o "/tmp/cloudflared" 2>/dev/null; then
                install -m 755 /tmp/cloudflared "$HOME/.local/bin/cloudflared" 2>/dev/null || true
                rm -f /tmp/cloudflared
            else
                rm -f /tmp/cloudflared
                log_warn "Could not download cloudflared."
            fi
        fi
    fi
    if ! has_cmd cloudflared && [ ! -f "$HOME/.local/bin/cloudflared" ]; then
        record_failure "CLI tool" "cloudflared"
    fi

    # Rclone (cloud storage synchronization)
    if ! has_cmd rclone && [ ! -f "$HOME/.local/bin/rclone" ]; then
        if has_vendor_archive "${VENDOR_BIN}/rclone.tar.xz"; then
            log_info "Installing rclone from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/rclone.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/rclone" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ]; then
            log_info "Installing rclone..."
            curl -fsSL https://rclone.org/install.sh | sudo bash 2>/dev/null || true
        fi
    fi
    if ! has_cmd rclone && [ ! -f "$HOME/.local/bin/rclone" ]; then
        record_failure "CLI tool" "rclone"
    fi

    # Podman Docker compatibility symlink
    if ! has_cmd docker && has_cmd podman; then
        log_info "Configuring docker -> podman symlink..."
        ln -sf "$(command -v podman)" "$HOME/.local/bin/docker" 2>/dev/null || true
    fi

    # Fastfetch (vendor first, then upstream fallback)
    if ! has_cmd fastfetch && [ ! -f "$HOME/.local/bin/fastfetch" ]; then
        if has_vendor_archive "${VENDOR_BIN}/fastfetch.tar.xz"; then
            log_info "Installing fastfetch from local repo..."
            extract_vendor_archive "${VENDOR_BIN}/fastfetch.tar.xz" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/fastfetch" 2>/dev/null || true
        elif [ "$OFFLINE_MODE" = false ] && [ "$ARCH" = "x86_64" ]; then
            log_info "Installing fastfetch standalone binary..."
            curl -fsSL https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz -o /tmp/fastfetch.tar.gz 2>/dev/null || true
            if [ -f /tmp/fastfetch.tar.gz ]; then
                tar -xzf /tmp/fastfetch.tar.gz -C /tmp 2>/dev/null || true
                install -m 755 /tmp/fastfetch-linux-amd64/usr/bin/fastfetch "$HOME/.local/bin/fastfetch" 2>/dev/null || true
                rm -rf /tmp/fastfetch* 2>/dev/null || true
            fi
        fi
    fi
    if ! has_cmd fastfetch && [ ! -f "$HOME/.local/bin/fastfetch" ]; then
        record_failure "CLI tool" "fastfetch"
    fi

    # SpotDL (uses configured PyPI / Artifactory if available)
    if ! has_cmd spotdl && [ ! -f "$HOME/.local/bin/spotdl" ]; then
        if has_cmd uv; then
            log_info "Installing spotdl via uv tool..."
            uv tool install spotdl 2>/dev/null || true
        elif has_cmd pipx; then
            log_info "Installing spotdl via pipx..."
            pipx install spotdl 2>/dev/null || true
        fi
        if ! has_cmd spotdl && [ ! -f "$HOME/.local/bin/spotdl" ]; then
            record_failure "Python tool" "spotdl"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 8. Ghostty Terminal Emulator
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
            if [ "$OFFLINE_MODE" = false ] && ! dnf list --available ghostty >/dev/null 2>&1; then
                sudo dnf copr enable -y scottames/ghostty 2>/dev/null || true
            fi
            sudo dnf install -y ghostty 2>/dev/null || true
        fi
    elif has_cmd apt-get; then
        if has_cmd sudo; then
            if ! apt-cache show ghostty >/dev/null 2>&1 && [ "$OFFLINE_MODE" = false ]; then
                sudo install -d -m 0755 /etc/apt/keyrings 2>/dev/null || true
                curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg 2>/dev/null || true
                echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list > /dev/null 2>&1 || true
                sudo apt-get update -qq 2>/dev/null || true
            fi
            sudo apt-get install -y ghostty 2>/dev/null || true
        fi
    fi

    if [ "$OFFLINE_MODE" = false ] && ! has_cmd ghostty && [ ! -f "$HOME/.local/bin/ghostty" ] && has_cmd snap; then
        sudo snap install ghostty --classic 2>/dev/null || true
    fi

    if has_cmd ghostty || [ -f "$HOME/.local/bin/ghostty" ]; then
        log_success "Ghostty installed successfully."
    else
        log_warn "Ghostty could not be installed automatically for this distro."
        record_failure "Terminal" "ghostty"
    fi
}

# ------------------------------------------------------------------------------
# 9. Flatpak Desktop Applications (Vesktop, Zen, ZapZap, Spotify, etc.)
# ------------------------------------------------------------------------------
install_flatpaks() {
    log_info "Configuring Flatpak and core desktop applications..."

    if ! has_cmd flatpak; then
        log_warn "Flatpak is not installed. Skipping flatpak app installations."
        record_failure "Flatpak" "All Flatpak apps" "flatpak command not installed"
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
            if ! flatpak install -y --noninteractive flathub "$app" 2>/dev/null && \
               ! flatpak install --user -y --noninteractive flathub "$app" 2>/dev/null; then
                log_warn "Could not install $app."
                record_failure "Flatpak" "$app"
            fi
        else
            log_info "Flatpak $app is already installed."
        fi
    done

    # Ensure application configuration directories exist and deploy configs
    local VESKTOP_DIR="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop"
    mkdir -p "$VESKTOP_DIR/themes" "$VESKTOP_DIR/settings" "$HOME/.config/vesktop"
    if [ -f "${DOTFILES_DIR}/config/vesktop/settings.json" ]; then
        [ ! -f "$VESKTOP_DIR/settings.json" ] && { cp "${DOTFILES_DIR}/config/vesktop/settings.json" "$VESKTOP_DIR/settings.json" 2>/dev/null || true; }
    fi
    if [ -f "${DOTFILES_DIR}/config/vesktop/settings/settings.json" ]; then
        [ ! -f "$VESKTOP_DIR/settings/settings.json" ] && { cp "${DOTFILES_DIR}/config/vesktop/settings/settings.json" "$VESKTOP_DIR/settings/settings.json" 2>/dev/null || true; }
    fi
    if [ -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" ]; then
        cp -f "${DOTFILES_DIR}/config/vesktop/themes/nothing.theme.css" "$VESKTOP_DIR/themes/nothing.theme.css" 2>/dev/null || true
    fi

    # ZapZap Config
    local ZAPZAP_DIR="$HOME/.var/app/com.rtosta.zapzap/config/ZapZap"
    mkdir -p "$ZAPZAP_DIR" "$HOME/.config/ZapZap"
    if [ -f "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" ]; then
        [ ! -f "$ZAPZAP_DIR/ZapZap.conf" ] && { cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$ZAPZAP_DIR/ZapZap.conf" 2>/dev/null || true; }
        [ ! -f "$HOME/.config/ZapZap/ZapZap.conf" ] && { cp "${DOTFILES_DIR}/config/zapzap/ZapZap.conf" "$HOME/.config/ZapZap/ZapZap.conf" 2>/dev/null || true; }
    fi
}

# ------------------------------------------------------------------------------
# 10. Set Default Shell to Zsh
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
# 11. Nought (Nothing OS) Rice & Theme Integration
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

    # Nothing Icon Theme (build dynamically if numpy/PIL exist, else restore vendored icons)
    mkdir -p "${DATA}/icons/Nothing"
    link_file "${DOTFILES_DIR}/config/theme/icons/Nothing/index.theme" "${DATA}/icons/Nothing/index.theme"
    if [ -f "${DOTFILES_DIR}/config/scripts/build-nothing-icons.py" ] && python3 -c "import numpy, PIL" 2>/dev/null; then
        log_info "Building Nothing icon theme..."
        python3 "${DOTFILES_DIR}/config/scripts/build-nothing-icons.py" "${DATA}/icons/Nothing" 2>/dev/null || true
    fi
    if [ ! -d "${DATA}/icons/Nothing/scalable" ] && has_vendor_archive "${DOTFILES_DIR}/vendor/icons/Nothing.tar.xz"; then
        log_info "Restoring prebuilt Nothing icon theme from local repo..."
        extract_vendor_archive "${DOTFILES_DIR}/vendor/icons/Nothing.tar.xz" "${DATA}/icons" || true
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
    chmod +x "${DOTFILES_DIR}/config/scripts/"*.sh 2>/dev/null || true
    link_file "${DOTFILES_DIR}/config/hypr" "${CONF}/hypr"
    mkdir -p "${CONF}/quickshell"
    link_file "${DOTFILES_DIR}/config/quickshell/nothing" "${CONF}/quickshell/nothing"
    link_file "${DOTFILES_DIR}/config/scripts" "${CONF}/scripts"
    link_file "${DOTFILES_DIR}/config/theme" "${CONF}/theme"
    link_file "${DOTFILES_DIR}/config/fastfetch" "${CONF}/fastfetch"
    link_file "${DOTFILES_DIR}/config/starship.toml" "${CONF}/starship.toml"
    mkdir -p "${CONF}/fish/conf.d"
    link_file "${DOTFILES_DIR}/config/fish/conf.d/nothing.fish" "${CONF}/fish/conf.d/nothing.fish"

    # Applications and Icons (Nothing X, Vesktop, Discord)
    mkdir -p "${DATA}/applications" "${DATA}/icons/hicolor/scalable/apps" "${DATA}/kio/servicemenus"
    link_file "${DOTFILES_DIR}/applications/nothing-x.desktop" "${DATA}/applications/nothing-x.desktop"
    for icon_svg in "${DOTFILES_DIR}/icons/hicolor/scalable/apps"/*.svg; do
        [ -e "$icon_svg" ] || continue
        link_file "$icon_svg" "${DATA}/icons/hicolor/scalable/apps/$(basename "$icon_svg")"
    done
    link_file "${DOTFILES_DIR}/applications/servicemenus/nothing-set-wallpaper.desktop" "${DATA}/kio/servicemenus/nothing-set-wallpaper.desktop"
    has_cmd gtk-update-icon-cache && { gtk-update-icon-cache -f "${DATA}/icons/Nothing" 2>/dev/null || true; gtk-update-icon-cache -f "${DATA}/icons/hicolor" 2>/dev/null || true; }

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
  - Installs developer tools (Antigravity CLI, Astral uv, Podman/Docker, cloudflared, rclone, spotdl)
  - Installs Flatpak desktop apps (Vesktop, Zen Browser, ZapZap, Spotify, etc.)
  - Deploys Nought (Nothing OS) Hyprland desktop rice & theme
  - Sets default shell to Zsh

Options:
  -h, --help            Show this help message
  -u, --ubuntu          Run Ubuntu-specific script (install-ubuntu.sh)
      --core-only       Install CLI tools and configs only (skip desktop rice and flatpaks)
      --apps            Ensure optional Flatpak desktop apps stage runs
      --apps-only       Run only the optional Flatpak desktop apps stage (Zen, Vesktop, ZapZap, etc.)
      --no-apps         Skip optional Flatpak desktop application installations
      --no-flatpak      Alias for --no-apps
      --offline, --local  Install strictly from apt/dnf/pacman (e.g. Artifactory) + local vendor/ (no external URLs/PPAs/Coprs/Flatpak)
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
    local APPS_FLAG=""

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
                APPS_FLAG="--no-apps"
                shift
                ;;
            --apps|--with-apps|--flatpak)
                RUN_FLATPAK=true
                APPS_FLAG="--apps"
                shift
                ;;
            --apps-only)
                RUN_CORE=false
                RUN_NOUGHT=false
                RUN_FLATPAK=true
                APPS_FLAG="--apps-only"
                shift
                ;;
            --no-apps|--no-flatpak)
                RUN_FLATPAK=false
                APPS_FLAG="--no-apps"
                shift
                ;;
            --offline|--local)
                OFFLINE_MODE=true
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
            local ubuntu_args=()
            [ "$OFFLINE_MODE" = true ] && ubuntu_args+=("--offline")
            [ -n "$APPS_FLAG" ] && ubuntu_args+=("$APPS_FLAG")
            bash "${DOTFILES_DIR}/install-ubuntu.sh" "${ubuntu_args[@]}"
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

        # Step 7: Install Developer & System Tools (Antigravity CLI, Astral uv, Podman/Docker, cloudflared, rclone, spotdl)
        install_developer_tools

        # Step 8: Install Ghostty terminal emulator
        install_ghostty

        # Step 9: Switch shell to Zsh
        set_default_shell
    fi

    if [ "$RUN_FLATPAK" = true ]; then
        # Step 10: Install Flatpak apps & configurations (Vesktop, Zen, ZapZap, Spotify, etc.)
        install_flatpaks
    fi

    if [ "$RUN_NOUGHT" = true ]; then
        # Step 11: Deploy Nought (Nothing OS) desktop rice, icons, and themes
        deploy_nought
    fi

    printf "\n%b========================================%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%bSetup completed!%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "%b========================================%b\n\n" "${GREEN}${BOLD}" "${NC}"
    print_summary
    printf "\nMesloLGS NF fonts location: %b~/.local/share/fonts%b.\n" "${BOLD}" "${NC}"
    printf "To start using your new environment right now, run:\n"
    printf "  %bexec zsh%b\n\n" "${BOLD}" "${NC}"
}

main "$@"
