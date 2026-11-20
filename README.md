# Dotfiles & Development Environment

Automated configuration and dotfiles to reproduce my exact terminal setup and desktop environment on any fresh machine.

### 🐧 Supported Distributions
* **Fedora / RHEL / CentOS Stream** (`dnf`)
* **Ubuntu / Debian / WSL / Pop!_OS** (`apt`)
* **Arch Linux / Manjaro** (`pacman`)

---

## ⚡ Quick Start

### Core Installation:

```bash
git clone https://github.com/master3716/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

Once installed, restart your shell or run:
```bash
exec zsh
```

### Full Installation with Nought (Nothing OS Rice):

```bash
cd ~/.dotfiles
./install.sh --all
```

### Installer Options:

| Command | Action |
|---|---|
| `./install.sh` | Installs core dotfiles, shell ecosystem, fonts, modern CLI tools & Ghostty |
| `./install.sh --nought` (or `-n`) | Deploys Nought (Nothing OS) desktop rice, themes, icons & configs |
| `./install.sh --all` (or `-a`) | Full installation (Core environment + Nought rice) |
| `./install.sh --revert-nought` | Safely reverts Nought themes and restores previous system configuration |
| `./revert-nought.sh` | Standalone one-click reverter script for Nought |
| `./install.sh --help` | Displays command line usage and flags |

---

## 🧰 What's Included

### 1. Shell & Prompts
* **Zsh** as the default shell with **[Oh My Zsh](https://ohmyz.sh/)**
* **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** fast theme (`.p10k.zsh` pre-configured)
* **Zsh Plugins**:
  * `zsh-autosuggestions` - Fish-like autosuggestions based on history
  * `zsh-syntax-highlighting` - Fast syntax highlighting for commands
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

### 2. Modern CLI Tools & System Fetch
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
* **[zellij](https://zellij.dev/)**: Fast, customizable terminal multiplexer (`zj` alias)
* **[ghostty](https://ghostty.org/)**: Fast, feature-rich, GPU-accelerated terminal emulator (Tokyo Night theme, non-transparent)

### 3. Desktop Environments & System Integrations
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

### 4. Editor (Neovim + LazyVim)
* **[Neovim](https://neovim.io/)** with **[LazyVim](https://www.lazyvim.org/)** starter
* Language Support & LSP:
  * **Python**: Pyright & Ruff debounced LSP integration
  * **Rust**: `rust-analyzer` with cargo features and clippy check-on-save
* Custom Plugins & Keymaps:
  * `snacks.nvim` + `toggleterm.nvim`: Floating terminal mapped to `<Ctrl-t>`
  * `snacks.nvim` file picker/explorer: Press `n` to create files or folders, press `<Ctrl-t>` to spawn a terminal inside the selected directory

### 5. Compilers & Toolchains
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
│   └── steam                   # Steam bwrap SSL certificate compatibility wrapper
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
    │   └── config             # Ghostty Tokyo Night modern configuration
    ├── gnome/                 # GNOME Dash to panel, Mutter, and keybinding dconfs
    ├── gtk-3.0/               # GTK 3 Nothing matte black + red theme
    ├── gtk-4.0/               # GTK 4 Nothing matte black + red theme
    ├── hypr/                  # Hyprland Lua configuration & keybinds
    ├── kitty/                 # Kitty terminal Nothing theme
    ├── nvim/                  # Neovim (LazyVim) configuration
    │   ├── init.lua
    │   ├── lazyvim.json
    │   ├── .neoconf.json
    │   ├── stylua.toml
    │   └── lua/
    │       ├── config/        # Autocmds, keymaps, lazy setup, options
    │       └── plugins/       # Custom language LSPs, explorer, and toggleterm
    ├── ptyxis/                # Ptyxis Tokyo Night palette
    ├── quickshell/            # Quickshell Nothing OS desktop & widget UI
    ├── scripts/               # Desktop helper scripts (lock, screenshot, etc.)
    ├── starship.toml          # Starship Nothing prompt configuration
    ├── steam/                 # Custom Steam desktop entry
    ├── theme/                 # GTK, KDE, Icon, Spicetify, Vesktop & Zen themes
    └── zellij/
        └── config.kdl         # Zellij custom layout & keybind configuration
```

---

## 🎨 Font Support (MesloLGS NF & Inter Variable)

* **Terminal Fonts**: `install.sh` downloads and installs all 4 official **MesloLGS NF** font variants (Regular, Bold, Italic, Bold Italic) into `~/.local/share/fonts` for Powerlevel10k and icon glyphs.
  * In your terminal emulator (Ghostty, Ptyxis, etc.), select **MesloLGS NF** or **JetBrains Mono**.
* **System UI Fonts**: The Nothing OS theme configures **Inter Variable** for crisp UI rendering across GTK and Qt/KDE.
