# Human Review Queue

Nothing here blocks unrelated lanes. Resolve an item by recording the decision and evidence; never place a secret value in this file.

| ID | Review needed | Current evidence | Unblocks |
| --- | --- | --- | --- |
| LOCAL-SUDO | Provide an attended sudo window for approved workstation packages. | `sudo -n` fails on the current Ubuntu computer. | System installation of age, SOPS dependencies, DNS, and qemu tools. |
| HOST-SUDO | Provide an attended sudo window or secure Ansible become mechanism. | SSH key works; `sudo -n` fails on `nmac`. | Storage and k3s applies, privileged host inventory. |
| HOST-FIREWALL | Run and review the privileged inventory in `runbooks/k3s-firewall-proof.md`; map the active interface/bridge zone and confirm how WireGuard sources arrive before choosing rules. | Firewalld is enabled/active; unprivileged rule inventory is denied. Prior inventory showed broad high-port access. | k3s exposure and persistent firewall rules. |
| HOST-REBOOT | Approve a maintenance reboot after k3s and firewall validation. | No unattended reboot is authorized. | Reboot recovery acceptance. |
| HOST-POWER | Confirm lid-closed usage and desired suspend/hibernate policy. | Current policy has not been captured with privilege. | Power-management automation. |
| HA-BACKUP | Approve graceful HA downtime for a consistent qcow2 backup. | VM is running/autostarted at `.84`; force-destroy is forbidden. | HA recovery artifact. |
| HA-BRIDGE | Review `runbooks/home-assistant-bridge-migration.md` and schedule its local-console window. | Active profile is DHCP UUID `2c145c77-880e-36a9-a419-55d1df2f951e`; host MAC `F8:E4:3B:54:E7:03`; macvtap is present. Inactive XML still needs privileged preflight verification. | `nmac` reaching HA without RouterOS changes. |
| DATA-ENCRYPTION | Accept that live `/srv/data` is unencrypted and only off-host copies are encrypted. | Full-disk/data encryption is outside the current build. | Recorded risk acceptance. |
| AGE-CUSTODY | Choose an independent place for the recovery-bundle passphrase. | SOPS + age selected; key generation is intentionally deferred. | age identity, `.sops.yaml`, encrypted secrets, Flux. |
| ROS-BACKUP | Make `ROUTEROS_BACKUP_PASSWORD` available for a fresh encrypted backup. | Latest backup is `2026-06-27`, stale for new changes. | RouterOS TLS/import work. |
| ROS-ACCOUNT | Choose a dedicated least-privilege OpenTofu account or approve the existing account. | `ROS_USERNAME`/`ROS_PASSWORD` are absent. | Provider connectivity/imports. |
| ROS-TLS | Review the exact `www-ssl:443` local-CA certificate packet and rollback. | Current recorded `www-ssl` certificate is `none`; user chose review-packet-only. | Trusted RouterOS REST. |
| STATE-CUSTODY | Store `TF_VAR_state_passphrase` outside Git with recovery instructions. | No OpenTofu state exists. | First import/state creation. |
| ADG-ENDPOINT | Approve a trusted LAN/VPN HTTPS route to AdGuard management. | `10.0.0.2` is router-internal; `adguard.nairdev.com` is unverified. | Provider connectivity. |
| ADG-BACKUP | Confirm AdGuard persistent YAML path and recovery/export procedure. | RouterOS mount details require fresh inventory. | Safe AdGuard import. |
| ADG-CONFIG | Decide whether OpenTofu owns full `adguard_config` or rewrites only. | Provider singleton ID `1` owns all supported configuration. | Singleton import. |
| CF-DNS01 | Supply zone-scoped token, confirm zone, and confirm ACME contact email. | No Cloudflare credential is present. | cert-manager DNS-01. |
| FLUX-AUTH | Choose public HTTPS, deploy key, or GitHub token. | Repository auth model is not recorded. | Flux bootstrap. |
