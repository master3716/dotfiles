# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# Oh My Zsh
# ============================================================

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    vi-mode
    colored-man-pages
    command-not-found
    extract
    history
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf-tab
)

source "$ZSH/oh-my-zsh.sh"

# ============================================================
# PATH
# ============================================================

export PATH="$HOME/.local/bin:$HOME/bin:/opt/nvim-linux-x86_64/bin:$PATH"

# ============================================================
# Editor
# ============================================================

export EDITOR="nvim"
export VISUAL="nvim"

# ============================================================
# Modern CLI replacements
# ============================================================

# Ubuntu installs bat as batcat
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    alias bat='batcat'
fi
if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
    alias cat='bat'
fi

alias zj='zellij'
alias python='python3'

# ripgrep
if command -v rg &>/dev/null; then
    alias grep='rg'
fi

# fd is called fdfind on Ubuntu
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    alias fd='fdfind'
fi

# Neovim
if command -v nvim &>/dev/null; then
    alias vim='nvim'
    alias vi='nvim'
fi

# eza
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -lah --icons'
    alias la='eza -a --icons'
    alias lt='eza --tree --icons'
fi

# ============================================================
# Git
# ============================================================

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gca='git commit --amend'
alias gcm='git commit -m'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gf='git fetch'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gm='git merge'
alias gr='git restore'
alias grs='git restore --staged'
alias gst='git stash'
alias gstp='git stash pop'
alias glog='git log --oneline --graph --decorate --all'

# ============================================================
# Navigation
# ============================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ============================================================
# Useful commands
# ============================================================

alias c='clear'
alias cls='clear'
alias h='history'
alias j='jobs'

# ============================================================
# FZF
# ============================================================

export FZF_DEFAULT_OPTS="
--height 40%
--layout=reverse
--border
--info=inline
"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Ctrl+T = fuzzy file finder
# Ctrl+R = fuzzy history
# Alt+C = fuzzy directory finder

# ============================================================
# Vi mode
# ============================================================

bindkey -v

# Small escape delay so Esc feels responsive
export KEYTIMEOUT=1

# jj = escape to normal mode
bindkey -M viins 'jj' vi-cmd-mode

# ============================================================
# History
# ============================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# ============================================================
# Completion
# ============================================================

autoload -Uz compinit
compinit

# ============================================================
# Direnv
# ============================================================

if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi

# ============================================================
# WSL
# ============================================================

# Make sure Windows executables remain available
if [[ -d /mnt/c/Windows/System32 ]]; then
    export PATH="$PATH:/mnt/c/Windows/System32"
fi

# ============================================================
# Prompt
# ============================================================

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi
