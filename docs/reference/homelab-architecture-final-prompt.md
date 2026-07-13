# Homelab architecture and implementation prompt

> Historical design input. `README.md`, `docs/architecture.md`, and `docs/operating-policy.md` are authoritative where this document differs, especially for TLS wildcard scope and the now-verified `adguard.nairdev.com` UI route.

We are designing and implementing a personal homelab.

The goal is a professional but manageable single-node homelab with:

* MikroTik hAP ax³ as the network control plane
* AdGuard DNS running on the MikroTik using RouterOS containers and veth
* MacBook Pro M1 14" running Fedora Asahi Linux as the Kubernetes host
* k3s as the Kubernetes runtime
* OpenTofu for RouterOS and AdGuard configuration
* Ansible for host bootstrap
* FluxCD and SOPS for GitOps and secrets after manual manifests are proven
* `/srv/data/<service>` as the persistent storage convention
* internal DNS hostnames under `nairdev.com`, resolved privately through AdGuard

Do not invent extra hosts, networks, VLANs, public exposure, or external dependencies unless explicitly requested. Cloudflare DNS is explicitly allowed for `nairdev.com` and Let’s Encrypt DNS-01. OCI Object Storage is an approved later backup target.

# Current architecture

## Current known state

| Item                    | Value                             |
| ----------------------- | --------------------------------- |
| Primary LAN             | `192.168.88.0/24`                 |
| Router                  | MikroTik hAP ax³                  |
| Router IP               | `192.168.88.1`                    |
| Router OS               | RouterOS `7.23.1`                 |
| Current DNS app         | AdGuard DNS                       |
| AdGuard placement       | RouterOS container on MikroTik    |
| AdGuard networking      | RouterOS veth                     |
| MacBook host            | MacBook Pro M1 14"                |
| MacBook target IP       | `192.168.88.20`                   |
| MacBook OS              | Fedora Asahi Linux                |
| Kubernetes runtime      | k3s                               |
| Desired app exposure    | Internal only                     |
| Desired IaC             | OpenTofu for RouterOS and AdGuard |
| Desired host automation | Ansible                           |
| Desired GitOps          | FluxCD later, after manual proof  |
| Desired secrets         | SOPS + age                        |
| Public DNS provider     | Cloudflare for `nairdev.com`      |
| Desired TLS             | Let’s Encrypt via DNS-01          |
| Temporary backup target | Current computer before OCI       |
| RouterOS access method  | SSH initially; API may be enabled for OpenTofu |
| RouterOS automation user | `nairda`                         |
| MacBook hostname        | `nmac`                            |
| MacBook SSH             | Working at `nairda@192.168.88.20` |
| MacBook management UI   | Cockpit running                   |
| Passwordless sudo       | No; Ansible should use become password unless changed |

## Current clarification

AdGuard currently runs on the MikroTik using RouterOS container/veth networking. It was originally created from a tutorial. The design should keep AdGuard on the router for now because DNS belongs close to the network edge and should not depend on k3s being healthy.

The active LAN is `192.168.88.0/24`.

The AdGuard RouterOS container subnet has been verified:

| Item | Value |
| ---- | ----- |
| AdGuard container IP | `10.0.0.2` |
| RouterOS container gateway | `10.0.0.1/24` |
| Container network | `10.0.0.0/24` |
| veth | `veth1-adguard` |
| bridge/network | `docker` |
| AdGuard web UI | `10.0.0.2:80` |
| AdGuard DNS port | `10.0.0.2:53` |
| AdGuard persistence | Router USB storage |

The current DHCP DNS handed to clients is `10.0.0.2`, but the target is to hand clients `192.168.88.1` and keep `10.0.0.2` as RouterOS-internal container plumbing.

Target behavior:

```text
LAN clients
→ DHCP DNS: 192.168.88.1
→ RouterOS DNS entrypoint
→ AdGuard container at 10.0.0.2 through RouterOS veth
→ internal nairdev.com rewrite or upstream DNS
```

Additional current operational facts:

| Item | Value |
| ---- | ----- |
| RouterOS access | SSH with user `nairda` |
| RouterOS API | May be enabled for OpenTofu, LAN/VPN-only and not exposed to WAN |
| RouterOS DNS `allow-remote-requests` | Enabled |
| RouterOS configured DNS server | `10.0.0.2` only for now |
| DHCP pool range | Unknown; must be discovered before DHCP changes |
| Router firewall tutorial state | Unknown; must be exported/reviewed before automation changes |
| MacBook hostname | `nmac` |
| MacBook SSH | Working |
| MacBook Cockpit | Running |
| MacBook passwordless sudo | Not enabled |
| Fedora Asahi state | Already installed; automation should support existing and fresh-host modes |
| Disk encryption | Not enabled |
| Home Assistant | Already running through Cockpit/libvirt |
| Home Assistant USB device | Silicon Labs CP2105 Dual UART Bridge, bus 1, device 3 |
| Let’s Encrypt ACME email | `adrian.ytw@gmail.com` |

# Summary plan

Build the homelab in this order:

1. Stabilize RouterOS.
2. Back up and export RouterOS config.
3. Confirm flat LAN on `192.168.88.0/24`.
4. Reserve `192.168.88.20` for the MacBook.
5. Keep AdGuard on RouterOS as a container.
6. Make `192.168.88.1` the client-facing DNS endpoint.
7. Use AdGuard for internal `nairdev.com` DNS rewrites.
8. Bootstrap the MacBook with Ansible.
9. Install k3s on the MacBook.
10. Deploy internal workloads by namespace.
11. Add monitoring, alerting, and backup runbooks.
12. Add FluxCD and SOPS after manual manifests are proven.
13. Add stateful apps.
14. Add dev, security, and AI services.
15. Run restore tests.

# End goal

The end state is:

```text
flat LAN
RouterOS-owned routing, DHCP, firewall, Wi-Fi, WireGuard, and DNS entrypoint
RouterOS-hosted AdGuard DNS container via veth
MacBook-hosted k3s workload platform
OpenTofu-managed RouterOS and AdGuard config
Ansible-managed MacBook bootstrap
FluxCD-managed Kubernetes apps after manual proof
SOPS + age for Kubernetes secrets
/srv/data/<service> for persistent app data
internal `nairdev.com` hostnames with Let’s Encrypt DNS-01 certificates
```

Do not introduce VLANs until the flat LAN, DNS, backups, monitoring, and restore process are proven.

