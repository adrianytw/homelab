## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## homelab

This repo describes and automates a single-node personal homelab.

Rules:
- Keep the flat LAN first. Do not add VLANs until DNS, backups, monitoring, and restore are proven.
- RouterOS owns routing, DHCP, firewall, Wi-Fi, WireGuard, and the client-facing DNS endpoint at `192.168.88.1`.
- AdGuard stays on the MikroTik as a RouterOS container. Treat `10.0.0.2` as router-internal container plumbing, not client DNS.
- The MacBook `nmac` at `192.168.88.20` owns k3s workloads only. It must not own LAN routing, DHCP, or primary DNS.
- Home Assistant stays a libvirt VM, not a k3s workload.
- Do not make RouterOS firewall, WireGuard, DHCP, DNS, or container-network changes without backup/export/review and explicit approval.
- No public service exposure by default. Public Let's Encrypt certificates do not imply WAN access.
- Use SOPS + age for committed secrets. Never commit plaintext tokens, SSH keys, age keys, kubeconfigs, or OpenTofu state.
- Cockpit is break-glass visibility, not source of truth.
- Current computer is the temporary off-host backup target until OCI Object Storage is active.
