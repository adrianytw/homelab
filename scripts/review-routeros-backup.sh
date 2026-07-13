#!/usr/bin/env bash
set -euo pipefail

backup_root="${BACKUP_DIR:-$HOME/homelab-backups}/routeros"
pack="${BACKUP_PACK:-}"
out="${REVIEW_OUT:-docs/routeros-baseline-review.md}"

if [[ -z "$pack" ]]; then
  pack="$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1)"
fi

if [[ -z "$pack" || ! -d "$pack" ]]; then
  echo "No RouterOS backup pack found. Run make backup-routeros first." >&2
  exit 1
fi

required=(
  resource.txt
  packages.txt
  addresses.txt
  dhcp.txt
  dns.txt
  containers.txt
  firewall-filter.rsc
  firewall-nat.rsc
  wireguard.rsc
  services.txt
  snmp.txt
  SHA256SUMS
  routeros.backup
  routeros.rsc
)

for file in "${required[@]}"; do
  if [[ ! -f "$pack/$file" ]]; then
    echo "Missing $pack/$file" >&2
    exit 1
  fi
done

(cd "$pack" && sha256sum -c SHA256SUMS >/dev/null)

first_match() {
  local pattern="$1"
  local file="$2"
  grep -m 1 -E "$pattern" "$file" | tr -d '\r' || true
}

kv_value() {
  local key="$1"
  local file="$2"
  first_match "^[[:space:]]*${key}:" "$file" | sed -E "s/^[[:space:]]*${key}:[[:space:]]*//; s/[[:space:]]+$//"
}

dhcp_lease_block() {
  local pattern="$1"
  local file="$2"
  awk -v pat="$pattern" '
    /^[[:space:]]*[0-9]+[[:space:]]/ {
      if (block ~ pat) { print block; found=1; exit }
      block=$0
      next
    }
    block { block=block " " $0 }
    END { if (!found && block ~ pat) print block }
  ' "$file" | tr -d '\r'
}

extract_token() {
  local token="$1"
  grep -oE "(^|[[:space:]])${token}=\"?[^\" ]+" | head -n 1 | sed -E "s/^[[:space:]]*${token}=//; s/^\"//; s/\"$//"
}

