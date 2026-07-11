#!/usr/bin/env bash
set -euo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="diagnostics/${ts}/nmac"
mkdir -p "$out"

control="$out/ssh-control"
ssh_args=(-o BatchMode=yes -o ConnectTimeout=5 -o ControlMaster=auto -o ControlPersist=60 -o ControlPath="$control" nmac)
remote() { timeout 20 ssh "${ssh_args[@]}" "$1"; }
close_control() { ssh -o ControlPath="$control" -O exit nmac >/dev/null 2>&1 || true; }
trap close_control EXIT

remote 'hostnamectl; uname -a; id' >"${out}/host.txt"
remote 'ip -br addr; ip -d link; ip route; nmcli connection show; nmcli device show; findmnt -R /srv || true; df -hT / /srv/data 2>&1 || true; lsblk -o NAME,SIZE,FSTYPE,FSAVAIL,FSUSE%,MOUNTPOINTS; ls -la /srv || true' >"${out}/storage-network.txt"
remote 'if sudo -n true 2>/dev/null; then echo "privilege: non-interactive sudo available"; sudo -n firewall-cmd --state 2>&1 || true; sudo -n firewall-cmd --get-active-zones 2>&1 || true; sudo -n firewall-cmd --list-all-zones 2>&1 || true; else echo "privilege: unavailable; firewalld configuration not inventoried"; firewall-cmd --state 2>&1 || true; fi' >"${out}/firewalld.txt"
remote 'command -v k3s || true; k3s --version 2>/dev/null || true; systemctl list-unit-files "k3s*" --no-pager || true' >"${out}/k3s.txt"
remote 'systemctl is-active cockpit.socket; systemctl is-enabled cockpit.socket; systemctl is-active libvirtd virtqemud 2>/dev/null || true; systemctl is-enabled libvirtd virtqemud 2>/dev/null || true' >"${out}/services.txt"
remote 'ss -lntp "( sport = :80 or sport = :443 or sport = :6443 )" 2>&1 || true' >"${out}/listeners.txt"
remote 'printf "enforce="; cat /sys/fs/selinux/enforce 2>/dev/null || echo unavailable; ls -Zd /srv /srv/data 2>&1 || true' >"${out}/selinux.txt"
remote 'systemctl get-default; systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target 2>&1 || true; systemd-analyze cat-config systemd/logind.conf 2>&1 || true' >"${out}/power.txt"
remote 'virsh -c qemu:///system list --all; virsh -c qemu:///system dominfo haos 2>/dev/null || true; virsh -c qemu:///system domiflist haos 2>/dev/null || true; virsh -c qemu:///system domblklist haos --details 2>/dev/null || true; virsh -c qemu:///system dumpxml --inactive haos 2>/dev/null || true; for disk in $(virsh -c qemu:///system domblklist haos --details 2>/dev/null | awk '"'"'$2 == "disk" {print $3}'"'"'); do virsh -c qemu:///system domblkinfo haos "$disk" 2>/dev/null || true; done' >"${out}/libvirt.txt"
remote 'lsusb; lsusb -d 10c4:ea70 -v 2>/dev/null | sed -n "1,120p"' >"${out}/usb.txt"

close_control
trap - EXIT
echo "$out"
