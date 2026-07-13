# Glance

Internal dashboard at `https://home.nairdev.com` using Glance `v0.8.5`, pinned
to the Linux ARM64 image digest in `app.yaml`. The Everforest-themed homepage
provides a compact view of nine service endpoints plus grouped operations,
infrastructure, source, and test links. Uptime Kuma remains the authoritative
monitor; Glance is the lightweight at-a-glance view.

Glance has no anonymous mutation surface: dashboard changes require changing
the ConfigMap and reapplying the manifest. It uses no host or container runtime
sockets, credentials, host agent, custom CSS, or third-party icon dependencies.
The PVC stores optional local assets and is the low-risk backup/restore target.
