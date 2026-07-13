#!/usr/bin/env bash
set -euo pipefail

host="${BACKUP_HOST:-nmac}"
root="${APP_BACKUP_DIR:-$HOME/homelab-backups/data}"
identity="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
app="${1:-}"

case "$app" in
  glance) pvc=glance-assets ;;
  uptime-kuma) pvc=uptime-kuma-data ;;
  ntfy) pvc=ntfy-data ;;
  healthchecks) pvc=healthchecks-data ;;
  prometheus) pvc=prometheus-data; extra_pvc=alertmanager-data; extra_deployment=alertmanager ;;
  grafana) pvc=grafana-data ;;
  *) echo "APP must be one of: glance uptime-kuma ntfy healthchecks prometheus grafana" >&2; exit 2 ;;
esac

ssh_cmd() {
  local arg command=()
  for arg; do printf -v arg '%q' "$arg"; command+=("$arg"); done
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$host" "${command[*]}"
}
kube() { ssh_cmd sudo -n k3s kubectl "$@"; }

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
dest="$root/$app/$stamp"
archive="$dest/$app.tar.age"
unit="homelab-backup-rollback-$app"
armed=0 suspended=0 scaled=0

recover() {
  local rc=$?
  trap - EXIT INT TERM
  if ((scaled)); then
    kube -n core scale "deployment/$app" --replicas=1 >/dev/null 2>&1 || true
    [[ -z ${extra_deployment:-} ]] || kube -n core scale "deployment/$extra_deployment" --replicas=1 >/dev/null 2>&1 || true
  fi
  if ((suspended)); then
    kube -n flux-system patch "kustomization/$app" --type=merge -p '{"spec":{"suspend":false}}' >/dev/null 2>&1 || true
    kube -n flux-system patch kustomization/flux-system --type=merge -p '{"spec":{"suspend":false}}' >/dev/null 2>&1 || true
  fi
  if ((armed)); then ssh_cmd sudo -n systemctl stop "$unit.timer" "$unit.service" >/dev/null 2>&1 || true; fi
  ((rc == 0)) || echo "backup failed; automatic application/Flux recovery attempted" >&2
  exit "$rc"
}
trap recover EXIT INT TERM

for cmd in ssh age age-keygen sops tar sha256sum sqlite3; do command -v "$cmd" >/dev/null || { echo "missing command: $cmd" >&2; exit 1; }; done
test -r "$identity" || { echo "age identity is not readable: $identity" >&2; exit 1; }
recipient="${AGE_RECIPIENT:-$(age-keygen -y "$identity")}"
[[ "$recipient" == age1* ]] || { echo "invalid age recipient" >&2; exit 1; }
ssh_cmd true
ssh_cmd sudo -n true
SOPS_AGE_KEY_FILE="$identity" sops --decrypt cluster/apps/ntfy/admin-credentials.enc.yaml >/dev/null
kube -n flux-system wait kustomization --all --for=condition=Ready --timeout=60s