router_version="$(kv_value version "$pack/resource.txt")"
board="$(kv_value board-name "$pack/resource.txt")"
arch="$(kv_value architecture-name "$pack/resource.txt")"
backup_ts="$(basename "$pack")"
dhcp_pool="$(first_match 'ranges=' "$pack/dhcp.txt" | extract_token ranges)"
dhcp_dns="$(first_match 'dns-server=' "$pack/dhcp.txt" | extract_token dns-server)"
lease_time="$(first_match 'lease-time=' "$pack/dhcp.txt" | extract_token lease-time)"
router_dns="$(kv_value servers "$pack/dns.txt")"
remote_dns="$(kv_value allow-remote-requests "$pack/dns.txt")"
veth_line="$(first_match 'veth1-adguard' "$pack/containers.txt" | sed -E 's/[[:space:]]+/ /g')"
container_line="$(first_match 'adguardhome:latest' "$pack/containers.txt" | sed -E 's/[[:space:]]+/ /g')"
usb_line="$(first_match 'BMp[[:space:]]+usb1-part1' "$pack/containers.txt" | sed -E 's/[[:space:]]+/ /g')"
wg_line="$(first_match 'listen-port=' "$pack/wireguard.rsc" | sed -E 's/[[:space:]]+/ /g')"
wg_port="$(printf '%s\n' "$wg_line" | extract_token listen-port)"
wg_peers="$(grep -c 'public-key=' "$pack/wireguard.rsc" || true)"
wg_names="$(grep -oE 'comment=[^ ]+' "$pack/wireguard.rsc" | sed 's/comment=//; s/"//g' | awk 'BEGIN { ORS="" } { printf "%s%s", NR == 1 ? "" : ", ", $0 } END { print "" }')"
filter_rules="$(grep -c '^add ' "$pack/firewall-filter.rsc" || true)"
nat_rules="$(grep -c '^add ' "$pack/firewall-nat.rsc" || true)"
dstnat_2222="$(tr '\n\r' '  ' < "$pack/firewall-nat.rsc" | sed 's/add /\nadd /g' | grep 'dst-port=2222' | sed -E 's/[[:space:]]+/ /g; s/\\ / /g; s/^[ ]+//; s/[ ]+$//' || true)"
dstnat_status="not found"
[[ -n "$dstnat_2222" ]] && dstnat_status="present"
nmac_lease="$(dhcp_lease_block 'host-name="nmac"' "$pack/dhcp.txt")"
ha_lease="$(dhcp_lease_block 'host-name="homeassistant"' "$pack/dhcp.txt")"
nmac_addr="$(printf '%s\n' "$nmac_lease" | extract_token address)"
nmac_mac="$(printf '%s\n' "$nmac_lease" | extract_token mac-address)"
ha_addr="$(printf '%s\n' "$ha_lease" | extract_token address)"
ha_mac="$(printf '%s\n' "$ha_lease" | extract_token mac-address)"
snmp_enabled="$(kv_value enabled "$pack/snmp.txt")"
snmp_prometheus="$(grep -A 2 -m 1 'name="prometheus"' "$pack/snmp.txt" | tr '\n\r' '  ' | sed -E 's/[[:space:]]+/ /g; s/^[ ]+//; s/[ ]+$//' || true)"
snmp_source="$(printf '%s\n' "$snmp_prometheus" | extract_token addresses)"
snmp_security="$(printf '%s\n' "$snmp_prometheus" | extract_token security)"
snmp_read="$(printf '%s\n' "$snmp_prometheus" | extract_token read-access)"
snmp_write="$(printf '%s\n' "$snmp_prometheus" | extract_token write-access)"
snmp_public="$(first_match 'name="public"' "$pack/snmp.txt")"
snmp_public_status=enabled
[[ "$snmp_public" =~ X.*name=\"public\" ]] && snmp_public_status=disabled
www_ssl="$(dhcp_lease_block 'name="www-ssl"' "$pack/services.txt")"
www_ssl_port="$(printf '%s\n' "$www_ssl" | extract_token port)"
www_ssl_cert="$(printf '%s\n' "$www_ssl" | extract_token certificate)"
reverse_proxy="$(dhcp_lease_block 'name="reverse-proxy"' "$pack/services.txt")"
reverse_proxy_port="$(printf '%s\n' "$reverse_proxy" | extract_token port)"
reverse_proxy_cert="$(printf '%s\n' "$reverse_proxy" | extract_token certificate)"
certificate_count=not-captured
if [[ -f "$pack/certificates.txt" ]]; then
  certificate_count="$(grep -cE '^[[:space:]]+[0-9]+.*name=' "$pack/certificates.txt" || true)"
fi

review_flags=()
[[ -n "$dstnat_2222" ]] && review_flags+=("WAN dst-nat exists: TCP 2222 to 192.168.88.138:2222.")
for svc in www www-ssl reverse-proxy winbox api api-ssl; do
  if grep -q "name=\"${svc}\".*address=\"\"" "$pack/services.txt"; then
    review_flags+=("RouterOS service '${svc}' is enabled with unrestricted address field.")
  fi
done
[[ -n "$ha_addr" && "$ha_addr" != "192.168.88.30" ]] && review_flags+=("Home Assistant current lease is ${ha_addr}; target convention is 192.168.88.30 if free.")
[[ "$snmp_enabled" == yes ]] || review_flags+=("SNMP is not enabled for RouterOS resource monitoring.")
[[ "$snmp_source" == "192.168.88.20/32" ]] || review_flags+=("Prometheus SNMP source is '${snmp_source:-unknown}', expected 192.168.88.20/32.")
[[ "$snmp_security" == private ]] || review_flags+=("Prometheus SNMP security is '${snmp_security:-unknown}', expected authPriv/private.")
[[ "$snmp_read" == yes && "$snmp_write" == no ]] || review_flags+=("Prometheus SNMP access must remain read-only.")
[[ "$snmp_public_status" == disabled ]] || review_flags+=("Default public SNMP community is enabled.")
[[ "$www_ssl_port" == 8443 && "$www_ssl_cert" == homelab-router-rest ]] || review_flags+=("RouterOS REST listener differs from reviewed www-ssl:8443/homelab-router-rest state.")
[[ "$reverse_proxy_port" == 443 && "$reverse_proxy_cert" == homelab-adguard ]] || review_flags+=("AdGuard reverse proxy differs from reviewed port 443/homelab-adguard state.")

mkdir -p "$(dirname "$out")"

{
  cat <<EOF
# RouterOS Baseline Review

Generated from backup pack: \`${pack}\`

## Baseline

| Item | Value |
| --- | --- |
| Backup timestamp | \`${backup_ts}\` |
| RouterOS version | \`${router_version}\` |
| Board | \`${board}\` |
| Architecture | \`${arch}\` |
| Binary backup | \`routeros.backup\` |
| Full text export | \`routeros.rsc\` |

## DHCP And DNS

| Item | Value |
| --- | --- |
| DHCP pool | \`${dhcp_pool:-unknown}\` |
| DHCP lease time | \`${lease_time:-unknown}\` |
| DHCP DNS handed to clients | \`${dhcp_dns:-unknown}\` |
| RouterOS DNS upstream | \`${router_dns:-unknown}\` |
| RouterOS DNS remote requests | \`${remote_dns:-unknown}\` |

## AdGuard Container

| Item | Value |
| --- | --- |
| veth | \`${veth_line:-unknown}\` |
| container | \`${container_line:-unknown}\` |
| USB storage | \`${usb_line:-unknown}\` |

## WireGuard

| Item | Value |
| --- | --- |
| Listen port | \`${wg_port:-unknown}\` |
| Peer count | \`${wg_peers:-0}\` |
| Peer labels | \`${wg_names:-none}\` |

## Firewall And NAT

| Item | Value |
| --- | --- |
| Filter rule count | \`${filter_rules}\` |
| NAT rule count | \`${nat_rules}\` |
| WAN dst-nat 2222 | \`${dstnat_2222:-not found}\` |

## Monitoring

| Item | Value |
| --- | --- |
| SNMP enabled | \`${snmp_enabled:-unknown}\` |
| Prometheus source | \`${snmp_source:-unknown}\` |
| Prometheus security | \`${snmp_security:-unknown}\` |
| Prometheus access | read=\`${snmp_read:-unknown}\`, write=\`${snmp_write:-unknown}\` |
| Default public community | \`${snmp_public_status}\` |

## TLS Services

| Item | Value |
| --- | --- |
| RouterOS REST | www-ssl port \`${www_ssl_port:-unknown}\`, certificate \`${www_ssl_cert:-unknown}\` |
| AdGuard HTTPS | reverse-proxy port \`${reverse_proxy_port:-unknown}\`, certificate \`${reverse_proxy_cert:-unknown}\` |
| Certificate inventory entries | \`${certificate_count}\` |

## DHCP Lease Candidates

| Host | Address | MAC | Note |
| --- | --- | --- | --- |
| nmac | \`${nmac_addr:-unknown}\` | \`${nmac_mac:-unknown}\` | target MacBook/k3s host |
| homeassistant | \`${ha_addr:-unknown}\` | \`${ha_mac:-unknown}\` | target convention is \`192.168.88.30\` if free |

## Review Flags

EOF

  if ((${#review_flags[@]} == 0)); then
    echo "- None found."
  else
    for flag in "${review_flags[@]}"; do
      printf -- "- %s\n" "$flag"
    done
  fi

  cat <<EOF

## Remaining Decisions

- WAN dst-nat \`2222 -> 192.168.88.138:2222\`: \`${dstnat_status}\`.
- RouterOS admin services: preserve the AdGuard reverse proxy; review whether to disable unused WebFig/API listeners later.
- DHCP pool shrink: defer until current leases are reviewed.
- Home Assistant lease: currently \`${ha_addr:-unknown}\`; target convention remains \`192.168.88.30\` for a later migration.

## Safety

This review is sanitized. It intentionally omits sensitive key material and does not include binary backup content.
EOF
} > "$out"

echo "$out"
