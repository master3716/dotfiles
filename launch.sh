#!/usr/bin/env bash
# ==============================================================================
# Launch Nought (Nothing OS) Nested Session
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NESTED_SCRIPT="${DOTFILES_DIR}/config/scripts/run-nested.sh"

# Check dependencies
MISSING=()
command -v Hyprland >/dev/null 2>&1 || MISSING+=("hyprland")
command -v quickshell >/dev/null 2>&1 || command -v qs >/dev/null 2>&1 || MISSING+=("quickshell")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "\033[1;31m[!] Missing required desktop components:\033[0m ${MISSING[*]}"
    echo -e "\nTo install them on Fedora, run in your terminal:"
    echo -e "  \033[1m\033[38;2;215;25;33msudo dnf copr enable -y errornointernet/quickshell\033[0m"
    echo -e "  \033[1m\033[38;2;215;25;33msudo dnf copr enable -y ashbuk/Hyprland-Fedora\033[0m"
    echo -e "  \033[1m\033[38;2;215;25;33msudo dnf install -y hyprland quickshell hypridle\033[0m\n"
    echo -e "Once installed, rerun this script to launch the nested Nothing OS session!"
    exit 1
fi

exec "$NESTED_SCRIPT" "$@"
