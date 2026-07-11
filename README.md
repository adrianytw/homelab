# Homelab

Reproducible, recoverable single-node homelab: MikroTik RouterOS owns the LAN edge and client DNS, AdGuard runs on the router, `nmac` owns k3s workloads, and Home Assistant remains a libvirt VM.

## Current State

| Area | State |
| --- | --- |
| Router baseline | Backed up, reviewed, and safely applied |
| DHCP and DNS | `nmac` and Home Assistant reserved; clients use `192.168.88.1`; RouterOS forwards to AdGuard at `10.0.0.2` |
| MacBook | Fedora Asahi at `192.168.88.20`; storage and k3s not yet applied |
| Home Assistant | `haos` VM at `192.168.88.84`; backup and host-reachability work pending |
| OpenTofu | Independent RouterOS and AdGuard roots scaffolded; no resources imported |
| Recovery | Runbooks exist; age/SOPS bootstrap, off-host copies, and restore proof pending |
| Kubernetes | Not installed; manual proof precedes Flux |

## Delivery Order

```text
Repository baseline
├── OpenTofu: encrypted state → secure API → imports → zero-diff plans ─┐
├── Ansible: storage → HA network → host prerequisites → k3s          ├── DNS/TLS proof
└── Recovery: backups → age/SOPS → restore proof                       ┘
                                                                         ↓
                                                               core apps → Flux
```

OpenTofu, host preparation, and recovery may progress independently. Device changes still require their documented safety gates.

## Checklist

### Source of truth

- [x] Document the goal, current state, dependency graph, and delivery checklist.
- [x] Forbid `*.nairdev.com`; use exact names or verified homelab-only subzones.
- [x] Treat `adguard.nairdev.com` routing as unverified until an HTTPS UI path is proven.
- [ ] Commit only intentional homelab files, excluding unrelated `.codex` tooling.
- [ ] Run checks and a secret scan, create the baseline commit, push `origin`, and create `~/homelab-backups/git/homelab.git`.

### OpenTofu first

- [x] Install OpenTofu `1.12.x` on the current computer.
- [x] Keep independent state in `opentofu/routeros` and `opentofu/adguard`.
- [x] Pin RouterOS provider `1.99.1` and AdGuard provider `1.7.0`.
- [x] Require PBKDF2/AES-GCM state and plan encryption via `TF_VAR_state_passphrase`.
- [x] Commit provider lock files after `tofu init`.
- [ ] Take fresh RouterOS and AdGuard backups before imports.
- [ ] With explicit approval, configure a RouterOS-local TLS certificate and trusted `ROS_CA_CERTIFICATE`; never use plaintext API `8728`.
- [ ] Import the `nmac` and Home Assistant leases individually, recording IDs in `opentofu/routeros/imports.md`; require a zero-diff detailed plan after each.
- [ ] Inventory and import AdGuard rewrites individually, then its singleton DNS configuration, recording IDs in `opentofu/adguard/imports.md`.
- [ ] Copy encrypted state to `~/homelab-backups/opentofu/<timestamp>/` after every successful import/apply.
- [ ] After ingress exists, make the first apply add only `test.k8s.nairdev.com -> 192.168.88.20`.

### Host and recovery

- [ ] Run `make ansible-storage` twice; the second run must report no changes.
- [ ] Verify `/srv/data`, `/srv/data/k3s-storage`, capacity, ownership, and permissions.
- [ ] Export Home Assistant XML and make a consistent disk backup.
- [ ] In a console maintenance window, make Home Assistant reachable from both LAN clients and `nmac`; verify boot, `.84`, USB `10c4:ea70`, port `8123`, and autostart.
- [ ] Add only currently needed host and k3s prerequisites to Ansible.
- [ ] Bootstrap age/SOPS, keep the private key outside Git in an encrypted recovery bundle, and record the accepted unencrypted `/srv/data` risk.
- [ ] Create encrypted off-host copies of RouterOS/AdGuard, Home Assistant, Git, and OpenTofu state.

### k3s, TLS, apps, and GitOps

- [ ] Install a pinned stable ARM64 k3s release through Ansible; keep Traefik and ServiceLB and restrict `80`, `443`, and `6443` to LAN/WireGuard.
- [ ] Prove node readiness, storage at `/srv/data/k3s-storage`, ingress, reboot recovery, and one pinned test workload.
- [ ] Add and verify the test AdGuard rewrite with the reviewed OpenTofu plan.
- [ ] Install cert-manager manually; prove exact-name staging then production certificates using a zone-only Cloudflare token stored with SOPS.
- [ ] Confirm no public A/AAAA records or WAN forwards exist.
- [ ] Restore one encrypted low-risk backup before deploying stateful apps.
- [ ] Deploy Glance, Uptime Kuma, ntfy, and Healthchecks manually; add Prometheus/Grafana, and Loki only if measured need exists.
- [ ] Bootstrap Flux only after manifests, restart recovery, SOPS decryption, and age-key recovery are proven.

Expansion remains gated on restore proof. Paperless, Actual, and Forgejo come next; firewall/WireGuard imports and all deferred services require separate reviewed work.

## Safe Commands

```sh
make check
make inventory-router
make inventory-nmac
make inventory
```

Inventory commands are read-only and write ignored, timestamped files under `diagnostics/`. There is intentionally no generic apply target.

## Non-Negotiable Rules

- No RouterOS firewall, WireGuard, DHCP, DNS, certificate, or container-network changes without a fresh backup/export, review, and explicit approval.
- No destructive OpenTofu plan or unreviewed replacement.
- Keep services LAN/VPN-only; public certificates do not imply public exposure.
- Ansible must be idempotent; k3s and Home Assistant must recover after reboot.
- Never commit plaintext state, tokens, age keys, SSH keys, kubeconfigs, backups, or OpenTofu plans.
- Restore order is RouterOS → host → data → Home Assistant → k3s → age → Flux.

See `docs/architecture.md`, `docs/operating-policy.md`, and `docs/ip-plan.md` for the compact source of truth. The original design prompt in `docs/reference/` is historical context when it conflicts with those files.
