# --------------------------------
# Base env
# --------------------------------
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R"
export LESS="-FRX"
export CLICOLOR=1

# --------------------------------
# Homebrew / PATH
# --------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=(
  "$HOME/go/bin"
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.lmstudio/bin"
  "$HOME/.moon/bin"
  $path
)
path=(${path:#/usr/local/go/bin})
typeset -U path PATH
export PATH

[[ -o interactive ]] || return

# --------------------------------
# Ghostty shell integration fallback
# --------------------------------
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" && -f "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration" ]]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi

# --------------------------------
# Version managers
# --------------------------------
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
  path=(${path:#/usr/local/go/bin})
  typeset -U path PATH
  export PATH
fi

# --------------------------------
# Shell behavior
# --------------------------------
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_GLOB

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

autoload -Uz compinit
compinit

# --------------------------------
# Tools
# --------------------------------
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# fzf restores zsh options verbatim; `zle` is not changeable here.
__fzf_restore_options() {
  local restore="$1"
  restore="${restore// zle on/}"
  restore="${restore// zle off/}"
  eval "$restore"
}

if command -v fzf >/dev/null 2>&1; then
  __fzf_zsh_init="$(fzf --zsh)"
  __fzf_zsh_init="${__fzf_zsh_init//eval \$__fzf_key_bindings_options/__fzf_restore_options \"\$__fzf_key_bindings_options\"}"
  __fzf_zsh_init="${__fzf_zsh_init//eval \$__fzf_completion_options/__fzf_restore_options \"\$__fzf_completion_options\"}"
  source <(print -r -- "$__fzf_zsh_init")
  unset __fzf_zsh_init
fi
unfunction __fzf_restore_options

# --------------------------------
# Prompt
# --------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# --------------------------------
# Completions
# --------------------------------
if command -v ng >/dev/null 2>&1; then
  source <(ng completion script)
fi

# --------------------------------
# Aliases
# --------------------------------
alias ls='eza --icons=auto'
alias ll='eza -la --icons=auto --git'
alias lt='eza --tree --level=2 --icons=auto'
alias cat='bat --paging=never'
alias c='clear'

alias lg='lazygit'
# --------------------------------
# Git core
# --------------------------------
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit -a -v'
alias gcam='git commit -a -m'
alias gcl='git clone'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gpu='git push'
alias gpf='git push --force-with-lease'
alias gst='git status -sb'
alias gd='git diff'
alias gdc='git diff --cached'
alias gl='git log --oneline --graph --decorate --all'
alias glog='git log --stat'
alias gr='git remote'
alias gra='git remote add'
alias grv='git remote -v'
alias gm='git merge'
alias grb='git rebase'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gcp='git cherry-pick'
alias gclean='git clean -fd'
alias gpristine='git reset --hard && git clean -fd'
alias gundo='git reset --soft HEAD~1'
alias gca!='git commit --amend --no-edit'


alias gpom='git push origin $(git branch --show-current)'
alias gplom='git pull origin $(git branch --show-current)'
alias gfix='git commit --fixup'
alias gsquash='git rebase -i --autosquash'
alias gconflict='git diff --name-only --diff-filter=U'

alias v='nvim'
alias ..='cd ..'
alias ...='cd ../..'

alias yz='yazi'
alias y='yazi .'
# --------------------------------
# Keybindings
# --------------------------------
bindkey '^R' atuin-search-zsh

# --------------------------------
# Optional
# --------------------------------
# source ~/.autoenv/activate.sh
# . "$HOME/.moon/bin/env"

if [[ -z "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi
