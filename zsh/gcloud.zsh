# gcloud helpers (sourced from .zshrc). Nothing here is machine specific:
# each repo binds itself to a gcloud configuration with `gcinit`, so the
# two Macs can have different projects.
#
#   gcinit [name]   bind this repo: pick project/region, create config
#                   <name>, write CLOUDSDK_ACTIVE_CONFIG_NAME into .envrc
#   gcfg            switch the global configuration (fzf)
#   crlogs [svc]    recent Cloud Run logs, colored (freshness: $CRLOGS_SINCE)
#   crtail [svc]    live Cloud Run logs
#   crurl  [svc]    service URL (copied to the clipboard)
#   crrev  [svc]    revisions + traffic; enter sends 100% to the picked one
#
# [svc] is picked with fzf when omitted.

command -v gcloud >/dev/null 2>&1 || return 0

_gc_pick() { fzf --height=40% --reverse --prompt="$1 › " "${@:2}"; }

_gc_service() {
  if [[ -n "$1" ]]; then
    print -r -- "$1"
    return
  fi
  gcloud run services list --format='value(metadata.name)' 2>/dev/null | _gc_pick service
}

gcinit() {
  local root name project region account
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  name="${1:-${root:t}}"
  name="${name:l}"
  name="${name//[^a-z0-9-]/-}"

  project="$(gcloud projects list --format='value(projectId,name)' --sort-by=projectId |
    _gc_pick project --with-nth=1.. | awk '{print $1}')" || return 1
  [[ -n "$project" ]] || return 1
  region="$(print -l europe-west1 europe-west3 europe-west4 europe-central2 \
    us-central1 us-east1 |
    _gc_pick "region (cloud run)" --print-query | tail -1)" || return 1
  account="$(gcloud config get account 2>/dev/null)"

  if ! gcloud config configurations describe "$name" >/dev/null 2>&1; then
    gcloud config configurations create "$name" --no-activate >/dev/null || return 1
  fi
  gcloud config set core/project "$project" --configuration="$name" --quiet >/dev/null
  [[ -n "$account" ]] && gcloud config set core/account "$account" --configuration="$name" --quiet >/dev/null
  if [[ -n "$region" ]]; then
    gcloud config set run/region "$region" --configuration="$name" --quiet >/dev/null
    gcloud config set compute/region "$region" --configuration="$name" --quiet >/dev/null
    gcloud config set artifacts/location "$region" --configuration="$name" --quiet >/dev/null
  fi

  local envrc="$root/.envrc" line="export CLOUDSDK_ACTIVE_CONFIG_NAME=$name"
  if [[ -f "$envrc" ]] && grep -q '^export CLOUDSDK_ACTIVE_CONFIG_NAME=' "$envrc"; then
    sed -i '' "s/^export CLOUDSDK_ACTIVE_CONFIG_NAME=.*/$line/" "$envrc"
  else
    print -r -- "$line" >>"$envrc"
  fi
  # you ran gcinit here, so this .envrc is yours: allow it
  command -v direnv >/dev/null && direnv allow "$root"
  print "gcloud: $root -> config $name ($project${region:+, $region})"
  git -C "$root" check-ignore -q .envrc 2>/dev/null ||
    print "note: .envrc is not gitignored (add it, or commit it on purpose)"
}

gcfg() {
  local name
  name="$(gcloud config configurations list \
    --format='value(name,is_active,properties.core.project,properties.run.region)' |
    awk -F'\t' '{printf "%s\t%s\t%s\t%s\n", $1, ($2=="True" ? "*" : " "), $3, $4}' |
    column -t -s $'\t' | _gc_pick gcloud | awk '{print $1}')" || return 1
  [[ -n "$name" ]] || return 1
  gcloud config configurations activate "$name"
  [[ -n "$CLOUDSDK_ACTIVE_CONFIG_NAME" ]] &&
    print "note: this dir pins CLOUDSDK_ACTIVE_CONFIG_NAME=$CLOUDSDK_ACTIVE_CONFIG_NAME (direnv), which wins here"
}

crlogs() {
  local svc
  svc="$(_gc_service "$1")" || return 1
  [[ -n "$svc" ]] || return 1
  gcloud logging read \
    "resource.type=cloud_run_revision AND resource.labels.service_name=$svc" \
    --freshness="${CRLOGS_SINCE:-1h}" --limit="${CRLOGS_LIMIT:-300}" --order=asc --format=json |
    jq -r '.[] | [
        (.timestamp[11:19]),
        (.severity // "DEFAULT"),
        (.textPayload // .jsonPayload.message // .jsonPayload.msg
          // (.httpRequest | select(.) | "\(.requestMethod) \(.status) \(.requestUrl) \(.latency // "")")
          // (.jsonPayload | tostring))
      ] | @tsv' |
    awk -F'\t' '{
      c = "\033[0m"
      if ($2 ~ /ERROR|CRITICAL|ALERT|EMERGENCY/) c = "\033[31m"
      else if ($2 ~ /WARNING/) c = "\033[33m"
      else if ($2 ~ /DEBUG/) c = "\033[90m"
      printf "\033[90m%s\033[0m %s%-7s\033[0m %s\n", $1, c, substr($2, 1, 7), $3
    }'
}

crtail() {
  local svc
  svc="$(_gc_service "$1")" || return 1
  [[ -n "$svc" ]] || return 1
  gcloud beta run services logs tail "$svc"
}

crurl() {
  local svc url
  svc="$(_gc_service "$1")" || return 1
  [[ -n "$svc" ]] || return 1
  url="$(gcloud run services describe "$svc" --format='value(status.url)')" || return 1
  print -r -- "$url"
  print -rn -- "$url" | pbcopy
}

crrev() {
  local svc rev
  svc="$(_gc_service "$1")" || return 1
  [[ -n "$svc" ]] || return 1
  rev="$(gcloud run revisions list --service="$svc" --sort-by='~metadata.creationTimestamp' \
    --format='table[no-heading](metadata.name,metadata.creationTimestamp.date("%Y-%m-%d %H:%M"),status.conditions[0].status,spec.containers[0].image.basename())' |
    _gc_pick "$svc revision (enter: 100% traffic)" \
      --header="$(gcloud run services describe "$svc" --format='value(status.traffic)' 2>/dev/null)" |
    awk '{print $1}')" || return 1
  [[ -n "$rev" ]] || return 1
  read -q "?send 100% of $svc traffic to $rev? [y/N] " || { print; return 1; }
  print
  gcloud run services update-traffic "$svc" --to-revisions="$rev=100"
}
