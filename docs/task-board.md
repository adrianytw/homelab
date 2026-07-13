# Task Board

Updated `2026-07-13`. A blocked task stops only its lane; see `human-review.md` for the decision or credential required.

| ID | Lane | Status | Next action |
| --- | --- | --- | --- |
| REPO-BASELINE | repository | done | GitHub, local Git, the bare mirror, and live Flux were proven current before reliability hardening. |
| REPO-CHECKS | repository | done | Shell fixtures, Kustomize renders, Prometheus validation, encrypted-manifest checks, and secret scan pass. |
| REPO-SYNC | repository | done | GitHub and the bare mirror are synchronized; all six application Kustomizations and deployments are Ready at current `main`. |
| TF-ROOTS | OpenTofu | done | RouterOS and AdGuard roots are independently pinned and encrypted. |
| TF-STATE-BACKUP | OpenTofu | done | Helper passes encrypted fixture, mode, checksum, commit-ID, and plaintext-rejection checks; no live state exists. |
| TF-ROUTER-INVENTORY | OpenTofu | done | IDs `*1AB0`/`*1AB7`, trusted local CA, and REST on `www-ssl:8443` are verified. |
| TF-ROUTER-TLS | OpenTofu | done | Trusted CA and IP-SAN REST certificate are live; plaintext API remains disabled. |
| TF-ROUTER-IMPORT | OpenTofu | blocked | Requires least-privilege credentials and state-passphrase custody; fresh backup exists. |
| TF-ADGUARD-IMPORT | OpenTofu | blocked | Trusted HTTPS and config backup exist; full ownership choice and provider credentials remain. |
| HOST-INVENTORY | host | done | Fresh read-only inventory recorded; per-command timeout and SSH connection reuse prevent hangs. |
| HOST-STORAGE | host | done | `/srv/data` and local-path PVC storage are live and exercised by encrypted backups. |
| HOST-FIREWALL-AUDIT | host | blocked | Privileged rule inventory still requires attended sudo/local-console access. |
| HA-BACKUP | recovery | partial | Fresh encrypted outer bundle/checksum exists; decryption, qcow2 checks, and isolated boot remain attended. |
| HA-BRIDGE | recovery | done | `br0` carries host and HA VM; `.20`, `.84`, HTTP 200, libvirt running, and autostart are verified. |
| SECRETS-TOOLS | recovery | done | Pinned age, checksum-verified SOPS, and kubectl are installed user-locally without sudo. |
| SECRETS-BOOTSTRAP | recovery | done | SOPS age key, encrypted application secrets, Flux decryption, and recovery documentation are live. |
| K3S-AUTOMATION | cluster | done | Pinned `v1.36.2+k3s1`, storage, Traefik, and digest-pinned test workload are live. |
| K3S-FIREWALL-PACKET | cluster | done | Privileged inventory, decision gates, validation, and rollback are documented; no firewall change ran. |
| K3S-PROOF | cluster | done | Node, storage, ingress, workload, Flux drift repair, app recovery, and reboot recovery are proven. |
| DNS-TLS-PROOF | network | done | Private rewrites and exact-name production certificates work without public A/AAAA records or WAN forwards. |
| CORE-APPS | apps | done | Six core applications passed TLS, auth, persistence, and reboot checks. |
| FLUX | GitOps | done | Reconciliation, suspension/resume, drift repair, SOPS, and reboot recovery were proven. |
| MAINTENANCE-HELPER | reliability | done | Root-owned wrapper, validated sudoers rule, allowlist, argument rejection, and transient rollback are installed and proven. |
| ALERT-DELIVERY | reliability | done | Guarded selector drift produced fresh firing and resolved ntfy messages; Flux repaired the target and all three scrapes recovered. |
| APP-BACKUPS | reliability | done | Six encrypted app archives, atomic validation, SQLite checks, and the eleven-monitor Uptime Kuma gate pass. |
| BACKUP-SCHEDULE | reliability | done | Idempotent off-host cron runs daily application and AdGuard backups, weekly RouterOS backups, and daily HA freshness checks; all four Healthchecks checks are up. |
| PLATFORM-MONITORING | reliability | done | Prometheus has 10/10 targets and 13/13 healthy rules; Uptime has eleven healthy desired monitors; Glance has nine; all three Grafana dashboards are provisioned. |
| RELIABILITY-REBOOT | reliability | done | SSH loss/recovery, host services, cert-manager retry, Flux, apps, monitoring, Grafana, and Home Assistant recovered. |
| EXPANSION | apps | deferred | Loki, Scrutiny, NetAlertX, Paperless, Actual, and Forgejo wait for critical restore proof or measured need. |
| VAULT | security | deferred | Reserve `vault.nairdev.com`; deploy only for a concrete runtime-secrets consumer. |
