# Monitoring Recovery

## Purpose

Recover and validate Uptime Kuma, Prometheus, Alertmanager, the ntfy bridge,
node-exporter, the SNMP exporter, and Grafana after the underlying host, data,
k3s, age identity, and Flux are healthy.

## Prerequisites

- Follow the recovery order in `README.md`.
- Restore the SOPS age identity outside Git before Flux decrypts app secrets.
- Verify the encrypted Uptime Kuma archive checksum before decrypting it.
- Stop Uptime Kuma before copying or restoring its SQLite PVC.
- Subscribe an ntfy client to the private `homelab-alerts` topic on
  `https://notify.nairdev.com`; use the existing ntfy administrator login.

## Validation

- Every Flux Kustomization reports `Ready=True` at the same Git revision.
- Prometheus reports `up=1` for every target in the `prometheus`, `nmac`,
  `alertmanager`, `router`, `flux`, `cert-manager`, and `traefik` jobs.
- Prometheus loads all thirteen rules with health `ok`: target loss; nmac disk,
  memory, and CPU; RouterOS CPU, memory, system flash, AdGuard USB, and
  temperature; Flux reconciliation errors; Certificate/ClusterIssuer
  readiness; and certificate expiry.
- Prometheus discovers `alertmanager.core.svc.cluster.local:9093`; Alertmanager
  reports its configuration healthy and the bridge `/health` endpoint is ready.
- A controlled `MonitoringTargetDown` test produces one firing notification and
  one resolved notification in ntfy. Resume Flux and confirm selector repair.
- Grafana serves the provisioned `nmac overview`, `RouterOS overview`, and
  `Platform overview` dashboards.
- Uptime Kuma shows successful heartbeats for all eleven desired monitors. Its
  CronJob reconciles named monitor drift every fifteen minutes without deleting
  unknown/manual monitors or notification attachments.
- Glance renders all nine human-facing service names as healthy.
- RouterOS SNMP remains source-restricted to `192.168.88.20/32`, read-only,
  authPriv/private, with the default public community disabled.
- Delete the node-exporter pod once and confirm its DaemonSet and scrape recover.

## Rollback

Suspend the affected Flux Kustomization, apply the last known-good manifest,
and restore the most recent verified encrypted application archive. Keep the
failed data and archive until validation finishes; never overwrite the only
copy. Resume Flux only after the manual workload is healthy.

If alert delivery alone fails, inspect Prometheus Alertmanager discovery,
Alertmanager status, and bridge logs in that order. Do not make either service
public.