# End-goal device tree

The tree must show ownership and placement. Details belong in tables.

```text
homelab
├── MikroTik hAP ax³
│   ├── RouterOS
│   ├── WAN uplink
│   ├── LAN bridge
│   ├── DHCP
│   ├── Firewall
│   ├── Wi-Fi
│   ├── VLAN-ready network model
│   ├── WireGuard
│   ├── RouterOS binary backups
│   ├── RouterOS text exports
│   ├── OpenTofu-managed RouterOS config
│   └── AdGuard DNS container
│       ├── RouterOS container runtime
│       ├── veth1-adguard
│       ├── DNS filtering
│       ├── internal nairdev.com DNS rewrites
│       ├── adguard.nairdev.com
│       └── OpenTofu-managed AdGuard config
│
├── MacBook Pro M1 14"
│   ├── Fedora Asahi Linux
│   ├── Cockpit
│   │   ├── host visibility
│   │   ├── emergency administration
│   │   ├── firewall inspection
│   │   ├── storage inspection
│   │   └── libvirt / Home Assistant VM inspection
│   ├── Ansible-managed host bootstrap
│   ├── SSH
│   ├── power and sleep settings
│   ├── host firewall
│   ├── backup agent
│   ├── k3s
│   │   ├── Kubernetes API
│   │   ├── containerd
│   │   ├── CNI
│   │   ├── ingress controller
│   │   ├── local-path storage
│   │   ├── namespaces
│   │   └── workloads
│   │       ├── core
│   │       ├── ops
│   │       ├── net
│   │       ├── home
│   │       ├── life
│   │       ├── dev
│   │       ├── sec
│   │       ├── ai
│   │       └── flux-system
│   ├── libvirt / virt-manager
│   │   └── Home Assistant OS VM
│   │       ├── ha.nairdev.com
│   │       └── USB passthrough: Z-Stick 10 Pro Zigbee 3.0 & Z-Wave 800 Series USB Adapter
│   └── /srv/data
│       ├── glance
│       ├── uptime-kuma
│       ├── ntfy
│       ├── healthchecks
│       ├── netalertx
│       ├── grafana
│       ├── prometheus
│       ├── loki
│       ├── scrutiny
│       ├── home-assistant-vm
│       ├── mqtt (deferred)
│       ├── nodered (deferred)
│       ├── paperless
│       ├── actual
│       ├── photos
│       ├── git
│       ├── registry
│       ├── ci
│       ├── vault
│       ├── crowdsec
│       ├── wazuh
│       ├── ollama
│       ├── langfuse
│       ├── postgres (only when app-required)
│       └── redis (deferred until app-required)
│
├── Cloudflare DNS
│   ├── authoritative DNS for nairdev.com
│   ├── Let’s Encrypt DNS-01 validation
│   ├── wildcard certificate validation records
│   └── no public A/AAAA records for private apps by default
│
├── homelab repo
│   ├── ansible
│   ├── cluster
│   ├── apps
│   ├── opentofu
│   │   ├── routeros
│   │   └── adguard
│   ├── secrets
│   ├── scripts
│   ├── docs
│   ├── runbooks
│   ├── diagnostics
│   └── Makefile
│
└── Backup and recovery layer
    ├── temporary backup target: current computer
    ├── later backup target: OCI Object Storage
    ├── /srv/data backups
    ├── repo backups
    ├── SOPS-encrypted secrets
    ├── encrypted age key recovery bundle
    ├── OpenTofu state backups
    ├── RouterOS binary backups
    ├── RouterOS text exports
    ├── AdGuard config exports
    ├── Home Assistant VM backups
    ├── restore tests
    ├── Healthchecks pings
    └── ntfy alerts
```

# Network details

## Active network model

| Item                             | Value                                                       |
| -------------------------------- | ----------------------------------------------------------- |
| LAN subnet                       | `192.168.88.0/24`                                           |
| Router IP                        | `192.168.88.1`                                              |
| Current DHCP DNS handed to clients | `10.0.0.2`                                                |
| Target DHCP DNS handed to clients  | `192.168.88.1`                                            |
| MacBook reservation              | `192.168.88.20`                                             |
| k3s ingress endpoint             | `192.168.88.20`                                             |
| AdGuard placement                | RouterOS container                                          |
| AdGuard container interface      | `veth1-adguard`                                             |
| AdGuard container IP             | `10.0.0.2`                                                  |
| RouterOS container gateway       | `10.0.0.1/24`                                               |
| Container network                | `10.0.0.0/24`                                               |
| RouterOS container bridge/network | `docker`                                                   |
| Client-facing DNS endpoint       | `192.168.88.1`                                              |
| Public exposure                  | None by default                                             |
| Remote access                    | WireGuard through RouterOS, full LAN for now                |
| Public DNS provider              | Cloudflare for `nairdev.com`                                |
| TLS model                        | Let’s Encrypt DNS-01, no private CA by default              |

## Future VLAN-ready model

VLANs are future work. Do not implement VLANs until the flat LAN is stable.

| Future zone      | Purpose                          |
| ---------------- | -------------------------------- |
| Trusted LAN      | Main trusted devices             |
| Homelab services | Servers and infrastructure       |
| IoT              | Smart home devices               |
| Guest            | Guest Wi-Fi                      |
| Management       | Router, switches, admin surfaces |

# Device details

## MikroTik hAP ax³

| Item                      | Value                           |
| ------------------------- | ------------------------------- |
| Role                      | Network control plane           |
| IP                        | `192.168.88.1`                  |
| Owns routing              | Yes                             |
| Owns DHCP                 | Yes                             |
| Owns firewall             | Yes                             |
| Owns Wi-Fi                | Yes                             |
| Owns WireGuard            | Yes                             |
| Owns DNS entrypoint       | Yes                             |
| Runs AdGuard              | Yes, as RouterOS container      |
| Runs general homelab apps | No                              |
| Managed by OpenTofu       | Yes, after backup/import/review |

## AdGuard DNS

