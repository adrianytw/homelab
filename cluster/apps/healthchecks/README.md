# Healthchecks

Internal cron-job monitoring at `https://health.ops.nairdev.com`, using the
official ARM64 image, SQLite on a local-path PVC, and SOPS-encrypted credentials.

An idempotent init container migrates the database, maintains the `Homelab`
project and superuser, removes only a sole empty bootstrap-default project, and
provisions these stable slug-based checks in the `America/Chicago` timezone:

| Check | Schedule | Grace | State |
| --- | --- | --- | --- |
| `k3s-app-backups` | daily 03:15 | 60 minutes | active |
| `adguard-config-backup` | daily 03:45 | 60 minutes | active |
| `routeros-backup` | Sunday 04:15 | 60 minutes | paused |
| `ha-backup-freshness` | daily 05:00 | 120 minutes | active |

The RouterOS check remains paused until its binary-backup password can be
provided non-interactively without plaintext storage. The AdGuard job is active
because public-key RouterOS SSH and its zero-downtime encrypted configuration
export are proven. The SOPS-encrypted ping key is 22 random lowercase
alphanumeric characters and never appears in a ConfigMap.

The bootstrap also assigns one webhook integration to the four checks. It reads
`healthchecks-admin`, `healthchecks-ping-key`, and topic-limited
`ntfy-publisher` Secrets, builds the ntfy Basic authorization header only in
memory, and posts down/recovery events to the internal `homelab-alerts` topic.
Healthchecks stores that webhook record in its SQLite database, so backups of
the PVC remain sensitive. Private integration access is enabled only to reach
the in-cluster ntfy Service.

Kustomize hashes the generated bootstrap ConfigMap name, so script changes roll
the Deployment and rerun the bootstrap. When any referenced Secret rotates,
increment `homelab.nairdev.com/credentials-revision` on the pod template so the
init container applies the new credentials immediately.
