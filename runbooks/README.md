# Runbooks

Every runbook needs: purpose, prerequisites, validation, rollback.

Recover in dependency order: RouterOS, host, `/srv/data`, Home Assistant, k3s,
age, then Flux. Restore monitoring only after those dependencies are healthy.

Review-gated execution packets include `home-assistant-bridge-migration.md` and `k3s-firewall-proof.md`. Their presence is not approval to run live changes.

Monitoring validation and recovery are documented in `monitoring-recovery.md`.

Template:

```md
## Purpose
## Prerequisites
## Validation
## Rollback
```