pv="$(kube -n core get pvc "$pvc" -o jsonpath='{.spec.volumeName}')"
[[ -n "$pv" ]] || { echo "$pvc is not bound" >&2; exit 1; }
path="$(kube get pv "$pv" -o jsonpath='{.spec.hostPath.path}')"
[[ "$path" == /var/lib/rancher/k3s/storage/* ]] || { echo "refusing unexpected PVC path: $path" >&2; exit 1; }
bytes="$(ssh_cmd sudo -n du -sb "$path" | awk '{print $1}')"
if [[ -n ${extra_pvc:-} ]]; then
  extra_pv="$(kube -n core get pvc "$extra_pvc" -o jsonpath='{.spec.volumeName}')"
  [[ -n "$extra_pv" ]] || { echo "$extra_pvc is not bound" >&2; exit 1; }
  extra_path="$(kube get pv "$extra_pv" -o jsonpath='{.spec.hostPath.path}')"
  [[ "$extra_path" == /var/lib/rancher/k3s/storage/* ]] || { echo "refusing unexpected PVC path: $extra_path" >&2; exit 1; }
  bytes=$((bytes + $(ssh_cmd sudo -n du -sb "$extra_path" | awk '{print $1}')))
fi
mkdir -p "$dest"
chmod 0700 "$root" "$root/$app" "$dest" 2>/dev/null || true
available="$(df -PB1 "$dest" | awk 'NR==2 {print $4}')"
((available > bytes * 2 + 104857600)) || { echo "insufficient backup free space" >&2; exit 1; }
test -w "$dest"

rollback="sudo k3s kubectl -n core scale deployment/$app --replicas=1; ${extra_deployment:+sudo k3s kubectl -n core scale deployment/$extra_deployment --replicas=1;} sudo k3s kubectl -n flux-system patch kustomization/$app --type=merge -p '{\"spec\":{\"suspend\":false}}'; sudo k3s kubectl -n flux-system patch kustomization/flux-system --type=merge -p '{\"spec\":{\"suspend\":false}}'"
ssh_cmd sudo -n systemd-run --unit="$unit" --on-active=10m /bin/sh -c "$rollback" >/dev/null
armed=1
kube -n flux-system patch kustomization/flux-system --type=merge -p '{"spec":{"suspend":true}}' >/dev/null
kube -n flux-system patch "kustomization/$app" --type=merge -p '{"spec":{"suspend":true}}' >/dev/null
suspended=1
kube -n core scale "deployment/$app" --replicas=0 >/dev/null
[[ -z ${extra_deployment:-} ]] || kube -n core scale "deployment/$extra_deployment" --replicas=0 >/dev/null
scaled=1
kube -n core wait --for=delete "pod" -l "app=$app" --timeout=120s
[[ -z ${extra_deployment:-} ]] || kube -n core wait --for=delete pod -l "app=$extra_deployment" --timeout=120s

ssh_cmd sudo -n tar --acls --xattrs --selinux --numeric-owner -C "$path" -cpf - . | age -r "$recipient" -o "$archive"
chmod 0600 "$archive"
if [[ -n ${extra_pvc:-} ]]; then
  extra_archive="$dest/$extra_pvc.tar.age"
  ssh_cmd sudo -n tar --acls --xattrs --selinux --numeric-owner -C "$extra_path" -cpf - . | age -r "$recipient" -o "$extra_archive"
  chmod 0600 "$extra_archive"
fi
(cd "$dest" && sha256sum ./*.tar.age > SHA256SUMS)
chmod 0600 "$dest/SHA256SUMS"
(cd "$dest" && sha256sum -c SHA256SUMS)
age -d -i "$identity" "$archive" | tar -tf - >/dev/null
[[ -z ${extra_archive:-} ]] || age -d -i "$identity" "$extra_archive" | tar -tf - >/dev/null

case "$app" in
  uptime-kuma|ntfy|healthchecks|grafana)
    scratch="$(mktemp -d)"
    checked=0
    trap 'rm -rf "${scratch:-}"; recover' EXIT INT TERM
    age -d -i "$identity" "$archive" | tar -xf - -C "$scratch"
    while IFS= read -r -d '' db; do
      [[ "$(sqlite3 "$db" 'PRAGMA quick_check;')" == ok ]] || { echo "SQLite quick_check failed: $db" >&2; exit 1; }
      checked=$((checked + 1))
    done < <(find "$scratch" -type f \( -name '*.db' -o -name '*.sqlite' \) -print0)
    ((checked > 0)) || { echo "no SQLite database found for $app" >&2; exit 1; }
    rm -rf "$scratch"
    ;;
esac

kube -n core scale "deployment/$app" --replicas=1 >/dev/null
[[ -z ${extra_deployment:-} ]] || kube -n core scale "deployment/$extra_deployment" --replicas=1 >/dev/null
scaled=0
kube -n flux-system patch "kustomization/$app" --type=merge -p '{"spec":{"suspend":false}}' >/dev/null
kube -n flux-system patch kustomization/flux-system --type=merge -p '{"spec":{"suspend":false}}' >/dev/null
suspended=0
kube -n flux-system annotate "kustomization/$app" reconcile.fluxcd.io/requestedAt="$(date -u +%FT%TZ)" --overwrite >/dev/null
kube -n core rollout status "deployment/$app" --timeout=180s
[[ -z ${extra_deployment:-} ]] || kube -n core rollout status "deployment/$extra_deployment" --timeout=180s
kube -n flux-system wait "kustomization/$app" --for=condition=Ready --timeout=180s
ssh_cmd sudo -n systemctl stop "$unit.timer" "$unit.service" >/dev/null
armed=0
trap - EXIT INT TERM
echo "$archive"
