#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & System Setup
# Compatible with Ubuntu / Debian / WSL and any standard Linux bash terminal
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

# Resolve directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If executed remotely via curl/wget without the repo files present, clone first
if [ ! -f "${SCRIPT_DIR}/zsh/.zshrc" ]; then
    log_info "Dotfiles configs not found locally. Cloning repository into ~/.dotfiles..."
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

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/bin:/opt/nvim-linux-x86_64/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. System Packages (APT)
# ------------------------------------------------------------------------------
install_apt_packages() {
    if ! has_cmd apt-get; then
        log_warn "apt-get not found. Skipping apt package installation (please install packages manually if needed)."
        return 0
    fi

    log_info "Updating apt package list..."
    sudo apt-get update -y

    local pkgs=(
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
    )

    log_info "Installing core system packages..."
    sudo apt-get install -y "${pkgs[@]}"

    # Setup eza (modern replacement for ls)
    if ! has_cmd eza; then
        log_info "Configuring eza package repository..."
        sudo mkdir -p /etc/apt/keyrings
        if wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg 2>/dev/null; then
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
            sudo apt-get update -qq
            sudo apt-get install -y eza || log_warn "Could not install eza from apt repository."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 2. Modern CLI Utilities
# ------------------------------------------------------------------------------
install_modern_tools() {
    local ARCH
    ARCH="$(uname -m)"

    # Zoxide (smarter cd command)
    if ! has_cmd zoxide; then
        log_info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    # Zellij (terminal multiplexer)
    if ! has_cmd zellij && [ ! -f "$HOME/.local/bin/zellij" ]; then
        log_info "Installing Zellij..."
        if [ "$ARCH" = "x86_64" ]; then
            curl -fsSL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz -o /tmp/zellij.tar.gz
            tar -xzf /tmp/zellij.tar.gz -C "$HOME/.local/bin"
            chmod +x "$HOME/.local/bin/zellij"
            rm -f /tmp/zellij.tar.gz
        elif [ "$ARCH" = "aarch64" ]; then
            curl -fsSL https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-unknown-linux-musl.tar.gz -o /tmp/zellij.tar.gz
            tar -xzf /tmp/zellij.tar.gz -C "$HOME/.local/bin"
            chmod +x "$HOME/.local/bin/zellij"
            rm -f /tmp/zellij.tar.gz
        else
            log_warn "Unknown architecture for Zellij binary: $ARCH"
        fi
    fi

    # Lazygit
    if ! has_cmd lazygit && [ ! -f "$HOME/.local/bin/lazygit" ]; then
        log_info "Installing Lazygit..."
        local LG_ARCH="x86_64"
        [ "$ARCH" = "aarch64" ] && LG_ARCH="arm64"
        local LG_VER
        LG_VER="$(curl -sI https://github.com/jesseduffield/lazygit/releases/latest | grep -i "^location:" | sed -E 's/.*tag\/(v[0-9.]+).*/\1/' | tr -d '\r\n' || echo "")"
        if [ -z "$LG_VER" ]; then
            LG_VER="$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")"
        fi
        if [ -n "$LG_VER" ]; then
            curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LG_VER}/lazygit_${LG_VER#v}_Linux_${LG_ARCH}.tar.gz"
            tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
            install -m 755 /tmp/lazygit "$HOME/.local/bin/lazygit"
            rm -f /tmp/lazygit /tmp/lazygit.tar.gz
        fi
    fi

    # Neovim (Latest official prebuilt release required by LazyVim)
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
        curl -fsSL -o /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        if has_cmd sudo; then
            sudo rm -rf /opt/nvim-linux-x86_64
            sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
            ln -sf /opt/nvim-linux-x86_64/bin/nvim "$HOME/.local/bin/nvim" 2>/dev/null || true
        else
            mkdir -p "$HOME/.local/opt"
            rm -rf "$HOME/.local/opt/nvim-linux-x86_64"
            tar -C "$HOME/.local/opt" -xzf /tmp/nvim-linux-x86_64.tar.gz
            ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
        fi
        rm -f /tmp/nvim-linux-x86_64.tar.gz
    fi

    # Pipx tools (IPython)
    if has_cmd pipx; then
        pipx ensurepath >/dev/null 2>&1 || true
        if ! has_cmd ipython; then
            log_info "Installing ipython via pipx..."
            pipx install ipython >/dev/null 2>&1 || true
        fi
    fi

    # Rust & Cargo
    if ! has_cmd rustup; then
        log_info "Installing Rust toolchain (rustup)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
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
# 3. Zsh, Oh My Zsh, Powerlevel10k & Plugins
# ------------------------------------------------------------------------------
install_zsh_ecosystem() {
    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_info "Oh My Zsh is already installed."
    fi

    local CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Powerlevel10k theme
    if [ ! -d "${CUSTOM_DIR}/themes/powerlevel10k" ]; then
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${CUSTOM_DIR}/themes/powerlevel10k"
    fi

    # Plugins
    mkdir -p "${CUSTOM_DIR}/plugins"

    if [ ! -d "${CUSTOM_DIR}/plugins/zsh-autosuggestions" ]; then
        log_info "Installing zsh-autosuggestions plugin..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${CUSTOM_DIR}/plugins/zsh-autosuggestions"
    fi

    if [ ! -d "${CUSTOM_DIR}/plugins/zsh-syntax-highlighting" ]; then
        log_info "Installing zsh-syntax-highlighting plugin..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "${CUSTOM_DIR}/plugins/zsh-syntax-highlighting"
    fi

    if [ ! -d "${CUSTOM_DIR}/plugins/fzf-tab" ]; then
        log_info "Installing fzf-tab plugin..."
        git clone --depth=1 https://github.com/Aloxaf/fzf-tab "${CUSTOM_DIR}/plugins/fzf-tab"
    fi
}

# ------------------------------------------------------------------------------
# 4. Link Configuration Files (Safe backup & symlink)
# ------------------------------------------------------------------------------
link_file() {
    local src="$1"
    local dest="$2"

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
    log_info "Deploying configuration files..."

    # Zsh configs
    link_file "${DOTFILES_DIR}/zsh/.zshrc" "$HOME/.zshrc"
    link_file "${DOTFILES_DIR}/zsh/.zshenv" "$HOME/.zshenv"
    link_file "${DOTFILES_DIR}/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

    # Zellij config
    link_file "${DOTFILES_DIR}/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

    # Neovim (LazyVim starter + custom plugins)
    link_file "${DOTFILES_DIR}/config/nvim" "$HOME/.config/nvim"
}

# ------------------------------------------------------------------------------
# 5. Set Default Shell to Zsh
# ------------------------------------------------------------------------------
set_default_shell() {
    if ! has_cmd zsh; then
        return 0
    fi

    local ZSH_PATH
    ZSH_PATH="$(which zsh)"

    if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
        log_info "Setting default shell to ${ZSH_PATH}..."
        if chsh -s "$ZSH_PATH" 2>/dev/null; then
            log_success "Default shell changed to Zsh."
        else
            log_warn "Could not change shell automatically. You can switch manually with: chsh -s ${ZSH_PATH}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    printf "\n%b========================================%b\n" "${BOLD}" "${NC}"
    printf "%b   Installing Dotfiles & Shell Setup    %b\n" "${BOLD}" "${NC}"
    printf "%b========================================%b\n\n" "${BOLD}" "${NC}"

    install_apt_packages
    install_modern_tools
    install_zsh_ecosystem
    deploy_configs
    set_default_shell

    printf "\n%bSetup completed successfully!%b\n" "${GREEN}${BOLD}" "${NC}"
    printf "Restart your terminal or run: %bexec zsh%b\n\n" "${BOLD}" "${NC}"
}

main "$@"