| Item                    | Value                                      |
| ----------------------- | ------------------------------------------ |
| Role                    | DNS filtering and local DNS                |
| Placement               | MikroTik RouterOS container                |
| Runtime                 | RouterOS container runtime                 |
| Network attachment      | `veth1-adguard`                            |
| Client DNS endpoint     | `192.168.88.1` target                      |
| Current DHCP DNS value  | `10.0.0.2`                                 |
| Container IP            | `10.0.0.2`                                 |
| RouterOS container gateway | `10.0.0.1/24`                           |
| Container network       | `10.0.0.0/24`                              |
| Hostname                | `adguard.nairdev.com` after UI route proof |
| Upstream DNS preference | Cloudflare DoH first, Quad9 DoH second     |
| Critical dependency     | Yes                                        |
| Managed by OpenTofu     | Yes                                        |

AdGuard is not a Kubernetes workload.

AdGuard should own:

* DNS filtering
* internal `nairdev.com` rewrites
* upstream DNS configuration: Cloudflare DoH first, Quad9 DoH second
* local DNS client/group policy, if used

## MacBook Pro M1 14"

| Item               | Value                     |
| ------------------ | ------------------------- |
| Role               | Kubernetes app host       |
| OS                 | Fedora Asahi Linux        |
| Architecture       | `linux/arm64` / `aarch64` |
| User               | `nairda`                  |
| IP                 | `192.168.88.20`           |
| Runtime            | k3s + containerd          |
| VM runtime          | libvirt / virt-manager    |
| Persistent data    | `/srv/data/<service>`     |
| App exposure       | Internal only by default  |
| Managed by Ansible | Yes                       |

The MacBook should not own LAN routing, DHCP, or the primary DNS entrypoint.

# k3s workload map

All HTTP applications should be exposed internally through k3s ingress at `192.168.88.20`.

Non-HTTP services need explicit exposure decisions. Do not assume HTTP ingress works for DNS, MQTT, or other raw TCP/UDP services.

| Namespace   | Service                 | Host          | IP / endpoint                                | Hostname                | Purpose                                  |
| ----------- | ----------------------- | ------------- | -------------------------------------------- | ----------------------- | ---------------------------------------- |
| core        | Glance                  | MacBook / k3s | `192.168.88.20` ingress                      | `home.nairdev.com`         | Homelab dashboard                        |
| core        | Uptime Kuma             | MacBook / k3s | `192.168.88.20` ingress                      | `status.nairdev.com`       | Uptime monitoring                        |
| core        | ntfy                    | MacBook / k3s | `192.168.88.20` ingress                      | `notify.nairdev.com`       | Push notifications                       |
| core        | Healthchecks            | MacBook / k3s | `192.168.88.20` ingress                      | `health.ops.nairdev.com`   | Cron and job monitoring                  |
| ops         | Grafana                 | MacBook / k3s | `192.168.88.20` ingress                      | `grafana.nairdev.com`      | Metrics dashboards                       |
| ops         | Prometheus              | MacBook / k3s | `192.168.88.20` ingress                      | `prom.ops.nairdev.com`     | Metrics collection                       |
| ops         | Loki                    | MacBook / k3s | `192.168.88.20` ingress                      | `loki.ops.nairdev.com`     | Log aggregation                          |
| ops         | Scrutiny                | MacBook / k3s | `192.168.88.20` ingress                      | `scrutiny.ops.nairdev.com` | Disk health monitoring                   |
| net         | NetAlertX               | MacBook / k3s | `192.168.88.20` ingress                      | `netalert.net.nairdev.com` | LAN device discovery                     |
| net         | Unbound                 | MacBook / k3s | explicit DNS exposure required               | `unbound.net.nairdev.com`  | Optional recursive DNS/upstream resolver |
| home        | Home Assistant          | MacBook / libvirt VM | VM IP, LAN/VPN only                    | `ha.nairdev.com`           | Home automation                          |
| home        | MQTT                    | Deferred      | explicit TCP exposure required               | `mqtt.home.nairdev.com`    | Deferred until needed                    |
| home        | Node-RED                | Deferred      | `192.168.88.20` ingress if later deployed    | `nodered.home.nairdev.com` | Deferred until needed                    |
| life        | Paperless-ngx           | MacBook / k3s | `192.168.88.20` ingress                      | `paperless.nairdev.com`    | Document management                      |
| life        | Actual Budget           | MacBook / k3s | `192.168.88.20` ingress                      | `actual.nairdev.com`       | Budgeting                                |
| life        | Photos                  | MacBook / k3s | `192.168.88.20` ingress                      | `photos.nairdev.com`       | Photo management                         |
| dev         | Forgejo                 | MacBook / k3s | `192.168.88.20` ingress                      | `git.nairdev.com`          | Internal Git hosting                     |
| dev         | Registry                | MacBook / k3s | `192.168.88.20` ingress                      | `registry.dev.nairdev.com` | Container registry                       |
| dev         | CI                      | MacBook / k3s | `192.168.88.20` ingress                      | `ci.dev.nairdev.com`       | CI automation                            |
| sec         | Vault                   | MacBook / k3s | `192.168.88.20` ingress                      | `vault.nairdev.com`        | Secrets service, later phase             |
| sec         | CrowdSec                | MacBook / k3s | service-specific                             | `crowdsec.sec.nairdev.com` | Security signal and remediation          |
| sec         | Wazuh / SIEM            | MacBook / k3s | `192.168.88.20` ingress                      | `wazuh.sec.nairdev.com`    | SIEM and endpoint/security monitoring    |
| ai          | AI dashboard            | MacBook / k3s | `192.168.88.20` ingress                      | `ai.nairdev.com`           | AI service dashboard                     |
| ai          | LibreChat               | MacBook / k3s | `192.168.88.20` ingress                      | `llm.nairdev.com`          | Web UI for LLM access                    |
| ai          | Ollama                  | MacBook / k3s | `192.168.88.20` ingress or internal API only | `ollama.ai.nairdev.com`    | Local LLM runtime                        |
| ai          | Langfuse                | MacBook / k3s | `192.168.88.20` ingress                      | `langfuse.ai.nairdev.com`  | LLM observability                        |
| flux-system | Flux dashboard, if used | MacBook / k3s | `192.168.88.20` ingress                      | `flux.k8s.nairdev.com`     | GitOps dashboard, optional               |

# DNS rewrite map

All internal `nairdev.com` DNS rewrites live in AdGuard.

