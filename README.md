# Dotfiles & Development Environment

Automated configuration and dotfiles to reproduce my exact terminal setup on any fresh machine.

### 🐧 Supported Distributions
* **Fedora / RHEL / CentOS Stream** (`dnf`)
* **Ubuntu / Debian / WSL / Pop!_OS** (`apt`)
* **Arch Linux / Manjaro** (`pacman`)

---

## ⚡ Quick Start

Install everything with a single command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/master3716/dotfiles/main/install.sh)"
```

### Or Clone & Run Manually:

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

---

## 🧰 What's Included

### 1. Shell & Prompts
* **Zsh** as the default shell
* **[Oh My Zsh](https://ohmyz.sh/)** framework
* **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** fast theme (`.p10k.zsh` pre-configured)
* **Zsh Plugins**:
  * `zsh-autosuggestions` - Fish-like autosuggestions based on history
  * `zsh-syntax-highlighting` - Fish-like command syntax highlighting
  * `fzf-tab` - FZF-powered tab completion
  * `git`, `vi-mode`, `colored-man-pages`, `command-not-found`, `extract`, `history`, `sudo`
* **Vi Mode**:
  * Escape with `jj` in insert mode
  * Low key-timeout for responsive switching

### 2. Modern CLI Tools
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

### 3. Editor (Neovim + LazyVim)
* **[Neovim](https://neovim.io/)** with **[LazyVim](https://www.lazyvim.org/)** starter
* Language Support & LSP:
  * **Python**: Pyright & Ruff debounced LSP integration
  * **Rust**: `rust-analyzer` with cargo features and clippy check-on-save
* Plugins:
  * `toggleterm.nvim`: Floating terminal mapped to `<Ctrl-t>`
  * Pre-configured keymaps and options

### 4. Compilers & Toolchains
* **Rust**: `rustup`, `cargo`, `rust-analyzer`, `clippy`, `rustfmt`
* **Python**: Python 3, `pip`, `venv`, `pipx`, and `ipython`
* **C/C++**: `build-essential`, `gcc`, `g++`, `make`, `cmake`

---

## 📁 Repository Structure

```
.
├── install.sh                  # Complete automated installation script
├── revert-nought.sh            # One-click revert script for Nought rice & theme
├── README.md                   # Documentation
├── .gitignore
├── .gitattributes
├── bin/
│   ├── dbfetch                 # Dragon Ball interactive terminal fetch
│   ├── neofetch                # Neofetch system info tool
│   └── steam                   # Custom steam launcher script
├── applications/               # Desktop application entries (Nothing X, etc.)
├── assets/                     # Rice wallpapers, logos, and UI assets
├── icons/                      # Custom app icons and SVG vectors
├── docs/                       # Rice internals and licenses
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
    │       └── plugins/       # Custom language LSPs & toggleterm
    ├── quickshell/            # Quickshell Nothing OS desktop & widget UI
    ├── scripts/               # Desktop helper scripts (lock, screenshot, etc.)
    ├── starship.toml          # Starship Nothing prompt configuration
    ├── theme/                 # GTK, KDE, Icon, Spicetify, Vesktop & Zen themes
    └── zellij/
        └── config.kdl         # Zellij custom layout & keybind configuration
```

---

## 🔴 Nought (Nothing OS) Desktop Rice & Theme

Integrated rice based on [Nought](https://github.com/0xbbuddha/Nought) — recreating the Nothing OS aesthetic on Linux: matte black ground (`#0b0b0b`), Nothing red accent (`#d71921`), tight radii, and dot-matrix glyphs.

### Conflict Resolution Policy
* **Theme of the OS**: Sticks with Nought's design language across the whole system:
  * **GTK 3 & GTK 4**: Matte black ground, red accent, squircle widgets.
  * **Qt / KDE**: `Nothing.colors` color scheme and `darklyrc` styling for Dolphin, Kate, etc.
  * **Icon Theme**: `Nothing` dot-matrix icon theme.
  * **GNOME Interface**: Dark preference (`prefer-dark`), `Adwaita-dark`, `Inter Variable 10` typography.
  * **Fonts**: Inter Variable for system UI, JetBrains Mono / Meslo for monospace.
* **Personal Development & Tooling**: Preserves user's preferred configs over repository defaults:
  * **Shell**: User's Zsh + Oh My Zsh + Powerlevel10k + `dbfetch` remains default.
  * **Terminal**: User's Ghostty configuration remains default.
  * **Editor**: User's Neovim (LazyVim) configuration is untouched.
  * **Multiplexer**: User's Zellij configuration is untouched.

### Deploying Nought
To deploy the Nothing OS desktop rice, themes, and configuration files:
```bash
./install.sh --nought
```
Or to run full setup and deploy Nought simultaneously:
```bash
./install.sh --all
```

### ↺ Reverting Nought (100% Revertable)
If you decide you do not want Nought, everything can be cleanly and safely reverted:

1. **Reverting system settings and installed configs**:
   Run the dedicated revert script at any time:
   ```bash
   ./revert-nought.sh
   # Or alternatively:
   ./install.sh --revert-nought
   ```
   This will:
   * Restore previous GNOME desktop interface settings (GTK theme, icon theme, font, color scheme).
   * Restore previous GTK 3, GTK 4, and Qt/KDE settings.
   * Remove Nothing icon themes and application entries.
   * Remove Nought Hyprland, Quickshell, scripts, and theme links from `~/.config`.
   * Re-apply user's GNOME dconf settings (`dash-to-panel`, etc.).

2. **Reverting the Git repository**:
   The Nought integration lives on the dedicated `nought` git branch, with the previous state preserved at tag `backup-before-nought`.
   To revert the repository back to before Nought was added:
   ```bash
   git checkout main
   # (Or: git checkout backup-before-nought)
   ```


---

## 🎨 Font Support (MesloLGS NF)

`install.sh` automatically downloads and installs all 4 official **MesloLGS NF** font variants (Regular, Bold, Italic, Bold Italic) into `~/.local/share/fonts` and updates the font cache.

* **In your terminal emulator** (Ptyxis, GNOME Terminal, Alacritty, Kitty, Windows Terminal, etc.):
  Go to Settings / Preferences -> Appearance -> Font -> select **MesloLGS NF Regular**.
