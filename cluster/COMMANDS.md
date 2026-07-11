# Cluster command log

## 2026-07-11

```sh
curl -fsSL -o /dev/null -w '%{url_effective}\n' https://update.k3s.io/v1-release/channels/stable
curl -fsSL -o /tmp/k3s-install.sh https://get.k3s.io
sha256sum /tmp/k3s-install.sh
```

Outcome: official stable channel resolved to `v1.36.2+k3s1`; installer SHA-256 is `d264d4d43f7c5a27b44de0075513fb22dfb02d0b7cd33ba7a3838cb822f4729c`. The BusyBox `1.37.0` multi-architecture index was pinned as `sha256:9532d8c39891ca2ecde4d30d7710e01fb739c87a8b9299685c63704296b16028`.

No cluster command has run and k3s remains absent.