| Domain                  |          Target |
| ----------------------- | --------------: |
| `adguard.nairdev.com`      | deferred pending HTTPS UI route proof |
| `home.nairdev.com`         | `192.168.88.20` |
| `status.nairdev.com`       | `192.168.88.20` |
| `notify.nairdev.com`       | `192.168.88.20` |
| `health.ops.nairdev.com`   | `192.168.88.20` |
| `grafana.nairdev.com`      | `192.168.88.20` |
| `prom.ops.nairdev.com`     | `192.168.88.20` |
| `loki.ops.nairdev.com`     | `192.168.88.20` |
| `scrutiny.ops.nairdev.com` | `192.168.88.20` |
| `netalert.net.nairdev.com` | `192.168.88.20` |
| `unbound.net.nairdev.com`  | `192.168.88.20` |
| `ha.nairdev.com`           | Home Assistant VM IP |
| `mqtt.home.nairdev.com`    | deferred |
| `nodered.home.nairdev.com` | deferred |
| `paperless.nairdev.com`    | `192.168.88.20` |
| `actual.nairdev.com`       | `192.168.88.20` |
| `photos.nairdev.com`       | `192.168.88.20` |
| `git.nairdev.com`          | `192.168.88.20` |
| `registry.dev.nairdev.com` | `192.168.88.20` |
| `ci.dev.nairdev.com`       | `192.168.88.20` |
| `vault.nairdev.com`        | `192.168.88.20` |
| `crowdsec.sec.nairdev.com` | `192.168.88.20` |
| `wazuh.sec.nairdev.com`    | `192.168.88.20` |
| `ai.nairdev.com`           | `192.168.88.20` |
| `llm.nairdev.com`          | `192.168.88.20` |
| `ollama.ai.nairdev.com`    | `192.168.88.20` |
| `langfuse.ai.nairdev.com`  | `192.168.88.20` |
| `flux.k8s.nairdev.com`     | `192.168.88.20` |

# TLS and certificate model

Use public Let’s Encrypt certificates through DNS-01 validation with Cloudflare.

Do not install a private homelab CA on client devices by default.

Private services may have public certificates while remaining LAN/VPN-only.

Do not create public A/AAAA records for private services by default.

Wildcard certificate coverage should preserve the hostname taxonomy:

```text
*.ops.nairdev.com
*.net.nairdev.com
*.dev.nairdev.com
*.sec.nairdev.com
*.ai.nairdev.com
*.k8s.nairdev.com
```

Use ACME staging before production issuance.

Certificate Transparency note:

* Public Let’s Encrypt certificates are logged to Certificate Transparency logs.
* Never issue `*.nairdev.com`; the root zone is shared. Wildcards are allowed only for verified homelab-exclusive subzones.
* Avoid issuing separate public certificates for every private service hostname unless that hostname being publicly visible is acceptable.

# Operational execution policy

When implementing this prompt, the AI should generate commands, manifests, OpenTofu code, Ansible tasks, runbooks, and validation steps. It must not assume it can safely apply destructive changes without explicit confirmation.

Rules:

* Do not apply destructive changes automatically.
* Require explicit confirmation before RouterOS firewall, WireGuard, DHCP, DNS, or container-networking changes.
* Prefer manual proof before GitOps automation.
* After each phase, provide validation commands and rollback steps.
* Treat unknown current state as something to discover, not something to overwrite.

# Access and credential policy

| Area | Decision |
| ---- | -------- |
| RouterOS access | SSH first |
| RouterOS automation user | `nairda` |
| RouterOS API | May be enabled for OpenTofu, LAN/VPN-only, not WAN-exposed |
| MacBook SSH | `nairda@192.168.88.20` works |
| MacBook sudo | No passwordless sudo by default; Ansible should use become password unless changed |
| Cockpit | Running on the MacBook |

Secrets handling:

* Use SOPS + age for durable secrets committed to the repo in encrypted form.
* Use environment variables or a Git-ignored local `.envrc` / `.env` only for local bootstrap secrets.
* Do not commit plaintext secrets, API tokens, SSH keys, age keys, kubeconfigs, or OpenTofu state.
* Cloudflare API token for cert-manager should be stored as a SOPS-encrypted Kubernetes Secret before Flux automation.
* Before SOPS is fully active, inject the Cloudflare token manually into the cluster and document the step in a runbook.
* Discord must not store raw secrets. If used for emergency recovery, store only an encrypted recovery archive whose passphrase/key is kept elsewhere.

# Cockpit policy

Cockpit is installed and available on the MacBook host `nmac`.

Cockpit may be used for:

* host visibility
* emergency administration
* service inspection
* firewall inspection
* storage inspection
* libvirt / virt-manager visibility
* Home Assistant VM inspection and manual recovery

Cockpit should not replace Ansible as the source of truth for repeatable host configuration.

Cockpit should not replace OpenTofu for RouterOS, AdGuard, or later infrastructure state.

Cockpit should not replace FluxCD for Kubernetes application reconciliation after GitOps is enabled.

Cockpit access should remain LAN/VPN-only and must not be publicly exposed by default.

Recommended access:

```text
https://192.168.88.20:9090
https://cockpit.nairdev.com:9090
```

Optional AdGuard rewrite:

| Domain | Target |
| --- | ---: |
| `cockpit.nairdev.com` | `192.168.88.20` |

Do not route Cockpit through k3s ingress initially. Keep it as a direct host administration endpoint on port `9090`.

# Cloudflare and ACME policy

Cloudflare DNS is used for `nairdev.com` and Let’s Encrypt DNS-01 validation.

Cloudflare API token requirements:

* Scope token to the `nairdev.com` zone only.
* Grant DNS edit permission for the zone.
* Grant zone read permission if required by cert-manager/provider behavior.
* Do not use the global Cloudflare API key.
* Store the token through SOPS + age or manual bootstrap secret, not plaintext Git.

cert-manager model:

* Use one ClusterIssuer for Let’s Encrypt staging.
* Use one ClusterIssuer for Let’s Encrypt production.
* Test staging first.
* Use a small number of wildcard Certificate resources matching the hostname taxonomy.
* Prefer a shared Traefik default TLS certificate for common ingress hostnames.

ACME email:

```text
adrian.ytw@gmail.com
```

# k3s platform defaults

| Area | Default |
| ---- | ------- |
| k3s version | Latest stable at implementation time |
| Ingress | Traefik first |
| ServiceLB | Keep k3s default ServiceLB initially unless it conflicts with explicit needs |
| Ingress ports | Allow Traefik/ServiceLB to own ports 80 and 443 on the single node |
| Kubernetes API | LAN/VPN-only; never WAN-exposed |
| Storage | Use explicit storage under `/srv/data` where practical |
| local-path storage | Prefer a configured path under `/srv/data/k3s-storage` instead of opaque defaults |
| Image tags | Pin meaningful versions for stateful apps; avoid unreviewed `latest` for important workloads |

