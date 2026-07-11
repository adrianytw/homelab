# Home Assistant Bridge Migration

## Purpose

Replace Home Assistant's direct/macvtap attachment with a host bridge so LAN clients and `nmac` can both reach the VM. This is a local-console maintenance procedure; it does not change RouterOS.

## Observed State

- Physical interface: `enu1u1c2`
- Active NetworkManager profile: `Wired connection 2`
- Profile UUID: `2c145c77-880e-36a9-a419-55d1df2f951e`
- Host MAC: `F8:E4:3B:54:E7:03`
- Addressing: DHCP, currently `192.168.88.20/24`
- IPv6 method: NetworkManager `auto`
- Gateway and DNS: `192.168.88.1`
- HA interface: direct/macvtap, MAC `52:54:00:D4:BD:37`, lease `192.168.88.84`

The bridge must present the host's current MAC. RouterOS identifies the `.20` reservation by that MAC.

## Prerequisites

- `HA-BRIDGE` is approved and a person is at the local console.
- `HOST-SUDO` is available for the maintenance window.
- Home Assistant backup is current, or the risk of a network-only XML change is explicitly accepted.
- The inactive production XML and NetworkManager profile properties are captured before mutation.
- No RouterOS, firewall, k3s, storage, or package change shares this window.
- Keep this runbook available locally; SSH is expected to disconnect.

## Preflight And Evidence

Run at the local console. Stop if any observed value differs from the table above.

```bash
set -euo pipefail
umask 077
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SAVE="$HOME/ha-bridge-$STAMP"
install -d -m 0700 "$SAVE"

nmcli -f connection.id,connection.uuid,connection.type,connection.interface-name,802-3-ethernet.cloned-mac-address,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv6.method connection show "Wired connection 2"
nmcli -f GENERAL.CONNECTION,GENERAL.DEVICE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show enu1u1c2
ip route show
sudo virsh domstate haos
sudo virsh domiflist haos --inactive
sudo virsh dumpxml haos --inactive >"$SAVE/haos-before.xml"
sudo virsh net-list --all >"$SAVE/libvirt-networks.txt"
nmcli connection show "Wired connection 2" >"$SAVE/Wired-connection-2.txt"
sudo find /etc/NetworkManager/system-connections -maxdepth 1 -type f \
  -exec grep -lF 'uuid=2c145c77-880e-36a9-a419-55d1df2f951e' {} + \
  | sudo xargs -r -I{} cp --preserve=mode,timestamps {} "$SAVE/"
sudo chown -R "$(id -u):$(id -g)" "$SAVE"
chmod -R u=rwX,go= "$SAVE"
sha256sum "$SAVE"/* >"$SAVE/SHA256SUMS"
```

Before proceeding, verify the inactive XML contains one direct interface with HA MAC `52:54:00:d4:bd:37` and source device `enu1u1c2`. Do not edit production XML by hand.

## Staged Change

Create profiles without activating them. The bridge inherits DHCP and the physical MAC; the port carries no IP configuration.

```bash
sudo nmcli connection add type bridge ifname br0 con-name br0 \
  bridge.mac-address F8:E4:3B:54:E7:03 \
  ipv4.method auto ipv6.method auto \
  connection.autoconnect no connection.autoconnect-slaves 1

sudo nmcli connection add type ethernet ifname enu1u1c2 con-name br0-port-enu1u1c2 \
  controller br0 port-type bridge \
  ipv4.method disabled ipv6.method disabled \
  connection.autoconnect no

nmcli connection show br0
nmcli connection show br0-port-enu1u1c2
```

Verify exactly one saved `.nmconnection` file contains the expected UUID. If NetworkManager rejects `bridge.mac-address`, `controller`, or `port-type`, stop and record `nmcli --version` plus `nmcli connection add help`; do not improvise alternative properties during the window.

## Activation

This will interrupt SSH. Run only at the local console.

