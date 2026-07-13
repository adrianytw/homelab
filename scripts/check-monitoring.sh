#!/usr/bin/env bash
set -euo pipefail

version=3.13.1
case "$(uname -m)" in
  x86_64) arch=amd64; checksum=962b812371aff838d152b6ff2d56fdb7a6396f5542f48ebf73421b9721f0d103 ;;
  aarch64|arm64) arch=arm64; checksum=fbd8e5e0f6ad2e7d053e717739186caee4fd0cab2cf9335bfc86c292fe2a2bfe ;;
  *) echo "unsupported architecture for promtool: $(uname -m)" >&2; exit 1 ;;
esac

promtool="${PROMTOOL:-$(command -v promtool || true)}"
archive=""
if [[ -z "$promtool" ]]; then
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/homelab/prometheus-${version}-${arch}"
  promtool="$cache/promtool"
  if [[ ! -x "$promtool" ]]; then
    archive="$(mktemp)"
    curl -fsSL "https://github.com/prometheus/prometheus/releases/download/v${version}/prometheus-${version}.linux-${arch}.tar.gz" -o "$archive"
    printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >/dev/null
    mkdir -p "$cache"
    tar -xzf "$archive" -C "$cache" --strip-components=1 "prometheus-${version}.linux-${arch}/promtool"
  fi
fi

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
  [[ -z "$archive" ]] || rm -f "$archive"
}
trap cleanup EXIT

awk '/^  prometheus.yml: \|$/ { copy=1; next } /^  alerts.yaml: \|$/ { copy=0 } copy { sub(/^    /, ""); print }' cluster/apps/prometheus/app.yaml >"$tmp/prometheus.yml"
awk '/^  alerts.yaml: \|$/ { copy=1; next } /^---$/ { if (copy) exit } copy { sub(/^    /, ""); print }' cluster/apps/prometheus/app.yaml >"$tmp/alerts.yaml"
"$promtool" check config "$tmp/prometheus.yml"
"$promtool" check rules "$tmp/alerts.yaml"

awk '/^  nmac.json: \|$/ { copy=1; next } /^  router.json: \|$/ { copy=0 } copy { sub(/^    /, ""); print }' cluster/apps/grafana/app.yaml >"$tmp/nmac.json"
awk '/^  router.json: \|$/ { copy=1; next } /^---$/ { if (copy) exit } copy { sub(/^    /, ""); print }' cluster/apps/grafana/app.yaml >"$tmp/router.json"
python3 -m json.tool "$tmp/nmac.json" >/dev/null
python3 -m json.tool "$tmp/router.json" >/dev/null

echo "monitoring config ok"