Storage convention:

* App data should live under `/srv/data/<service>` wherever practical.
* k3s local-path dynamic storage may use `/srv/data/k3s-storage`.
* Critical apps should have clear restore instructions, not only opaque PVC names.

# Database and cache policy

Do not create a dedicated database VM by default.

Default rules:

* Keep simple app-local databases with their apps.
* Use SQLite where appropriate.
* Use Postgres only when an app needs it.
* First Postgres deployment should run in k3s with explicit `/srv/data/postgres` storage unless a host-managed container is chosen for isolation.
* Consider a libvirt data-services VM later only if multiple critical apps depend on Postgres or k3s rebuilds become common.
* Do not deploy Redis by default.
* Add Redis only when a specific app requires it, preferably app-scoped first.

Database backup policy:

* Use logical dumps for Postgres databases.
* Also back up the relevant `/srv/data` volume data.
* Restore tests should use logical dumps first because they are more portable across versions and storage layouts.

# Exposure policy

Public certificates do not imply public exposure.

Default exposure matrix:

| Category | Default access |
| -------- | -------------- |
| RouterOS admin | LAN/VPN only |
| AdGuard UI | LAN/VPN only |
| Dashboard | LAN/VPN only |
| Paperless-ngx | LAN/VPN only, app auth required |
| Actual Budget | LAN/VPN only, app auth required |
| Forgejo | LAN/VPN only first; public exposure only by explicit exception |
| AI frontend / LibreChat | LAN/VPN only |
| Ollama API | Cluster-internal or AI-frontend-only by default |
| Home Assistant | LAN/VPN only |
| Grafana | VPN-only preferred |
| Prometheus | VPN-only or cluster-internal preferred |
| Loki | VPN-only or cluster-internal preferred |
| Vault | VPN-only, later phase only |
| CI | VPN-only; can be scaffolded with TODOs but not actively run until Git service is stable |
| Registry | LAN/VPN only first; Docker-compatible OCI registry behavior is sufficient |
| Databases | Cluster-internal only |
| Redis | Cluster-internal only, app-scoped when used |

No WAN port forwards are allowed by default. Any public exposure must be explicitly requested and documented with a rollback path.

Headscale/Tailscale may be considered later for VPN-style access, but RouterOS WireGuard remains the initial remote-access path.

# Home Assistant VM operational policy

Home Assistant remains outside k3s as a Home Assistant OS VM under Cockpit/libvirt.

Recommended conventions:

| Area | Decision |
| ---- | -------- |
| VM networking | Bridged LAN networking |
| VM IP convention | Reserve `192.168.88.30` for Home Assistant unless occupied |
| DNS name | `ha.nairdev.com` |
| CPU/RAM | Allocate just enough; 2 GB RAM minimum target if stable, 4 GB acceptable if already configured |
| USB passthrough | Use stable USB vendor/product/device identity where possible, not only ephemeral bus/device number |
| VM storage/backup path | `/srv/data/home-assistant-vm` |
| OpenTofu destroy behavior | Must be forbidden unless explicitly approved |

Known USB device:

```text
CP2105 Dual UART Bridge
Silicon Labs
Bus 1
Device 3
```

# App product choices

| Category | Product decision |
| -------- | ---------------- |
| Paperless | Paperless-ngx |
| Budget | Actual Budget |
| Git service | Forgejo |
| Photos | Deferred for now |
| AI frontend | LibreChat |
| LLM runtime | Ollama, occasional use |
| Registry | Docker-compatible OCI registry behavior is enough initially |
| CI | Scaffold with TODOs, do not actively run until Forgejo is stable |
| MQTT | Deferred until needed |
| Node-RED | Deferred until needed |
| Redis | Deferred until app-required |

# Backup policy

The current computer is the temporary off-host backup target before OCI Object Storage is active. OCI Object Storage remains the later durable backup target. Until at least one off-host backup target is active and restore-tested, the homelab is not fully protected against MacBook storage loss.

Temporary backup model:

```text
MacBook /srv/data
→ backup job or manual encrypted archive
→ current computer
→ later OCI Object Storage
```

Before OCI is active, back up at minimum to the current computer:

* homelab Git repo to GitHub and mirror
* RouterOS binary backups
* RouterOS text exports
* AdGuard config export
* SOPS age key, stored offline or in an encrypted recovery bundle
* OpenTofu state, encrypted and Git-ignored
* critical `/srv/data` paths to a local encrypted archive when possible
* Home Assistant VM backup/export where practical

Raw secrets must not be stored unencrypted on the current computer. Discord may hold only an encrypted recovery bundle, not raw keys or plaintext credentials.

Backup tool choice is deferred until OCI backup implementation. Candidates are restic or kopia.

Efficient retention target once off-host backups exist:

```text
hourly: optional for critical app dumps only, last 24 hours
 daily: 7 days
weekly: 4 weeks
monthly: 6 months
```

Before OCI exists, keep fewer local encrypted snapshots to avoid filling the 512 GB SSD.

First restore test:

```text
Restore one low-risk app from /srv/data, such as Glance or Uptime Kuma, then restore one critical app database dump after Postgres/Paperless-ngx exists.
```

# Implementation gates

Do not proceed past these gates without validation:

1. Do not change DHCP DNS until RouterOS backup/export exists.
2. Do not let OpenTofu manage RouterOS firewall until import/review is complete.
3. Do not let OpenTofu manage WireGuard until import/review is complete.
4. Do not let OpenTofu destroy or recreate the Home Assistant VM without explicit approval.
5. Do not enable Flux until manual manifests are proven.
6. Do not consider Paperless-ngx, Actual Budget, Forgejo, Photos, or Vault protected until off-host backups exist.
7. Do not deploy Vault until SOPS/age and backup/restore are proven.
8. Do not expose services publicly unless a service-specific public exposure decision is documented.

# Preflight inventory to collect before implementation

Collect these facts before generating destructive changes:

| Area | Required fact |
| ---- | ------------- |
| RouterOS | DHCP pool range |
| RouterOS | Current DHCP network options |
| RouterOS | Current DNS config |
| RouterOS | Current firewall export |
| RouterOS | Current WireGuard export, if configured |
| RouterOS | Current container config and mounts |
| RouterOS | Router USB storage path for AdGuard persistence |
| MacBook | Disk layout and free space |
| MacBook | `/srv/data` existence and permissions |
| MacBook | Host firewall active zones/services from Cockpit/firewalld |
| MacBook | k3s installed or not |
| Home Assistant | VM name, current IP, vCPU/RAM/disk |
| Home Assistant | USB vendor/product IDs for stable passthrough |
| Cloudflare | Zone ID for `nairdev.com` |
| Cloudflare | API token created with least privilege |
| Backup | Local encrypted state backup path |
| Backup | Current computer backup path and available free space |

# Required runbooks

The repo should contain runbooks for:

* RouterOS backup and restore
* DNS failure recovery
* AdGuard container recovery
* DHCP DNS migration from `10.0.0.2` to `192.168.88.1`
* MacBook rebuild
* k3s reinstall
* SOPS age key recovery
* cert-manager / Cloudflare DNS-01 troubleshooting
* Flux reconciliation recovery
* Home Assistant VM restore
* `/srv/data` restore
* OpenTofu state recovery
* Cockpit access and emergency host administration

# Storage map

Persistent app data lives under `/srv/data/<service>` on the MacBook.

| Service        | Path                       | Restore priority |
| -------------- | -------------------------- | ---------------: |
| Glance         | `/srv/data/glance`         |              Low |
| Uptime Kuma    | `/srv/data/uptime-kuma`    |           Medium |
| ntfy           | `/srv/data/ntfy`           |           Medium |
| Healthchecks   | `/srv/data/healthchecks`   |             High |
| Grafana        | `/srv/data/grafana`        |           Medium |
| Prometheus     | `/srv/data/prometheus`     |           Medium |
| Loki           | `/srv/data/loki`           |              Low |
| Scrutiny       | `/srv/data/scrutiny`       |           Medium |
| NetAlertX      | `/srv/data/netalertx`      |           Medium |
| Home Assistant VM | `/srv/data/home-assistant-vm` |             High |
| MQTT           | `/srv/data/mqtt`           | Deferred |
| Node-RED       | `/srv/data/nodered`        | Deferred |
| Paperless-ngx  | `/srv/data/paperless`      |         Critical |
| Actual Budget  | `/srv/data/actual`         |         Critical |
| Photos         | `/srv/data/photos`         |         Critical |
| Forgejo        | `/srv/data/git`            |         Critical |
| Registry       | `/srv/data/registry`       |           Medium |
| CI             | `/srv/data/ci`             |              Low |
| Vault          | `/srv/data/vault`          |         Critical |
| CrowdSec       | `/srv/data/crowdsec`       |           Medium |
| Wazuh          | `/srv/data/wazuh`          |           Medium |
| Ollama         | `/srv/data/ollama`         |       Low/Medium |
| Langfuse       | `/srv/data/langfuse`       |           Medium |
| Postgres       | `/srv/data/postgres`       | Critical when used |
| Redis          | `/srv/data/redis`          | Deferred until app-required |

# OpenTofu structure

Use `opentofu`, not `terraform`, unless compatibility tooling requires the old name.

```text
opentofu
├── README.md
├── versions.tf
├── providers.tf
├── backend.tf
├── variables.tf
├── outputs.tf
├── env
│   └── homelab.tfvars
├── routeros
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── dhcp.tf
│   ├── dns.tf
│   ├── firewall.tf
│   ├── wireguard.tf
│   ├── containers.tf
│   ├── backups.tf
│   └── imports.md
└── adguard
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── rewrites.tf
    ├── filters.tf
    ├── upstreams.tf
    ├── clients.tf
    └── imports.md
```

## OpenTofu ownership

| Area                  | OpenTofu ownership                                                     |
| --------------------- | ---------------------------------------------------------------------- |
| RouterOS DHCP         | Static reservations, DHCP options, DNS server handed to clients        |
| RouterOS DNS behavior | DNS entrypoint settings and forwarding/redirect rules where safe       |
| RouterOS firewall     | Imported first, changed slowly                                         |
| RouterOS WireGuard    | Imported first, changed slowly                                         |
| RouterOS containers   | AdGuard container networking, veth, container metadata where supported |
| RouterOS backups      | Backup/export job definitions where safe                               |
| AdGuard rewrites      | All internal `nairdev.com` rewrites                                    |
| AdGuard filters       | DNS blocklists and filtering configuration                             |
| AdGuard upstreams     | Cloudflare DoH first, Quad9 DoH second                                 |
| AdGuard clients       | Client/group policy if used                                            |
| Cloudflare DNS         | DNS-01 validation records only; no public A/AAAA for private apps by default |
| libvirt                | Possible later ownership for Home Assistant VM after manual proof       |

## OpenTofu safety rules

* Do not let OpenTofu modify RouterOS firewall until the current config is backed up, exported, imported, and reviewed.
* Do not let OpenTofu modify WireGuard until the current config is backed up, exported, imported, and reviewed.
* Do not replace working RouterOS container networking blindly.
* `10.0.0.2` is the verified current AdGuard container IP, but it must remain RouterOS-internal plumbing rather than the LAN client DNS endpoint.
* Do not change the working `veth1-adguard`, `10.0.0.2`, or `docker` container network blindly.
* Keep OpenTofu state backed up; OCI Object Storage is the later backup target.
* Initial OpenTofu state is local, Git-ignored, and backed up as an encrypted local artifact.
* Do not store secrets in plaintext state if avoidable.
* Enable RouterOS API for OpenTofu only if needed, restrict it to LAN/VPN access, and do not expose it to WAN.
* Any import must be documented in `imports.md`.
* Make small changes and test after each apply.

# Repo structure

```text
homelab
├── README.md
├── Makefile
├── ansible
│   ├── inventory
│   │   └── homelab.ini
│   ├── playbooks
│   │   ├── bootstrap.yml
│   │   ├── k3s-prereqs.yml
│   │   └── storage.yml
│   └── roles
│       ├── common
│       ├── ssh
│       ├── power
│       ├── firewall
│       ├── storage
│       ├── backup-agent
│       ├── k3s-prereqs
│       └── libvirt
├── cluster
│   ├── namespaces
│   ├── ingress
│   ├── storage
│   ├── flux-system
│   └── platform
├── apps
│   ├── core
│   ├── ops
│   ├── net
│   ├── home
│   ├── life
│   ├── dev
│   ├── sec
│   └── ai
├── opentofu
│   ├── routeros
│   ├── adguard
│   ├── cloudflare-acme
│   └── libvirt-later
├── secrets
│   ├── age
│   └── sops
├── scripts
├── docs
│   └── decisions
├── runbooks
└── diagnostics
```

