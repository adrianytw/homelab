# k3s Firewall And Proof

## Purpose

Inventory and review the `nmac` host firewall, install the prepared pinned k3s release, and prove storage, networking, ingress, and rollback without exposing services beyond the flat LAN. WireGuard reaches the LAN through RouterOS; this procedure does not change RouterOS.

## Prerequisites

- `HOST-SUDO`, `HOST-FIREWALL`, and a maintenance window are approved.
- `make ansible-storage` has completed twice; the second run reports no changes.
- `/srv/data/k3s-storage` exists with reviewed ownership, permissions, capacity, and SELinux context.
- Ports `80`, `443`, and `6443` have no existing listeners.
- The HA bridge migration is either complete or explicitly scheduled separately; do not combine it with this change.
- A second LAN session is available to verify that SSH and Cockpit remain reachable.
- No RouterOS firewall, DNS, DHCP, WireGuard, or container-network change is included.

## Privileged Firewall Inventory

Capture this before proposing commands. Existing zone assignments and rich/direct policies are authoritative; do not assume `FedoraWorkstation` is the final zone.

```bash
set -euo pipefail
umask 077
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SAVE="$HOME/k3s-firewall-$STAMP"
install -d -m 0700 "$SAVE"

sudo firewall-cmd --state | tee "$SAVE/state.txt"
sudo firewall-cmd --get-active-zones | tee "$SAVE/active-zones.txt"
sudo firewall-cmd --get-default-zone | tee "$SAVE/default-zone.txt"
sudo firewall-cmd --get-policies | tee "$SAVE/policies.txt"
sudo firewall-cmd --list-all-zones | tee "$SAVE/all-zones.txt"
sudo firewall-cmd --direct --get-all-rules | tee "$SAVE/direct-rules.txt"
sudo nft list ruleset >"$SAVE/nft-ruleset.txt"
ss -lntup >"$SAVE/listeners-before.txt"
ip -brief address >"$SAVE/addresses.txt"
ip route >"$SAVE/routes.txt"
sha256sum "$SAVE"/*.txt >"$SAVE/SHA256SUMS"
```

Human review must identify:

- the zone bound to the LAN-facing interface or `br0` after HA migration;
- how SSH `22/tcp` and Cockpit `9090/tcp` are currently allowed;
- any broad high-port services, source ports, rich rules, policies, or direct/nft rules;
- whether traffic from RouterOS-routed WireGuard clients arrives with source `192.168.36.0/24`;
- conflicts on k3s defaults: pod CIDR `10.42.0.0/16` and service CIDR `10.43.0.0/16`.

Do not create permanent rules until this inventory is attached to `HOST-FIREWALL` and reviewed. A final ruleset must preserve established SSH and Cockpit access, allow k3s overlay/service traffic needed on the node, and limit ingress/API exposure to approved sources.

## Firewall Go/No-Go Gate

The reviewed ticket must contain the exact runtime `firewall-cmd` commands and their exact inverse commands. Apply runtime rules before installing k3s, then verify them with `firewall-cmd --list-all`/`--list-rich-rules` from the selected zone and connectivity tests from one approved and one unapproved source. Do not start k3s while relying only on a future permanent rule.

After k3s validation, convert the tested runtime rules to permanent form using the same reviewed definitions, run `firewall-cmd --check-config`, reload only during the approved window, and repeat every access test. If the review cannot identify the active zone, source behavior, or inverse commands, this lane remains blocked.

## Install

After the firewall review is resolved and its runtime restrictions pass the go/no-go gate, execute the already-reviewed automation from the repository root:

```bash
make ansible-check
make ansible-storage
make ansible-storage
make ansible-k3s
```

The playbook pins k3s `v1.36.2+k3s1`, verifies ARM64, configures local-path storage at `/srv/data/k3s-storage`, retains Traefik and ServiceLB defaults, and waits for node readiness. Do not run the upstream install script manually.

## Runtime Validation

Run on `nmac`:

```bash
sudo systemctl --no-pager --full status k3s
sudo k3s kubectl get nodes -o wide
sudo k3s kubectl get pods -A -o wide
sudo k3s kubectl get storageclass
sudo k3s kubectl get ingressclass
sudo k3s kubectl get services -A
sudo k3s crictl info
ss -lntup | grep -E ':(80|443|6443)\b'
sudo journalctl -u k3s -b --no-pager | tail -n 200
```

From an approved LAN client, `6443` must be reachable only if that client is intentionally allowed. From an unapproved source, verify it is denied. Do not expose kubeconfig contents or copy `/etc/rancher/k3s/k3s.yaml` into Git.

## Test Workload

From the workstation repository root, copy only the digest-pinned workload, then run the remaining commands in an attended SSH session:

```bash
scp cluster/platform/test-workload.yaml nmac:/tmp/homelab-test-workload.yaml
ssh -t nmac
sudo k3s kubectl apply -f /tmp/homelab-test-workload.yaml
sudo k3s kubectl -n homelab-test rollout status deployment/web --timeout=180s
sudo k3s kubectl -n homelab-test get all,pvc,ingress -o wide
sudo k3s kubectl -n homelab-test exec deploy/web -- test -f /data/index.html
curl --fail --show-error --resolve test.k8s.nairdev.com:80:192.168.88.20 \
  http://test.k8s.nairdev.com/
```

This direct `--resolve` check proves ingress without changing DNS. The AdGuard rewrite is a later reviewed OpenTofu apply; do not add it manually here.

## Validation

- Node `nmac` is `Ready`; system pods are healthy.
- containerd/CRI, CNI, CoreDNS, Traefik, ServiceLB, and local-path provisioning work.
- The test pod serves the expected response through Traefik and its PVC is bound under `/srv/data/k3s-storage`.
- LAN/WireGuard source restrictions for `80`, `443`, and `6443` match the reviewed firewall evidence.
- SSH and Cockpit still work from a second session.
- A second Ansible k3s run reports no changes before idempotence is accepted.
- Reboot recovery remains unproven until `HOST-REBOOT` is separately approved and completed.

## Rollback

Remove only the test workload first:

```bash
sudo k3s kubectl delete -f /tmp/homelab-test-workload.yaml --wait=true
```

If k3s must be removed, capture logs and resource state, then run its installed uninstall script only after explicit approval:

```bash
SAVE="$HOME/k3s-firewall-<inventory-timestamp>"
test -d "$SAVE"
sudo k3s kubectl get all,pvc,ingress -A -o wide
sudo journalctl -u k3s -b --no-pager >"$SAVE/k3s-journal.txt"
sudo /usr/local/bin/k3s-uninstall.sh
```

Preserve `/srv/data`; do not recursively delete k3s storage during rollback. Restore firewall configuration using the reviewed, recorded inverse operations rather than replacing the whole ruleset. Verify SSH, Cockpit, HA, DNS through `192.168.88.1`, and ordinary LAN access after rollback.
