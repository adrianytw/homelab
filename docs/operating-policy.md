# Operating Policy

## Safety Gates

- Back up and export RouterOS before DHCP, DNS, firewall, WireGuard, or container-network changes.
- Import and review RouterOS firewall/WireGuard before OpenTofu manages them.
- Do not let OpenTofu destroy or recreate the Home Assistant VM without explicit approval.
- Do not enable Flux until manual manifests are proven.
- Do not treat stateful apps as protected until off-host backup and restore tests exist.
- Do not deploy Vault until SOPS/age and backup/restore are proven.

## Secrets

- Commit only SOPS-encrypted secrets.
- Never commit plaintext API tokens, SSH keys, age keys, kubeconfigs, or OpenTofu state.
- Store local bootstrap values in ignored `.env` or shell environment.
- Cloudflare token must be zone-scoped for `nairdev.com`; no global API key.

## Exposure

- LAN/VPN only by default.
- No WAN port forwards for new services.
- Public Let's Encrypt certificates are allowed through DNS-01; public app DNS records are not.
- Cockpit stays direct on port `9090`, not through k3s ingress initially.

## Backups

Temporary local backup path: `~/homelab-backups`.

Minimum before OCI:

- Git repo in GitHub and mirror.
- RouterOS binary backup and text export.
- AdGuard export.
- Encrypted SOPS age key recovery bundle.
- Encrypted, Git-ignored OpenTofu state backup.
- Critical `/srv/data` archives when possible.
- Home Assistant VM backup/export.

Restore order:

1. RouterOS baseline.
2. DHCP and DNS.
3. MacBook host bootstrap.
4. `/srv/data` restore.
5. Home Assistant VM restore if applicable.
6. k3s install.
7. SOPS age key restore.
8. Flux reconciliation.
9. Core service validation.
10. Observability validation.
11. Backup and alert validation.

Retention target once off-host backups exist:

| Frequency | Retention |
| --- | --- |
| hourly | Optional critical app dumps only, last 24 hours |
| daily | 7 days |
| weekly | 4 weeks |
| monthly | 6 months |

Before OCI exists, keep fewer local encrypted snapshots to avoid filling the MacBook SSD.

First restore test:

- Restore one low-risk app from `/srv/data`, such as Glance or Uptime Kuma.
- After Postgres/Paperless exists, restore one critical app database dump.

Stateful apps, Home Assistant, SOPS, and Flux are not protected until both off-host backup and restore test pass.
