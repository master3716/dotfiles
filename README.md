# Dotfiles & Development Environment

Automated configuration and dotfiles to reproduce my exact terminal setup and desktop environment on any fresh machine.

### 🐧 Supported Distributions
* **Arch Linux / Manjaro** (`pacman` + `yay`/`paru` for AUR)
* **Fedora / RHEL / CentOS Stream** (`dnf` + Copr)
* **Ubuntu (24.04 LTS, 24.10+) / Debian / Pop!_OS** (`apt` + `ppa:cppiber/hyprland`)

---

## ⚡ Quick Start (One-Command Setup)

To set up a fresh machine with everything (Shell, Neovim, Ghostty, Hyprland desktop rice, Flatpaks, themes, and apps):

```bash
git clone -b nought https://github.com/master3716/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Or run directly via `curl`:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/master3716/dotfiles/nought/install.sh)"
```

Once installed, restart your shell or run:
```bash
exec zsh
```

### Installer Options:

| Command | Action |
|---|---|
| `./install.sh` | **Full One-Command Setup**: Deploys dotfiles, installs system & AUR packages, fonts, Ghostty, Flatpaks (Vesktop, Zen, ZapZap, Spotify), and Nought (Nothing OS) desktop rice |
| `./install.sh --offline` (or `--local`) | **Offline / Artifactory Mode**: Installs system packages solely from configured `apt`/`dnf`/`pacman` mirrors (e.g., Artifactory) and extracts all non-distro tools, Zsh plugins, fonts, icons, and LazyVim plugins directly from `vendor/` without external internet calls |
| `./install.sh --core-only` | Installs CLI dotfiles, Zsh ecosystem, fonts, and terminal tools only (skips desktop rice and flatpaks) |
| `./install.sh --no-flatpak` | Installs everything except Flatpak applications |
| `./install.sh --ubuntu` (or `-u`) | Runs Ubuntu-specific script (`install-ubuntu.sh`) |
| `./install.sh --revert-nought` | Safely reverts Nought themes and restores previous system configuration |
| `./revert-nought.sh` | Standalone one-click reverter script for Nought |
| `./install.sh --help` | Displays command line usage and flags |

---

## 📦 Dependencies & What Gets Installed

Even though `./install.sh` automatically checks, resolves, and downloads all dependencies for you, this section details everything required by and downloaded onto your system.

### 1. Minimal Prerequisites (Before Running)
Before running `./install.sh`, the host machine only needs:
* **Operating System**: Fresh or existing installation of Arch Linux, Fedora (40+), or Ubuntu (24.04+ / Debian-based).
* **Base Packages**: `bash`, `curl` (or `wget`), and `git`.
* **User Privileges**: A user account with `sudo` permissions (for distro package management).
* **Display Server**: Wayland-capable GPU drivers (for the Hyprland & Quickshell desktop environment).

---

### 2. System Packages by Distribution (Installed via Package Manager)

The installer detects your distribution and installs the following package sets:

| Category | Arch Linux (`pacman` / AUR) | Fedora (`dnf` + Copr) | Ubuntu / Debian (`apt` + PPA) |
|---|---|---|---|
| **Shell & Core Tools** | `zsh`, `git`, `curl`, `wget`, `unzip`, `tar`, `tree`, `jq`, `tmux`, `cmake`, `direnv`, `shellcheck` | `zsh`, `git`, `curl`, `wget`, `unzip`, `tar`, `tree`, `jq`, `tmux`, `cmake`, `direnv`, `shellcheck`, `util-linux-user` | `zsh`, `git`, `curl`, `wget`, `unzip`, `tar`, `tree`, `jq`, `tmux`, `cmake`, `direnv`, `shellcheck` |
| **Build Essentials** | `base-devel`, `gcc`, `cmake`, `fontconfig` | `gcc`, `gcc-c++`, `make`, `cmake`, `fontconfig` | `build-essential`, `gcc`, `g++`, `make`, `cmake`, `fontconfig` |
| **Python Ecosystem** | `python`, `python-pip`, `python-pipx`, `python-pillow`, `python-numpy`, `uv` | `python3`, `python3-pip`, `python3-pillow`, `python3-numpy`, `pipx`, `uv` | `python3`, `python3-pip`, `python3-venv`, `python3-pil`, `python3-numpy`, `pipx` |
| **CLI & System Monitors** | `ripgrep`, `fd`, `bat`, `fzf`, `eza`, `zoxide`, `zellij`, `lazygit`, `fastfetch`, `starship`, `neovim`, `htop`, `btop` | `ripgrep`, `fd-find`, `bat`, `fzf`, `eza`, `fastfetch`, `htop`, `btop` | `ripgrep`, `fd-find`, `bat`, `fzf`, `htop`, `btop` |
| **Containers & Mesh VPN** | `podman`, `podman-compose`, `rclone`, `tailscale` | `podman`, `podman-compose`, `rclone`, `tailscale` | `podman`, `podman-compose`, `rclone` |
| **Hyprland & Wayland** | `hyprland`, `hypridle`, `hyprlock`, `hyprpicker`, `hyprsunset`, `quickshell`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` | `hyprland`, `hypridle`, `hyprlock`, `quickshell`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk` | `hyprland`, `hypridle`, `hyprlock`, `quickshell`, `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `wayland-protocols`, `libwayland-dev` *(via `install-ubuntu.sh`)* |
| **Audio & Media** | `pipewire`, `wireplumber`, `pipewire-pulse`, `pipewire-alsa`, `pipewire-jack`, `pavucontrol`, `playerctl`, `ffmpeg`, `mpv` | `pipewire`, `wireplumber`, `pavucontrol`, `playerctl`, `ffmpeg`, `mpv` | `pipewire`, `pipewire-pulse`, `wireplumber`, `libspa-0.2-bluetooth`, `pavucontrol`, `playerctl`, `ffmpeg`, `mpv` |
| **Desktop Utilities** | `brightnessctl`, `wl-clipboard`, `cliphist`, `grim`, `slurp`, `swappy`, `wf-recorder`, `zenity`, `dconf`, `chafa`, `nautilus`, `polkit-kde-agent` | `brightnessctl`, `wl-clipboard`, `cliphist`, `grim`, `slurp`, `swappy`, `wf-recorder`, `zenity`, `dconf`, `chafa`, `nautilus` | `brightnessctl`, `wl-clipboard`, `cliphist`, `grim`, `slurp`, `swappy`, `wf-recorder`, `zenity`, `dconf`, `chafa`, `nautilus`, `udisks2` |
| **System Fonts** | `noto-fonts`, `noto-fonts-emoji`, `noto-fonts-cjk`, `ttf-font-awesome`, `ttf-inter` | System default + MesloLGS NF | `fonts-font-awesome` + MesloLGS NF |
| **Application Framework** | `flatpak` | `flatpak` | `flatpak` |

*Note: On Ubuntu/Debian, `install-ubuntu.sh` also installs `software-properties-common`, `apt-transport-https`, `ca-certificates`, `gpg`, and `pkg-config`, and symlinks `batcat -> bat` and `fdfind -> fd` in `~/.local/bin`.*

---

### 3. Repositories, PPAs & Coprs Added Automatically

To ensure cutting-edge packages for Hyprland, Quickshell, and Ghostty, the installer configures:
* **Arch Linux**:
  * Bootstraps `yay-bin` from the Arch User Repository (AUR) if no AUR helper is detected.
  * Installs `quickshell-git` / `quickshell` and `ghostty` from AUR.
* **Fedora**:
  * Copr: `ashbuk/Hyprland-Fedora` (Hyprland Wayland compositor builds)
  * Copr: `errornointernet/quickshell` (Quickshell QML shell runtime)
  * Copr: `scottames/ghostty` (Ghostty GPU terminal emulator)
* **Ubuntu / Debian**:
  * PPA: `ppa:cppiber/hyprland` (modern Hyprland packages)
  * PPA: `ppa:avengemedia/danklinux` (Quickshell desktop runtime)
  * Keyring/Repo: `deb.gierens.de` (`eza` modern `ls` replacement)
  * Keyring/Repo: `deb.griffo.io` (Ghostty terminal emulator)

---

### 4. Standalone Binaries, Plugins & Assets (`vendor/` — Local-First)

Everything outside `apt` / `dnf` / `pacman` is **hosted directly inside `vendor/`** so setups work cleanly in Artifactory or restricted-internet environments (online URLs are only used as a fallback when an architecture isn't vendored and `--offline` is not set):

* **[Antigravity CLI](https://antigravity.google)** (`agy`): Vendored in `vendor/bin/x86_64/agy.tar.xz.part-*`
* **[Astral uv](https://docs.astral.sh/uv/)** (`uv`, `uvx`): Vendored in `vendor/bin/x86_64/uv.tar.xz`
* **[Cloudflare Tunnel](https://github.com/cloudflare/cloudflared)** (`cloudflared`): Vendored in `vendor/bin/x86_64/cloudflared.tar.xz`
* **[Rclone](https://rclone.org/)**: Vendored in `vendor/bin/x86_64/rclone.tar.xz`
* **[Neovim](https://neovim.io/) (v0.10+) & LazyVim Plugins**: Vendored in `vendor/bin/x86_64/nvim-linux-x86_64.tar.xz` and `vendor/nvim/lazy.tar.xz.part-*` (pre-populated into `~/.local/share/nvim/lazy`)
* **[eza](https://github.com/eza-community/eza), [zoxide](https://github.com/ajeetdsouza/zoxide), [zellij](https://zellij.dev/), [lazygit](https://github.com/jesseduffield/lazygit), [fastfetch](https://github.com/fastfetch-cli/fastfetch)**: Vendored in `vendor/bin/x86_64/`
* **Fonts (`MesloLGS NF` & `Inter`)**: Vendored in `vendor/fonts/` (`MesloLGS_NF.tar.xz`, `Inter.tar.xz`)
* **Nothing OS Icons Fallback**: Vendored in `vendor/icons/Nothing.tar.xz` (used if Python `numpy`/`pillow` aren't present to build dynamically)
* **Zsh Ecosystem (`Oh My Zsh` + `Powerlevel10k` + plugins)**: Vendored in `vendor/zsh/oh-my-zsh.tar.xz` (includes `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fzf-tab`)
* **[Rust Toolchain](https://rustup.rs/)**: Uses distro `cargo`/`rustc` if provided, or `https://sh.rustup.rs` when online
* **Python Tooling**: `ipython` (via `pipx`), `spotdl` (via `uv tool` or `pipx`, using configured PyPI / Artifactory)
* **Container Compatibility**: Automated `docker -> podman` symlink in `~/.local/bin/docker`

