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
# tmux (exec early — the pre-tmux shell skips the rest of init)
# --------------------------------
if [[ -z "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi

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
setopt EXTENDED_GLOB

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

# --------------------------------
# Completions
# --------------------------------
# Generated completions are cached and refreshed once a day instead of
# being regenerated on every shell start (ng/npm spawn Node each time).
_zsh_comp_cache="$HOME/.cache/zsh/completions"
mkdir -p "$_zsh_comp_cache"

_cache_comp() {
  local out="$_zsh_comp_cache/$1"
  shift
  if [[ ! -s "$out" || -z $out(#qN.mh-24) ]]; then
    "$@" >| "$out" 2>/dev/null || rm -f "$out"
  fi
}

# docker/task emit fpath-style completion files
command -v docker >/dev/null 2>&1 && _cache_comp _docker docker completion zsh
command -v task >/dev/null 2>&1 && _cache_comp _task task --completion zsh

fpath=(
  "$_zsh_comp_cache"
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-completions"
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions"
  $fpath
)

# Rebuild the dump when it is older than a day, otherwise trust it.
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh-24) ]]; then
  compinit -C
else
  compinit
fi

# Google Cloud SDK: PATH + completions
if [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/path.zsh.inc" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/path.zsh.inc"
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc"
fi

# npm/ng emit source-style scripts
if command -v npm >/dev/null 2>&1; then
  _cache_comp npm.zsh npm completion
  [[ -s "$_zsh_comp_cache/npm.zsh" ]] && source "$_zsh_comp_cache/npm.zsh"
fi

if command -v ng >/dev/null 2>&1; then
  _cache_comp ng.zsh ng completion script
  [[ -s "$_zsh_comp_cache/ng.zsh" ]] && source "$_zsh_comp_cache/ng.zsh"
fi

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

if command -v navi >/dev/null 2>&1; then
  eval "$(navi widget zsh)"
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

if [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/share/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/fzf-tab/fzf-tab.plugin.zsh"
fi

# --------------------------------
# Prompt
# --------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
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
alias vi='nvim'
alias vim='nvim'
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

# --------------------------------
# Plugins (syntax highlighting must be sourced last)
# --------------------------------
if [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
