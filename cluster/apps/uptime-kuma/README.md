# Uptime Kuma

Internal monitoring UI at `https://status.nairdev.com`. Uptime Kuma `2.4.0`
uses the digest-pinned Linux ARM64 rootless image, SQLite single-connection mode,
and a local-path PVC mounted at `/app/data`.

The SOPS-encrypted admin credential is retained for recovery. Never mount a
container-runtime socket. Stop the deployment before backing up or restoring
the SQLite data.

The one-shot setup Job idempotently adds checks for each core web application,
Home Assistant, the Router and AdGuard interfaces, the k3s ingress test
workload, and the RouterOS-to-AdGuard client DNS path at `192.168.88.1` using
that encrypted credential.
