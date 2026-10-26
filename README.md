# Dotfiles & Development Environment

Automated configuration and dotfiles to reproduce my exact WSL / Linux terminal setup on any fresh machine.

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
├── README.md                   # Documentation
├── .gitignore
├── .gitattributes
├── zsh/
│   ├── .zshrc                 # Main Zsh configuration
│   ├── .zshenv                # Shell environment exports
│   └── .p10k.zsh              # Powerlevel10k theme configuration
└── config/
    ├── nvim/                  # Neovim (LazyVim) configuration
    │   ├── init.lua
    │   ├── lazyvim.json
    │   ├── .neoconf.json
    │   ├── stylua.toml
    │   └── lua/
    │       ├── config/        # Autocmds, keymaps, lazy setup, options
    │       └── plugins/       # Custom language LSPs & toggleterm
    └── zellij/
        └── config.kdl         # Zellij custom layout & keybind configuration
```

---

## 🎨 Recommended Font

For icons in Powerlevel10k and `eza`, install a [Nerd Font](https://www.nerdfonts.com/) on your terminal/host machine:
* **MesloLGS NF** (Recommended for Powerlevel10k)
* JetBrains Mono Nerd Font