# Implementation notes

## Phase 1: Router baseline

* Connect to RouterOS over SSH as `nairda`.
* Discover DHCP pool range and current DHCP network options.
* Export current firewall rules before making changes.
* Create RouterOS binary backup.
* Create RouterOS text export.
* Record RouterOS version.
* Record installed RouterOS packages.
* Confirm router IP is `192.168.88.1`.
* Confirm LAN is `192.168.88.0/24`.
* Confirm DHCP scope.
* Create or verify MacBook static DHCP reservation at `192.168.88.20`.
* Confirm basic firewall policy; do not assume tutorial firewall behavior is safe or complete.
* Confirm admin access method.
* Configure or verify WireGuard.
* Document how to restore RouterOS from backup/export.
* Start OpenTofu import only after backup/export.

## Phase 2: AdGuard and DNS foundation

* Keep AdGuard on RouterOS as a container.
* Verify actual veth name is `veth1-adguard`.
* Do not rename `veth1-adguard` unless there is a documented reason and rollback plan.
* Verify actual AdGuard container IP is `10.0.0.2`.
* Use `192.168.88.1` as DHCP DNS for clients after validating RouterOS DNS forwarding to `10.0.0.2`.
* Ensure clients do not need to know the AdGuard container IP.
* Add `adguard.nairdev.com` only after verifying its HTTPS UI route; do not infer it from the client DNS endpoint.
* Add all internal `nairdev.com` rewrites.
* Use Cloudflare DoH first and Quad9 DoH second as AdGuard upstreams; fallback behavior should be documented but not hidden.
* Manage AdGuard rewrites with OpenTofu after import/review.

## Phase 3: MacBook bootstrap

* Install Fedora Asahi Linux.
* Configure user `nairda`.
* Configure SSH.
* Configure power and sleep settings so the host stays available.
* Configure host firewall.
* Create `/srv/data`.
* Create per-service directories under `/srv/data`.
* Install backup agent.
* Add Ansible roles for repeatability.
* Confirm ARM64 image compatibility for planned workloads.
* Install and configure libvirt / virt-manager foundation for Home Assistant OS VM.
* Pass through Z-Stick 10 Pro Zigbee 3.0 & Z-Wave 800 Series USB Adapter to the Home Assistant VM.

## Phase 4: k3s minimal platform

* Install k3s.
* Verify containerd.
* Verify pod networking.
* Use Traefik as the initial ingress controller.
* Configure local-path storage.
* Create namespaces.
* Install cert-manager and configure Cloudflare DNS-01 for Let’s Encrypt.
* Use ACME staging first, then production.
* Issue exact-name certificates first; use wildcards only for verified homelab-exclusive subzones.
* Deploy one test workload.
* Confirm DNS rewrite to ingress works.
* Confirm LAN/VPN-only access with public certificates and no public A/AAAA records for private services.

## Phase 5: Home Assistant VM

* Keep Home Assistant out of k3s.
* Run Home Assistant OS as a libvirt / virt-manager VM on the MacBook.
* Pass through the Z-Stick 10 Pro Zigbee 3.0 & Z-Wave 800 Series USB Adapter.
* Resolve `ha.nairdev.com` through AdGuard to the Home Assistant VM IP.
* Keep Home Assistant LAN/VPN-only.
* Defer MQTT and Node-RED until explicitly needed.
* Manage the libvirt foundation with Ansible first; consider OpenTofu/libvirt later after manual proof.

## Phase 6: Core apps

* Deploy Glance.
* Deploy Uptime Kuma.
* Deploy ntfy.
* Deploy Healthchecks.
* Verify hostnames.
* Verify persistent paths.
* Verify backups for stateful core apps.
* Do not artificially limit rollout to five apps; proceed in order with validation gates.
* Verify alert path through ntfy and Healthchecks.

## Phase 7: Observability

* Deploy Grafana.
* Deploy Prometheus.
* Deploy Loki.
* Deploy Scrutiny.
* Monitor RouterOS.
* Monitor MacBook host.
* Monitor k3s.
* Monitor important workloads.
* Create dashboards.
* Create alerts.

## Phase 8: GitOps and secrets

* Add SOPS + age.
* Encrypt Kubernetes secrets.
* Back up the age key.
* Deploy FluxCD.
* Reconcile known-good manifests.
* Do not rely only on an internal Git service for cluster restore.
* Keep canonical repo in GitHub and mirrored outside the cluster; do not rely only on an internal Git service for restore.

## Phase 9: Stateful life apps

* Deploy Paperless-ngx.
* Deploy Actual Budget.
* Keep Photos deferred for now.
* Verify data paths.
* Verify backup strategy; OCI Object Storage is the later off-host backup target.
* Restore-test at least one critical app. Critical apps are not fully protected until off-host backups are active.

## Phase 10: Dev, security, and AI apps

* Deploy Forgejo.
* Deploy registry.
* Deploy CI.
* Deploy Vault only after SOPS baseline is stable.
* Deploy CrowdSec.
* Deploy Wazuh only if resources allow.
* Deploy AI dashboard.
* Deploy LibreChat.
* Deploy Ollama.
* Deploy Langfuse.

## Phase 11: Restore test

* Restore RouterOS baseline.
* Restore DHCP and DNS.
* Restore MacBook bootstrap with Ansible.
* Restore `/srv/data`.
* Reinstall k3s.
* Restore SOPS age key.
* Reconcile Flux.
* Validate core apps.
* Validate monitoring.
* Validate backups.
* Document gaps.

# Restore order

```text
1. RouterOS baseline
2. DHCP and DNS
3. MacBook host bootstrap
4. /srv/data restore
5. Home Assistant VM restore if applicable
6. k3s install
7. SOPS age key restore
8. Flux reconciliation
9. Core service validation
10. Observability validation
11. Backup and alert validation
```

# AI behavior rules

When using this prompt, the AI must follow these rules:

1. Do not invent a new subnet.
2. Do not assume VLANs exist.
3. Do not assume AdGuard is a Kubernetes workload.
4. Treat `10.0.0.2` as the verified current AdGuard container IP, not the LAN client-facing DNS endpoint.
5. Treat `192.168.88.1` as the client-facing DNS endpoint.
6. Treat `192.168.88.20` as the MacBook and k3s ingress endpoint.
7. Treat AdGuard’s container IP as RouterOS-internal plumbing.
8. Do not expose services publicly unless explicitly requested; public Let’s Encrypt certificates do not imply public exposure.
9. Do not make RouterOS firewall changes without backup/export/import/review.
10. Cloudflare DNS and later OCI Object Storage are explicitly approved; do not introduce other cloud dependencies unless requested.
11. Prefer simple flat LAN first.
12. Prefer explicit tables over vague prose.
13. Prefer job lists and restore steps over theory.
14. Keep tree sections focused on ownership and placement.
15. Put implementation details under headings, tables, and short lists.
16. Preserve the original hostname taxonomy under `nairdev.com`; do not flatten everything under `home.nairdev.com`.
17. Keep Home Assistant as a libvirt / virt-manager VM, not a k3s workload.
18. Defer MQTT and Node-RED until explicitly needed.
19. Treat Cockpit as an admin convenience layer and break-glass visibility tool, not the source of truth.
20. Treat the current computer as the temporary off-host backup target until OCI Object Storage is active.
19. Do not create a dedicated database VM by default.
20. Do not deploy Redis unless a specific app requires it.
21. Prefer app-local SQLite or app-required Postgres with explicit `/srv/data` storage.
22. Do not store raw secrets in Discord; only encrypted recovery bundles may be stored there.

# Remaining clarifying questions

Most first-pass architecture questions are now answered.

Known decisions:

1. RouterOS version is `7.23.1`.
2. RouterOS access starts with SSH as `nairda`.
3. RouterOS API may be enabled for OpenTofu, LAN/VPN-only and not WAN-exposed.
4. AdGuard veth is `veth1-adguard`.
5. AdGuard container IP is `10.0.0.2`.
6. AdGuard UI is reachable at `10.0.0.2:80`; DNS is `10.0.0.2:53`.
7. AdGuard persistence is on router USB storage.
8. LAN DNS redirect/hijack rules are not desired for now.
9. AdGuard upstreams should prefer Cloudflare DoH first and Quad9 DoH second.
10. k3s should use Traefik first.
11. k3s should keep default ServiceLB initially unless it conflicts with explicit needs.
12. Traefik may own ports 80 and 443 on the single node.
13. Kubernetes API should be LAN/VPN-only and never WAN-exposed.
14. k3s storage should prefer explicit paths under `/srv/data`, with local-path rooted at `/srv/data/k3s-storage` where practical.
15. Cloudflare DNS should be used for Let’s Encrypt DNS-01.
16. Internal HTTPS should use public Let’s Encrypt certificates.
17. ACME email is `adrian.ytw@gmail.com`.
18. ACME staging should be used before production.
19. Cloudflare API token should be least-privilege and stored through SOPS/manual bootstrap, not plaintext.
20. Certificate Transparency exposure is accepted for exact names and homelab-exclusive subzone wildcards; `*.nairdev.com` is forbidden because the root zone is shared.
21. The canonical repo should live in GitHub and be mirrored.
22. OCI Object Storage is the later off-host backup target.
23. Home Assistant should run as a libvirt / virt-manager VM with Z-Stick 10 Pro USB passthrough.
24. Home Assistant VM should use bridged LAN networking.
25. Home Assistant should conventionally use `192.168.88.30` unless occupied.
26. Home Assistant VM backups should live under `/srv/data/home-assistant-vm` where practical.
27. OpenTofu must be forbidden from destroying/recreating the Home Assistant VM without explicit approval.
28. MQTT and Node-RED are not needed initially.
29. Paperless implementation should be Paperless-ngx.
30. Git service should be Forgejo.
31. Photos are deferred for now.
32. AI frontend should be LibreChat.
33. Redis is forbidden unless app-required.
34. Database/cache policy should be documented explicitly.
35. Postgres should start in k3s with explicit `/srv/data/postgres` storage unless a later isolation decision changes this.
36. Database backups should use logical dumps plus volume/data backup.
37. CI may be scaffolded with TODOs but should not actively run until Forgejo is stable.
38. No WAN port forwards are allowed by default.
39. Headscale/Tailscale may be evaluated later; RouterOS WireGuard remains initial remote access.

Remaining questions:

1. What is the current DHCP pool range?
2. What is the current full RouterOS firewall export, especially LAN-to-router DNS and router-to-AdGuard traffic?
3. What is the exact Router USB path for AdGuard persistent config?
4. What is the current Home Assistant VM name, IP, vCPU, RAM, disk size, and storage path?
5. Is `192.168.88.30` free for Home Assistant, or should another convention slot be used?
6. What are the stable USB vendor/product IDs for the Silicon Labs CP2105 device?
7. What local encrypted backup path should hold OpenTofu state before OCI is active?
8. Which services, if any, should ever get public WAN exposure later?
9. Will SSO be added later, and if so, should the design prefer apps that support OIDC?
10. Which backup tool should be selected when OCI backup is implemented: restic or kopia?

# Final design decision

The target design is:

```text
MikroTik hAP ax³
→ owns routing, DHCP, firewall, Wi-Fi, WireGuard, and DNS entrypoint
→ runs AdGuard DNS as RouterOS container via veth1-adguard
→ RouterOS DNS forwards to AdGuard at 10.0.0.2
→ DHCP should hand clients 192.168.88.1 as DNS
→ managed by OpenTofu after backup/import/review

Cloudflare
→ authoritative DNS for nairdev.com
→ used for Let’s Encrypt DNS-01 validation
→ no public A/AAAA records for private services by default

MacBook Pro M1 14"
→ owns k3s workloads
→ uses 192.168.88.20
→ stores persistent data in /srv/data/<service>
→ bootstrapped by Ansible
→ runs Home Assistant OS VM through libvirt / virt-manager

k3s
→ hosts internal applications
→ exposes HTTP apps through Traefik
→ uses cert-manager and Let’s Encrypt DNS-01 certificates
→ uses SOPS + age for secrets
→ uses FluxCD after manual manifests are proven

AdGuard
→ owns internal nairdev.com DNS rewrites
→ client-facing endpoint should be 192.168.88.1
→ container IP 10.0.0.2 is RouterOS-internal plumbing
→ upstream DNS prefers Cloudflare DoH first and Quad9 DoH second
```
