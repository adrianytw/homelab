#!/usr/bin/env bash
set -euo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="diagnostics/${ts}/routeros"
mkdir -p "$out"

run() {
  local name="$1"
  local cmd="$2"
  ssh router "$cmd" >"${out}/${name}.txt"
}

run resource "/system resource print"
run packages "/system package print"
run addresses "/ip address print detail"
run pools "/ip pool print detail"
run dhcp_servers "/ip dhcp-server print detail"
run dhcp_networks "/ip dhcp-server network print detail"
run dhcp_leases "/ip dhcp-server lease print detail"
run dns "/ip dns print"
run bridges "/interface bridge print detail; /interface bridge port print detail"
run veth "/interface veth print"
run containers "/container print; /container config print; /container mounts print"
run disks "/disk print; /file print where name~\"usb|adguard\""
run firewall_filter "/ip firewall filter print"
run firewall_nat "/ip firewall nat print"
run wireguard "/interface wireguard print; /interface wireguard peers print"
run services "/ip service print detail"

echo "$out"
