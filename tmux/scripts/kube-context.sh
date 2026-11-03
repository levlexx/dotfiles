#!/usr/bin/env bash
#
# Status capsule with the current kube context, so a remote cluster is never
# a surprise. Local clusters (k3d-*, docker-desktop, kind-*) render muted,
# anything else red. Prints nothing without a kubeconfig.

config="${KUBECONFIG:-$HOME/.kube/config}"
config="${config%%:*}"
[ -r "$config" ] || exit 0

ctx="$(awk '/^current-context:/ { print $2; exit }' "$config")"
[ -n "$ctx" ] || exit 0

case "$ctx" in
k3d-* | kind-* | docker-desktop | minikube | orbstack) fg="#7dcfff" bg="#292e42" ;;
*) fg="#1a1b26" bg="#f7768e" ;;
esac

printf '#[fg=%s,bg=default]\xee\x82\xb6#[fg=%s,bg=%s,bold]\xf3\xb1\x83\xbe %s#[fg=%s,bg=default]\xee\x82\xb4 ' \
	"$bg" "$fg" "$bg" "$ctx" "$bg"
