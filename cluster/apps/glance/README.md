# Glance

Internal dashboard at `https://home.nairdev.com` using Glance `v0.8.5`, pinned
to the Linux ARM64 image digest in `app.yaml`. Configuration is Git-managed;
the PVC stores optional local assets and is the low-risk backup/restore target.

Glance has no anonymous mutation surface: dashboard changes require changing
the ConfigMap and reapplying the manifest. Do not mount host or container
runtime sockets.
