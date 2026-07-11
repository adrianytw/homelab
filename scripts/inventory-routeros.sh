#!/usr/bin/env bash
set -euo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="diagnostics/${ts}/routeros"
mkdir -p "$out"
control="$out/ssh-control"
ssh_args=(-o BatchMode=yes -o ConnectTimeout=5 -o ControlMaster=auto -o ControlPersist=60 -o ControlPath="$control" router)
close_control() { ssh -o ControlPath="$control" -O exit router >/dev/null 2>&1 || true; }
trap close_control EXIT

run() {
  local name="$1"
  local cmd="$2"
  timeout 20 ssh "${ssh_args[@]}" "$cmd" >"${out}/${name}.txt"
}

run resource "/system resource print"
run packages "/system package print"
run addresses "/ip address print detail"
run pools "/ip pool print detail"
run dhcp_servers "/ip dhcp-server print detail"
run dhcp_networks "/ip dhcp-server network print detail"
run dhcp_leases "/ip dhcp-server lease print detail"
run managed_lease_ids "/ip dhcp-server lease print show-ids detail where mac-address=F8:E4:3B:54:E7:03 or mac-address=52:54:00:D4:BD:37"
run dns "/ip dns print"
run bridges "/interface bridge print detail; /interface bridge port print detail"
run veth "/interface veth print"
run containers "/container print; /container config print; /container mounts print"
run disks "/disk print; /file print where name~\"usb|adguard\""
run firewall_filter "/ip firewall filter print"
run firewall_nat "/ip firewall nat print"
run wireguard "/interface wireguard print; /interface wireguard peers print"
run services "/ip service print detail"
run https_rest "/ip service print detail where name=\"www-ssl\""
run certificates "/certificate print detail without-paging"

close_control
trap - EXIT
echo "$out"
