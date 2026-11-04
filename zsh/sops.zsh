# sops + age: encrypted .env in the repo (sourced from .zshrc).
#
#   sopsinit [age1... ...]  set up this repo: age key (created once per Mac),
#                           .sops.yaml with your key plus any extra recipients
#                           (the other Mac, teammates), .env -> .env.sops,
#                           `use sops` in .envrc
#   senv                    edit .env.sops in $EDITOR (re-encrypts on save)
#   agepub                  print this Mac's public key (add it on the other Mac)
#
# Commit .sops.yaml and .env.sops; .env stays ignored. The private key lives
# in $SOPS_AGE_KEY_FILE and never in the repo; Claude is denied reading it.

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$XDG_CONFIG_HOME/sops/age/keys.txt}"

agepub() { age-keygen -y "$SOPS_AGE_KEY_FILE"; }

senv() { sops edit --input-type dotenv --output-type dotenv "${1:-.env.sops}"; }

sopsinit() {
  command -v sops >/dev/null && command -v age-keygen >/dev/null || {
    print -u2 "sops/age missing (mise install)"
    return 1
  }
  local root recipients
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  if [[ ! -f "$SOPS_AGE_KEY_FILE" ]]; then
    mkdir -p "${SOPS_AGE_KEY_FILE:h}"
    (umask 077 && age-keygen -o "$SOPS_AGE_KEY_FILE" 2>&1 | grep -v "^Public key") ; [[ -f "$SOPS_AGE_KEY_FILE" ]] || return 1
    print "created age key $SOPS_AGE_KEY_FILE (back it up: password manager)"
  fi
  recipients="$(print -l "$(agepub)" "$@" | awk 'NF && !seen[$0]++' | paste -sd, -)"

  if [[ -e "$root/.sops.yaml" ]]; then
    print "keeping existing $root/.sops.yaml"
  else
    cat >"$root/.sops.yaml" <<YAML
creation_rules:
  - path_regex: (^|/)(\.env\.sops|.*\.sops\.(ya?ml|json|env))$
    age: >-
      $recipients
YAML
    print "created .sops.yaml (recipients: $recipients)"
  fi

  if [[ -f "$root/.env" && ! -e "$root/.env.sops" ]]; then
    (cd "$root" && sops encrypt --input-type dotenv --output-type dotenv \
      --filename-override .env.sops .env >.env.sops) || return 1
    print "encrypted .env -> .env.sops (.env itself stays local and ignored)"
  fi

  local envrc="$root/.envrc"
  if ! grep -qs '^use sops' "$envrc"; then
    print -r -- "use sops" >>"$envrc"
    print "added 'use sops' to .envrc"
  fi
  command -v direnv >/dev/null && direnv allow "$root"
  git -C "$root" check-ignore -q .env 2>/dev/null || print "note: .env is not gitignored"
}
