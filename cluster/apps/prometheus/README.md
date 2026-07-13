# Prometheus

Internal metrics service at `https://prom.ops.nairdev.com`, with bounded local
retention and mutation APIs disabled. It scrapes itself and `nmac`, and alerts
on target loss, low root-disk space, and low available memory.

Alertmanager `0.32.1` and `alexbakker/alertmanager-ntfy` `1.2.1` are internal
only and digest pinned. The bridge is listed in the official ntfy integration
catalog, publishes warning/critical firing and resolved events to
`homelab-alerts`, and reads the existing `ntfy-admin` Secret at runtime.
