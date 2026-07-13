# Prometheus

Internal metrics service at `https://prom.ops.nairdev.com`, with bounded local
retention and mutation APIs disabled. It scrapes itself and `nmac`, and alerts
on target loss, low root-disk space, low available memory, and sustained high
CPU usage.

The internal SNMP exporter collects RouterOS system resources over read-only,
source-restricted SNMPv3 `authPriv`. Credentials are SOPS encrypted; SNMP and
the exporter are not exposed outside the flat LAN and cluster, respectively.
Alerts cover target loss, sustained CPU load, memory, system flash, AdGuard USB
storage, and CPU temperature.

Prometheus also scrapes the four Flux controllers, cert-manager, and Traefik
through internal ClusterIP Services. Alerts cover repeated Flux reconciliation
failures, Certificates and ClusterIssuers remaining unready, and certificate
expiry inside 14 days. Static targets avoid adding Kubernetes API credentials,
discovery RBAC, or another monitoring dependency.

Alertmanager `0.32.1` and `alexbakker/alertmanager-ntfy` `1.2.1` are internal
only and digest pinned. The bridge is listed in the official ntfy integration
catalog, publishes warning/critical firing and resolved events to
`homelab-alerts`, and reads the topic-limited `ntfy-publisher` Secret at runtime.
