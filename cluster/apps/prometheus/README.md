# Prometheus

Internal metrics service at `https://prom.ops.nairdev.com`, with bounded local
retention and mutation APIs disabled. It scrapes itself and `nmac`, and alerts
on target loss, low root-disk space, and low available memory.