---

### 5. Desktop Applications (Flatpaks via Flathub)

Installed via Flatpak (`flathub` remote configured automatically; can be skipped using `--no-flatpak` or `--core-only`):

* `dev.vencord.Vesktop` (Discord client pre-configured with Vencord & Nothing Red accents)
* `app.zen_browser.zen` (Zen Browser with desktop launcher)
* `com.rtosta.zapzap` (WhatsApp client with system tray integration)
* `com.spotify.Client` (Spotify desktop)
* `com.stremio.Stremio` (Stremio media player)
* `com.discordapp.Discord` (Official Discord fallback)
* `io.github.Foldex.AdwSteamGtk` (Adwaita theme integration for Steam)
* `org.prismlauncher.PrismLauncher` (Open-source Minecraft launcher)

---

## 🧰 What's Included

### 1. Shell & Prompts
* **Zsh** as the default shell with **[Oh My Zsh](https://ohmyz.sh/)**
* **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** fast theme (`.p10k.zsh` pre-configured)
* **Directory Navigation**:
  * **[zoxide](https://github.com/ajeetdsouza/zoxide)** hooked directly into `cd` (`eval "$(zoxide init zsh --cmd cd)"`) with interactive `cdi` (`zi`) jump
  * Smart `cdpath` enabled (`cdpath=(. ~ ~/HardDrive)`) allowing quick access across drives and projects
* **Zsh Plugins**:
  * `zsh-autosuggestions` - Fish-like autosuggestions based on history
  * `zsh-syntax-highlighting` - Fast syntax highlighting for commands (valid commands highlight green, paths cyan, flags yellow, invalid tokens red)
  * `fzf-tab` - FZF-powered tab completion preview
  * `git`, `vi-mode`, `colored-man-pages`, `command-not-found`, `extract`, `history`, `sudo`
* **Vi Mode**:
  * Escape with `jj` in insert mode
  * Low key-timeout for responsive switching
* **Custom Aliases**:
  * `pipi` -> `pip install`
  * `python` -> `python3`
  * `zj` -> `zellij`
  * `cls` -> `clear`
  * `h` -> `history`, `j` -> `jobs`
  * `agy` -> `agy --dangerously-skip-permissions` (Antigravity CLI)

### 2. Applications & Desktop Stack
* **[Ghostty](https://ghostty.org/)**: Fast GPU-accelerated terminal configured with matte black (`#0b0b0b`) background, Tokyo Night accents, and crisp green syntax coloring for shell commands.
* **[Neovim](https://neovim.io/) (LazyVim)**: Full IDE experience with LSP, Treesitter, Tokyo Night palette, customized calm slate borders, and natural syntax highlighting.
* **[Vesktop](https://github.com/Vencord/Vesktop)**: Discord client pre-configured with Vencord plugins, Nothing OS Red (`#d71921`) call-disconnect accents, rounded corners, and official Discord SVG icon.
* **[Zen Browser](https://zen-browser.app/)**: Modern Firefox-based browser with automated launcher wrapper.
* **[ZapZap](https://github.com/rtosta/zapzap)**: WhatsApp desktop client with system tray integration.
* **[Hyprland](https://hyprland.org/) & [Quickshell](https://quickshell.outfoxxed.me/) (Nought Rice)**: Nothing OS desktop experience featuring dynamic widgets, dock, control center, and status bar.
* **Dual-Language Input (English + Hebrew)**:
  * Switching shortcuts: `Alt + Shift` (or `Shift + Alt`), and `Super + Shift + Space` (keeping `Super + Space` dedicated to the app launcher).
  * Interactive top bar indicator (`󰌌 EN` / `󰌌 HE`): Highlights `HE` in Nothing Red when Hebrew is active; click to switch.
### 3. Developer, Cloud & System Utilities
* **[Antigravity CLI](https://antigravity.google)** (`agy`): Powerful agentic terminal assistant (`alias agy='agy --dangerously-skip-permissions'`)
* **[Astral uv](https://docs.astral.sh/uv/)**: Extremely fast Python package and tool manager (`uv`, `uvx`)
* **[Podman](https://podman.io/) & [Podman Compose](https://github.com/containers/podman-compose)**: Daemonless container engine with automatic `docker -> podman` compatibility link
* **[Cloudflare Tunnel](https://github.com/cloudflare/cloudflared)** (`cloudflared`): Secure remote tunneling daemon
* **[Rclone](https://rclone.org/)**: Universal cloud storage synchronization tool
* **[Tailscale](https://tailscale.com/)**: Zero-config encrypted mesh VPN
* **[SpotDL](https://spotdl.rtfd.io/)**: Spotify music downloader tool
* **System Monitors & Media**: `htop`, `btop`, `fastfetch`, and `chafa` (terminal image and thumbnail viewer)

### 4. Modern CLI Tools & System Fetch
* **[dbfetch](file:///home/oferg/.dotfiles/bin/dbfetch)**: Custom Dragon Ball ASCII art system fetcher powered by Fastfetch / Neofetch
  * Features 80+ handcrafted Dragon Ball characters (`data/dragonball/ascii`)
  * Automatically displays on interactive shell startup
  * `dbfetch` (random character)
  * `dbfetch --list` (lists all available characters categorized by Universe)
  * `dbfetch <character_name>` (displays specific character)
  * `dbfetch --classic` (falls back to traditional Neofetch)
* **[eza](https://github.com/eza-community/eza)**: Modern replacement for `ls` (`ls`, `ll`, `la`, `lt`)
* **[bat](https://github.com/sharkdp/bat)**: Syntax-highlighted replacement for `cat`
* **[ripgrep](https://github.com/BurntSushi/ripgrep)**: Fast grep replacement (`grep` aliased to `rg`)
* **[fd-find](https://github.com/sharkdp/fd)**: Fast user-friendly find (`fd`)
* **[fzf](https://github.com/junegunn/fzf)**: Fuzzy finder for files, history, and tab completion
* **[zoxide](https://github.com/ajeetdsouza/zoxide)**: Smarter `cd` command tracking frequent directories
* **[direnv](https://direnv.net/)**: Automatic per-directory environment variables
* **[lazygit](https://github.com/jesseduffield/lazygit)**: Interactive terminal UI for Git
* **[zellij](https://zellij.dev/)**: Fast, customizable terminal multiplexer (`zj` alias, Tokyo Night theme)
* **[ghostty](https://ghostty.org/)**: Fast, GPU-accelerated terminal emulator (Black & Red theme, non-transparent)

### 5. Desktop Environments & System Integrations
* **Hyprland Wayland Compositor** (`config/hypr/`):
  * **Lua Configuration**: Modern Lua-based Hyprland config (`hyprland.lua`, `hyprland/*.lua`)
  * **Displays**: Dynamic multi-monitor resolution, positioning, scaling, and orientation managed via `displays.lua` (`SUPER + P`)
  * **Keybindings**: Customized hotkeys, workspace management, and floating windows (`binds.lua`)
  * **Automounting**: Automatic drive mounting on session startup (`udisksctl mount` for `HardDrive` & `SSD`)
  * **Cursor Theme**: Standardized `Adwaita` (24px) cursor across Hyprland, GTK 3/4, XWayland, GSettings, and Flatpaks
  * **Screen Sharing & Portals**: Out-of-the-box PipeWire Wayland screen sharing via `xdg-desktop-portal-hyprland` and `hyprland-share-picker`
* **GNOME Wayland Configurations** (`config/gnome/`):
  * `dash-to-panel.dconf`: Clean bottom taskbar configuration
  * `dash-to-panel-apps-toggle.patch`: Patch enabling direct app drawer open & close toggle with the `Super` key
  * `mutter.dconf`: Fractional scaling and Wayland window management settings
  * `shell-keybindings.dconf` & `wm-keybindings.dconf`: Customized desktop navigation keymaps
  * `input-sources.dconf`: Multi-language keyboard input switching
* **Ptyxis Terminal Palette** (`config/ptyxis/`):
  * `tokyo-night.palette`: Tokyo Night color palette for GNOME Ptyxis terminal
* **Steam Compatibility Wrapper** (`bin/steam`):
  * Fedora 44 OpenSSL CA certificates sandbox wrapper (`bwrap`) to prevent network TLS handshake failures (RHBZ #2387674)
  * Configured with `config/steam/steam.desktop`

### 6. Editor (Neovim + LazyVim)
* **[Neovim](https://neovim.io/)** with **[LazyVim](https://www.lazyvim.org/)** starter
* **Theme**: Official **Tokyo Night** (`folke/tokyonight.nvim`, `style = "night"`)
* Language Support & LSP:
  * **Python**: Pyright & Ruff debounced LSP integration
  * **Rust**: `rust-analyzer` with cargo features and clippy check-on-save
* Custom Plugins & Keymaps:
  * `snacks.nvim` + `toggleterm.nvim`: Floating terminal mapped to `<Ctrl-t>`
  * `snacks.nvim` file picker/explorer: Press `n` to create files or folders, press `<Ctrl-t>` to spawn a terminal inside the selected directory

### 7. Compilers & Toolchains
* **Rust**: `rustup`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`
* **Python**: Python 3, `pip`, `venv`, `pipx`, and `ipython`
* **C/C++**: `build-essential`, `gcc`, `g++`, `make`, `cmake`

---

## 🔴 Nought (Nothing OS) Desktop Rice & Theme

Integrated rice based on [Nought](https://github.com/0xbbuddha/Nought) — recreating the Nothing OS aesthetic on Linux: matte black ground (`#0b0b0b`), Nothing red accent (`#d71921`), tight radii, and dot-matrix glyphs.

### Conflict Resolution Policy
* **Theme of the OS (Nought's version picked)**:
  * **GTK 3 & GTK 4**: Matte black ground, red accent, squircle widgets ([config/gtk-3.0/](file:///home/oferg/.dotfiles/config/gtk-3.0/) & [config/gtk-4.0/](file:///home/oferg/.dotfiles/config/gtk-4.0/)).
  * **Qt / KDE**: `Nothing.colors` color scheme and `darklyrc` styling for Dolphin, Kate, etc.
  * **Icon Theme**: `Nothing` dot-matrix icon theme.
  * **GNOME Interface**: Dark preference (`prefer-dark`), `Adwaita-dark`, `Inter Variable 10` typography.
  * **Fonts**: Inter Variable for system UI, JetBrains Mono / Meslo for monospace.
  * **Compositor**: Hyprland Lua configuration with Quickshell Nothing UI.
* **Personal Development & Tooling (User's version picked)**:
  * **Shell**: User's Zsh + Oh My Zsh + Powerlevel10k + `dbfetch` remains default.
  * **Terminal**: User's Ghostty configuration remains default (Kitty available as alternative).
  * **Editor**: User's Neovim (LazyVim) configuration is untouched.
  * **Multiplexer**: User's Zellij configuration is untouched.

### Nought Shortcuts & Surface Reference

| Shortcut | Surface / Feature | Description |
|---|---|---|
| `SUPER` | **Launcher & Overview** | Top search bar with 10-workspace visual overview (`#` lists Nothing surfaces) |
| `SUPER + ALT + L` | **Nothing Launcher** | Homescreen widget library and Glyph selector preview |
| `SUPER + A` | **Essential Space** | Quick capture vault for clips, screenshots, voice notes, and audio search |
| `SUPER + ALT + A` | **Essential Apps** | Conversational UI that builds and iterates homescreen widgets on demand |
| `SUPER + SHIFT + G` | **Glyph Interface** | Cycles active surface between Matrix (489-dot disc), Bar (Phone 4a), and Strip (Phone 3a) |
| `SUPER + N` | **Control Centre** | Wi-Fi, Bluetooth, Audio, Brightness, Night Light, Caffeine, and WARP controls |
| `SUPER + B` | **Notifications** | Notification history and quick message actions |
| `SUPER + I` | **Settings** | Complete configuration center with live preview of the bar and control center |
| `SUPER + P` | **Displays** | Interactive draggable multi-monitor arrangement, resolution, refresh, and scale |
| `SUPER + G` | **Game Bar** | Pin overlay widgets directly over fullscreen games |
| `SUPER + SHIFT + S` | **Screenshot Region** | Drag rectangular region, window, or monitor capture |
| `SUPER + SHIFT + X` | **Screenshot OCR** | Screen snip with immediate OCR text extraction and inline translation |
| `SUPER + SHIFT + T` | **Wallpaper Selector** | Switch between shipped Nothing / Manga wallpapers or your own picture |
| `SUPER + V` | **Clipboard** | Clipboard history with color swatch previews for hex codes and URL detection |
| `CTRL + SHIFT + Esc` | **Processes** | Resource usage monitor with quick process kill |
| `SUPER + L` / `SUPER + Esc` | **Lock / Session** | Lock screen and system power session menu |

*Note: Custom keybinds and overrides can be placed in `~/.config/hypr/custom.lua` without conflicting with updates.*

---

## ↺ Reverting Nought (100% Revertable)

If you ever decide to revert Nought, the setup can be completely restored back to your original configuration:

### 1. System Settings & Installed Files Revert
Run the standalone revert script:
```bash
./revert-nought.sh
# Or alternatively:
./install.sh --revert-nought
```
**What this restores:**
* Reverts GNOME desktop interface settings (`gtk-theme`, `icon-theme`, `font-name`, `color-scheme`) back to your saved pre-Nought state.
* Restores backed-up GTK 3, GTK 4, and Qt/KDE settings.
* Removes generated `Nothing` icons and desktop launchers.
* Removes Nought Hyprland, Quickshell, scripts, and theme links from `~/.config`.
* Reloads your custom GNOME dconf settings (`dash-to-panel`, etc.).

### 2. Git Repository Revert
The Nought integration lives on the dedicated `nought` git branch, and your pre-Nought state is tagged at `backup-before-nought`.
To return your repository back to the pre-Nought state:
```bash
git checkout main
# (Or: git checkout backup-before-nought)
```

### 3. Keeping Nought on Main
If you want to keep Nought permanently as your primary dotfiles branch:
```bash
git checkout main && git merge nought
```

---

## 📁 Repository Structure

```
.
├── install.sh                  # Multi-distro installation script with Nought support
├── revert-nought.sh            # Safe one-click revert script for Nought rice & theme
├── README.md                   # Comprehensive documentation
├── .gitignore
├── .gitattributes
├── bin/
│   ├── dbfetch                 # Dragon Ball interactive terminal fetch (Fastfetch powered)
│   ├── neofetch                # Neofetch system info tool
│   ├── steam                   # Steam bwrap SSL certificate compatibility wrapper
│   ├── vesktop                 # Vesktop Discord Flatpak launcher wrapper
│   ├── zen / zen-browser       # Zen Browser Flatpak launcher wrapper
│   └── zap / zapzap            # ZapZap WhatsApp Flatpak launcher wrapper
├── applications/               # Desktop application entries (Nothing X, servicemenus)
├── assets/                     # Rice wallpapers, logos, and UI assets
├── icons/                      # Custom app icons and SVG vectors
├── docs/                       # Rice internals and licenses
├── data/
│   └── dragonball/             # 80+ Dragon Ball character ANSI art and metadata
├── zsh/
│   ├── .zshrc                 # Main Zsh configuration
│   ├── .zshenv                # Shell environment exports
│   └── .p10k.zsh              # Powerlevel10k theme configuration
└── config/
    ├── fastfetch/             # Fastfetch Nothing dot-matrix configuration
    ├── fish/                  # Fish shell Nothing integration
    ├── fontconfig/            # Fontconfig Inter / Ndot typography
    ├── ghostty/
    │   └── config             # Ghostty Black & Red modern configuration
    ├── gnome/                 # GNOME Dash to panel, Mutter, and keybinding dconfs
    ├── gtk-3.0/               # GTK 3 Nothing matte black + red theme
    ├── gtk-4.0/               # GTK 4 Nothing matte black + red theme
    ├── hypr/                  # Hyprland Lua configuration & keybinds (Hebrew dual-layout)
    ├── nothing/
    │   └── config.json        # Nothing OS user settings, keybind overrides, bar layout
    ├── nvim/                  # Neovim (LazyVim) configuration
    │   ├── init.lua
    │   ├── lazyvim.json
    │   ├── .neoconf.json
    │   ├── stylua.toml
    │   └── lua/
    │       ├── config/        # Autocmds, keymaps, lazy setup, options
    │       └── plugins/       # Custom theme, LSP, explorer, and toggleterm
    ├── ptyxis/                # Ptyxis Tokyo Night palette
    ├── quickshell/            # Quickshell Nothing OS desktop & widget UI
    ├── scripts/               # Desktop helper scripts (lock, screenshot, etc.)
    ├── starship.toml          # Starship Nothing prompt configuration
    ├── steam/                 # Custom Steam desktop entry
    ├── theme/                 # GTK, KDE, Icon, Spicetify, Vesktop & Zen themes
    ├── vesktop/               # Vesktop settings, Vencord config & Nothing theme
    ├── zapzap/                # ZapZap WhatsApp client configuration
    └── zellij/
        └── config.kdl         # Zellij custom layout & keybind configuration
```

---

## 🎨 Font Support (MesloLGS NF & Inter Variable)

* **Terminal Fonts**: `install.sh` downloads and installs all 4 official **MesloLGS NF** font variants (Regular, Bold, Italic, Bold Italic) into `~/.local/share/fonts` for Powerlevel10k and icon glyphs.
  * In your terminal emulator (Ghostty, Ptyxis, etc.), select **MesloLGS NF** or **JetBrains Mono**.
* **System UI Fonts**: The Nothing OS theme configures **Inter Variable** for crisp UI rendering across GTK and Qt/KDE.
