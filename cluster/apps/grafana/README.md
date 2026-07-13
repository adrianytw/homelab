# Grafana

Internal dashboard at `https://grafana.nairdev.com`, with anonymous access and
sign-up disabled. The Prometheus datasource and `nmac overview` dashboard are
provisioned read-only. The `RouterOS overview` dashboard shows CPU, memory,
temperature, system flash, AdGuard USB storage, and uptime from SNMPv3 metrics.
The `Platform overview` dashboard shows scrape health, Flux reconciliation
errors, certificate readiness and lifetime, and Traefik request/5xx rates. It
does not claim exact Flux Kustomization readiness without kube-state-metrics.
