# DigitalOcean helpers (sourced from .zshrc). Same idea as gcloud.zsh: each
# repo binds itself to a doctl auth context, nothing is machine specific.
#
#   doinit [ctx]    bind this repo: pick (or create) a doctl context, write
#                   DIGITALOCEAN_CONTEXT into .envrc
#   doctx           switch the global doctl context (fzf)
#   dossh           ssh into a droplet (fzf)
#   dologs [-f]     App Platform runtime logs of an app (fzf), -f follows
#   dodeploy        redeploy an App Platform app (fzf, asks first)
#   dok8s           save a DOKS cluster kubeconfig (then kctx / k9s)
#
# Tokens live in doctl's config (~/Library/Application Support/doctl), never
# in .envrc: the context name is all a repo stores.

command -v doctl >/dev/null 2>&1 || return 0

_do_pick() { fzf --height=40% --reverse --prompt="$1 › " "${@:2}"; }

_do_contexts() { doctl auth list 2>/dev/null | sed 's/ (current)$//'; }

doinit() {
  local root ctx
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  ctx="$(_do_contexts | _do_pick "doctl context (type a new name to create)" \
    --print-query --query="${1:-}" | tail -1)"
  [[ -n "$ctx" ]] || return 1
  ctx="${ctx:l}"
  if ! _do_contexts | grep -qx "$ctx"; then
    print "new context $ctx: paste a token from https://cloud.digitalocean.com/account/api/tokens"
    doctl auth init --context "$ctx" || return 1
  fi

  local envrc="$root/.envrc" line="export DIGITALOCEAN_CONTEXT=$ctx"
  if [[ -f "$envrc" ]] && grep -q '^export DIGITALOCEAN_CONTEXT=' "$envrc"; then
    sed -i '' "s/^export DIGITALOCEAN_CONTEXT=.*/$line/" "$envrc"
  else
    print -r -- "$line" >>"$envrc"
  fi
  # you ran doinit here, so this .envrc is yours: allow it
  command -v direnv >/dev/null && direnv allow "$root"
  print "doctl: $root -> context $ctx"
  git -C "$root" check-ignore -q .envrc 2>/dev/null ||
    print "note: .envrc is not gitignored (add it, or commit it on purpose)"
}

doctx() {
  local ctx
  ctx="$(_do_contexts | _do_pick doctl)" || return 1
  [[ -n "$ctx" ]] || return 1
  doctl auth switch --context "$ctx"
  [[ -n "$DIGITALOCEAN_CONTEXT" ]] &&
    print "note: this dir pins DIGITALOCEAN_CONTEXT=$DIGITALOCEAN_CONTEXT (direnv), which wins here"
}

dossh() {
  local id
  id="$(doctl compute droplet list --format ID,Name,PublicIPv4,Region,Status,Tags --no-header |
    _do_pick droplet --header="ID NAME IP REGION STATUS TAGS" | awk '{print $1}')" || return 1
  [[ -n "$id" ]] || return 1
  doctl compute ssh "$id" "$@"
}

_do_app() {
  doctl apps list --format ID,Spec.Name,DefaultIngress,ActiveDeployment.Phase --no-header |
    _do_pick app | awk '{print $1}'
}

dologs() {
  local app
  app="$(_do_app)" || return 1
  [[ -n "$app" ]] || return 1
  doctl apps logs "$app" --type run "$@"
}

dodeploy() {
  local app
  app="$(_do_app)" || return 1
  [[ -n "$app" ]] || return 1
  read -q "?redeploy app $app? [y/N] " || { print; return 1; }
  print
  doctl apps create-deployment "$app" --wait
}

dok8s() {
  local cluster
  cluster="$(doctl kubernetes cluster list --format Name,Region,Version,Status --no-header |
    _do_pick cluster | awk '{print $1}')" || return 1
  [[ -n "$cluster" ]] || return 1
  doctl kubernetes cluster kubeconfig save "$cluster"
}
