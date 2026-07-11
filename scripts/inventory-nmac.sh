#!/usr/bin/env bash
set -euo pipefail

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="diagnostics/${ts}/nmac"
mkdir -p "$out"

ssh nmac "hostnamectl; uname -a; id" >"${out}/host.txt"
ssh nmac "ip -br addr; findmnt -R /srv || true; df -h / /srv/data 2>&1 || true; ls -la /srv || true" >"${out}/storage-network.txt"
ssh nmac "firewall-cmd --state 2>&1 || true; firewall-cmd --get-active-zones 2>&1 || true; firewall-cmd --list-all 2>&1 || true" >"${out}/firewalld.txt"
ssh nmac "command -v k3s || true; k3s --version 2>/dev/null || true; systemctl list-unit-files 'k3s*' --no-pager || true" >"${out}/k3s.txt"
ssh nmac "systemctl is-active cockpit.socket; systemctl is-enabled cockpit.socket; systemctl is-active libvirtd virtqemud 2>/dev/null || true; systemctl is-enabled libvirtd virtqemud 2>/dev/null || true" >"${out}/services.txt"
ssh nmac "virsh -c qemu:///system list --all; virsh -c qemu:///system dominfo haos 2>/dev/null || true; virsh -c qemu:///system domiflist haos 2>/dev/null || true; virsh -c qemu:///system domblklist haos --details 2>/dev/null || true" >"${out}/libvirt.txt"
ssh nmac "lsusb; lsusb -d 10c4:ea70 -v 2>/dev/null | sed -n '1,120p'" >"${out}/usb.txt"

echo "$out"