```bash
sudo nmcli connection modify br0 connection.autoconnect yes
sudo nmcli connection modify br0-port-enu1u1c2 connection.autoconnect yes
sudo nmcli connection modify "Wired connection 2" connection.autoconnect no
test "$(nmcli -g connection.autoconnect connection show br0)" = yes
test "$(nmcli -g connection.autoconnect connection show br0-port-enu1u1c2)" = yes
test "$(nmcli -g connection.autoconnect connection show "Wired connection 2")" = no
sudo nmcli connection down "Wired connection 2"
sudo nmcli connection up br0
```

Immediately validate host networking before touching the VM:

```bash
ip -brief address show | grep -E '^(br0|enu1u1c2)[[:space:]]'
ip route show
nmcli -f GENERAL.CONNECTION,GENERAL.DEVICE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show br0
ping -c 3 -W 2 192.168.88.1
getent hosts example.com
```

The bridge must own `192.168.88.20/24`, default route and DNS must remain `192.168.88.1`, and `enu1u1c2` must be a bridge port without an IP address. Roll back immediately if these gates fail.

## VM Migration

Gracefully stop Home Assistant. Do not use `virsh destroy`.

```bash
sudo virsh shutdown haos
for _ in {1..60}; do
  [[ "$(sudo virsh domstate haos | xargs)" = "shut off" ]] && break
  sleep 5
done
test "$(sudo virsh domstate haos | xargs)" = "shut off"

sudo virsh detach-interface haos direct --config --mac 52:54:00:d4:bd:37
sudo virsh attach-interface haos bridge br0 --model virtio \
  --mac 52:54:00:d4:bd:37 --config
sudo virsh domiflist haos --inactive
sudo virsh start haos
```

Stop if the direct interface is not uniquely identified by that MAC. The reviewed target is exactly one bridge interface on `br0`, with the existing HA MAC.

## Validation

- `nmac` remains at `192.168.88.20`; LAN DNS and gateway remain `192.168.88.1`.
- A second LAN client and `nmac` can reach `192.168.88.84:8123`.
- HA boots normally, autostart remains enabled, and USB `10c4:ea70` serial `00C3A38C` is present.
- `sudo virsh domiflist haos --inactive` shows `bridge` / `br0` and the original HA MAC.
- Reboot validation is a separate `HOST-REBOOT` approval; do not claim persistence proof before it occurs.

Record the before/after XML, NetworkManager profile output, reachability results, and decision in the recovery command log without secrets.

## Rollback

If host networking fails, use the local console:

```bash
sudo nmcli connection down br0 || true
sudo nmcli connection modify br0 connection.autoconnect no
sudo nmcli connection modify br0-port-enu1u1c2 connection.autoconnect no
sudo nmcli connection modify "Wired connection 2" connection.autoconnect yes
sudo nmcli connection up "Wired connection 2"
```

Confirm `.20`, gateway, DNS, and RouterOS reachability before removing staged profiles. Preserve them until the incident is understood.

If only HA networking fails while host networking on `br0` is healthy, leave the VM attached to `br0` and diagnose it from the local console. Do not restore direct/macvtap XML while the physical interface is a bridge port.

To restore the old HA XML, first restore host networking as above and confirm `enu1u1c2` owns `.20`. Then gracefully stop `haos` and restore the captured inactive XML:

```bash
SAVE="$HOME/ha-bridge-<preflight-timestamp>"
test -f "$SAVE/haos-before.xml"
sudo virsh shutdown haos
for _ in {1..60}; do
  [[ "$(sudo virsh domstate haos | xargs)" = "shut off" ]] && break
  sleep 5
done
test "$(sudo virsh domstate haos | xargs)" = "shut off"
sudo virsh define "$SAVE/haos-before.xml"
sudo virsh start haos
```

Do not delete `br0`, the old profile, or captured evidence until both host and HA validation pass.
