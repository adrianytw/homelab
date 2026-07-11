# Architecture

## Target Shape

```text
MikroTik hAP ax3
  RouterOS: routing, DHCP, firewall, Wi-Fi, WireGuard, DNS entrypoint
  AdGuard: RouterOS container via veth1-adguard

MacBook Pro M1 14"
  Fedora Asahi Linux
  Cockpit
  libvirt Home Assistant VM
  k3s workloads
  /srv/data/<service>

Cloudflare
  authoritative DNS for nairdev.com
  Let's Encrypt DNS-01 only

homelab repo
  Ansible, OpenTofu, Kubernetes manifests, runbooks, diagnostics
```

## Network

| Item | Value |
| --- | --- |
| LAN | `192.168.88.0/24` |
| Router | `192.168.88.1` |
| MacBook / k3s ingress target | `192.168.88.20` |
| Home Assistant target convention | `192.168.88.30` unless occupied |
| Home Assistant current lease | `192.168.88.84`, reserve now |
| AdGuard container | `10.0.0.2` |
| RouterOS container gateway | `10.0.0.1/24` |
| DNS clients should use | `192.168.88.1` |

See `docs/ip-plan.md` for reserved addresses and deferred DHCP pool cleanup.

## DNS And TLS

AdGuard owns private `nairdev.com` rewrites. HTTP apps point at `192.168.88.20`; `ha.nairdev.com` points at the Home Assistant VM IP. Do not create an `adguard.nairdev.com` rewrite until the actual HTTPS UI route is verified: `192.168.88.1` is the client DNS endpoint, not proof that it serves the AdGuard UI.

Use Let's Encrypt DNS-01 through Cloudflare. `nairdev.com` is shared, so never issue `*.nairdev.com`. Start with exact hostnames; use a wildcard only for a verified homelab-exclusive subzone:

```text
*.ops.nairdev.com
*.net.nairdev.com
*.dev.nairdev.com
*.sec.nairdev.com
*.ai.nairdev.com
*.k8s.nairdev.com
```

Public certificates do not mean public exposure. No public A/AAAA records for private apps by default.

## Service Map

| Namespace | Service | Hostname | Target | Exposure | Status |
| --- | --- | --- | --- | --- | --- |
| router | AdGuard | `adguard.nairdev.com` | unverified UI route | LAN/VPN | deferred rewrite |
| host | Cockpit | `cockpit.nairdev.com` | `192.168.88.20:9090` | LAN/VPN direct | optional rewrite |
| core | Glance | `home.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| core | Uptime Kuma | `status.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| core | ntfy | `notify.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| core | Healthchecks | `health.ops.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| ops | Grafana | `grafana.nairdev.com` | `192.168.88.20` ingress | VPN preferred | planned |
| ops | Prometheus | `prom.ops.nairdev.com` | `192.168.88.20` ingress | VPN/internal preferred | planned |
| ops | Loki | `loki.ops.nairdev.com` | `192.168.88.20` ingress | VPN/internal preferred | planned |
| ops | Scrutiny | `scrutiny.ops.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| net | NetAlertX | `netalert.net.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| net | Unbound | `unbound.net.nairdev.com` | explicit DNS exposure | LAN/VPN | optional |
| home | Home Assistant | `ha.nairdev.com` | Home Assistant VM IP | LAN/VPN | current VM |
| home | MQTT | `mqtt.home.nairdev.com` | explicit TCP exposure | LAN/VPN | deferred |
| home | Node-RED | `nodered.home.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | deferred |
| life | Paperless-ngx | `paperless.nairdev.com` | `192.168.88.20` ingress | LAN/VPN + app auth | planned |
| life | Actual Budget | `actual.nairdev.com` | `192.168.88.20` ingress | LAN/VPN + app auth | planned |
| life | Photos | `photos.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | deferred |
| dev | Forgejo | `git.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| dev | Registry | `registry.dev.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| dev | CI | `ci.dev.nairdev.com` | `192.168.88.20` ingress | VPN | scaffold later |
| sec | Vault | `vault.nairdev.com` | `192.168.88.20` ingress | VPN | later phase |
| sec | CrowdSec | `crowdsec.sec.nairdev.com` | service-specific | LAN/VPN | planned |
| sec | Wazuh | `wazuh.sec.nairdev.com` | `192.168.88.20` ingress | VPN | resource-gated |
| ai | AI dashboard | `ai.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| ai | LibreChat | `llm.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| ai | Ollama | `ollama.ai.nairdev.com` | ingress or internal API | internal preferred | planned |
| ai | Langfuse | `langfuse.ai.nairdev.com` | `192.168.88.20` ingress | LAN/VPN | planned |
| flux-system | Flux dashboard | `flux.k8s.nairdev.com` | `192.168.88.20` ingress | VPN | optional |

