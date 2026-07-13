# Task Board

Updated `2026-07-13`. A blocked task stops only its lane; see `human-review.md` for the decision or credential required.

| ID | Lane | Status | Next action |
| --- | --- | --- | --- |
| REPO-BASELINE | repository | done | GitHub, local Git, the bare mirror, and live Flux were proven current before reliability hardening. |
| REPO-CHECKS | repository | done | Subsystem logs, ledgers, shell tests, Ansible syntax, OpenTofu format/validation, YAML parse, and secret scan pass. |
| REPO-COMMIT | repository | done | Verified work is synchronized across local Git, GitHub, the bare mirror, and Flux. |
| TF-ROOTS | OpenTofu | done | RouterOS and AdGuard roots are independently pinned and encrypted. |
| TF-STATE-BACKUP | OpenTofu | done | Helper passes encrypted fixture, mode, checksum, commit-ID, and plaintext-rejection checks; no live state exists. |
| TF-ROUTER-INVENTORY | OpenTofu | done | IDs `*1AB0`/`*1AB7`; no certificates; `www-ssl:443` is restricted with certificate `none`. |
| TF-ROUTER-TLS | OpenTofu | blocked | Prepare review packet; live change waits on `ROS-BACKUP`, `ROS-TLS`, and credentials. |
| TF-ROUTER-IMPORT | OpenTofu | blocked | Requires trusted REST, state-passphrase custody, credentials, and fresh backup. |
| TF-ADGUARD-IMPORT | OpenTofu | blocked | Requires verified HTTPS endpoint, recovery export, full rewrite inventory, and credentials. |
| HOST-INVENTORY | host | done | Fresh read-only inventory recorded; per-command timeout and SSH connection reuse prevent hangs. |
| HOST-STORAGE | host | blocked | Playbook will cover only current directories; apply waits on `HOST-SUDO`. |
| HA-BACKUP | recovery | blocked | Procedure can be documented; live backup needs downtime, sudo, and age custody. |
| HA-BRIDGE | recovery | blocked | Exact observed-profile migration and rollback packet is prepared; requires local console, sudo, XML verification, and approval. |
| SECRETS-TOOLS | recovery | done | Pinned age, checksum-verified SOPS, and kubectl are installed user-locally without sudo. |
| SECRETS-BOOTSTRAP | recovery | blocked | Requires `AGE-CUSTODY`. |
| K3S-AUTOMATION | cluster | done | Pinned `v1.36.2+k3s1` playbook and digest-pinned test workload prepared; not applied. |
| K3S-FIREWALL-PACKET | cluster | done | Privileged inventory, decision gates, validation, and rollback are documented; no firewall change ran. |
| K3S-PROOF | cluster | blocked | Execution packet is prepared; requires storage, sudo, privileged firewall review, and maintenance window. |
| DNS-TLS-PROOF | network | blocked | Requires k3s proof, AdGuard import, Cloudflare token, and separate DNS approval. |
| CORE-APPS | apps | done | Six core applications passed TLS, auth, persistence, and reboot checks. |
| FLUX | GitOps | done | Reconciliation, suspension/resume, drift repair, SOPS, and reboot recovery were proven. |
| MAINTENANCE-HELPER | reliability | done | Root-owned wrapper, validated sudoers rule, allowlist, argument rejection, and transient rollback are installed and proven. |
| ALERT-DELIVERY | reliability | done | Guarded selector drift produced fresh firing and resolved ntfy messages; Flux repaired the target and all three scrapes recovered. |
| APP-BACKUPS | reliability | done | Six `0700` backup sets, encrypted `0600` archives, checksums, listings, SQLite checks, and seven-monitor Uptime Kuma restore passed. |
| RELIABILITY-REBOOT | reliability | done | SSH loss/recovery, host services, cert-manager retry, Flux, apps, monitoring, Grafana, and Home Assistant recovered. |
| VAULT | security | deferred | Reserve `vault.nairdev.com`; deploy only for a concrete runtime-secrets consumer. |
