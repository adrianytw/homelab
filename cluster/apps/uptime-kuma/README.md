# Uptime Kuma

Internal monitoring UI at `https://status.nairdev.com`. Uptime Kuma `2.4.0`
uses the digest-pinned Linux ARM64 rootless image, SQLite single-connection mode,
and a local-path PVC mounted at `/app/data`.

The SOPS-encrypted admin credential is retained for recovery. Never mount a
container-runtime socket. Stop the deployment before backing up or restoring
the SQLite data.

The one-shot setup Job idempotently adds checks for each core web application
and Home Assistant using that encrypted credential.