## DNS Rewrite Map

| Hostname | Target | Notes |
| --- | --- | --- |
| `adguard.nairdev.com` | deferred | Verify the HTTPS UI route before adding a rewrite; `192.168.88.1` is only the proven DNS endpoint |
| `cockpit.nairdev.com` | `192.168.88.20` | Optional direct host admin rewrite |
| `home.nairdev.com` | `192.168.88.20` | Glance |
| `status.nairdev.com` | `192.168.88.20` | Uptime Kuma |
| `notify.nairdev.com` | `192.168.88.20` | ntfy |
| `health.ops.nairdev.com` | `192.168.88.20` | Healthchecks |
| `grafana.nairdev.com` | `192.168.88.20` | Grafana |
| `prom.ops.nairdev.com` | `192.168.88.20` | Prometheus |
| `loki.ops.nairdev.com` | `192.168.88.20` | Loki |
| `scrutiny.ops.nairdev.com` | `192.168.88.20` | Scrutiny |
| `netalert.net.nairdev.com` | `192.168.88.20` | NetAlertX |
| `unbound.net.nairdev.com` | `192.168.88.20` | Optional; explicit DNS exposure required |
| `ha.nairdev.com` | Home Assistant VM IP | Current lease `.84`, target convention `.30` |
| `mqtt.home.nairdev.com` | deferred | Explicit TCP exposure required |
| `nodered.home.nairdev.com` | deferred | Deferred |
| `paperless.nairdev.com` | `192.168.88.20` | Paperless-ngx |
| `actual.nairdev.com` | `192.168.88.20` | Actual Budget |
| `photos.nairdev.com` | `192.168.88.20` | Deferred |
| `git.nairdev.com` | `192.168.88.20` | Forgejo |
| `registry.dev.nairdev.com` | `192.168.88.20` | Registry |
| `ci.dev.nairdev.com` | `192.168.88.20` | CI scaffold |
| `vault.nairdev.com` | `192.168.88.20` | Later phase |
| `crowdsec.sec.nairdev.com` | `192.168.88.20` | CrowdSec |
| `wazuh.sec.nairdev.com` | `192.168.88.20` | Wazuh |
| `ai.nairdev.com` | `192.168.88.20` | AI dashboard |
| `llm.nairdev.com` | `192.168.88.20` | LibreChat |
| `ollama.ai.nairdev.com` | `192.168.88.20` | Prefer internal/API-only unless needed |
| `langfuse.ai.nairdev.com` | `192.168.88.20` | Langfuse |
| `flux.k8s.nairdev.com` | `192.168.88.20` | Optional Flux dashboard |

## Workload Order

1. Router baseline and backups.
2. AdGuard and DNS foundation.
3. MacBook bootstrap and `/srv/data`.
4. k3s minimal platform.
5. Home Assistant VM hardening/backups.
6. Core apps: Glance, Uptime Kuma, ntfy, Healthchecks.
7. Observability.
8. SOPS + Flux after manual manifests are proven.
9. Stateful apps.
10. Dev, security, and AI services.
11. Restore tests.
