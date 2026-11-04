# shellcheck shell=bash
# `use sops [file]` in .envrc: decrypt a sops-encrypted dotenv (default
# .env.sops) and export it. Plaintext never touches the disk; the file is
# watched, so `sops edit` reloads the env on the next prompt.
use_sops() {
  local file="${1:-.env.sops}" plain
  watch_file "$file"
  if [[ ! -f "$file" ]]; then
    log_error "use sops: $file not found (sopsinit)"
    return 1
  fi
  if ! plain="$(sops --decrypt --input-type dotenv --output-type dotenv "$file")"; then
    log_error "use sops: cannot decrypt $file (age key in ${SOPS_AGE_KEY_FILE:-~/.config/sops/age/keys.txt}?)"
    return 1
  fi
  eval "$(direnv dotenv bash <(printf '%s\n' "$plain"))"
}
