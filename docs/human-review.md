# Human Review Queue

Nothing here blocks unrelated lanes. Resolve an item by recording the decision and evidence; never place a secret value in this file.

| ID | Review needed | Current evidence | Unblocks |
| --- | --- | --- | --- |
| HOST-SUDO | Provide an attended sudo/local-console window for operations outside the fixed maintenance wrapper. | SSH key and allowlisted app maintenance work; generic `sudo -n` fails on `nmac`. | Privileged firewall/power inventory and HA restore test. |
| HOST-FIREWALL | Run and review the privileged inventory in `runbooks/k3s-firewall-proof.md`; map the active interface/bridge zone and confirm how WireGuard sources arrive before choosing rules. | Firewalld is enabled/active; unprivileged rule inventory is denied. Prior inventory showed broad high-port access. | k3s exposure and persistent firewall rules. |
| HOST-POWER | Confirm lid-closed usage and desired suspend/hibernate policy. | Current policy has not been captured with privilege. | Power-management automation. |
| HA-RESTORE | Schedule a local-console isolated restore test and make the existing recovery passphrase available interactively. | Encrypted bundle and outer checksum are fresh; `haos` is running/autostarted on `br0` at `.84`; contents are not yet restore-proven. | Critical restore proof and stateful app expansion. |
| DATA-ENCRYPTION | Accept that live `/srv/data` is unencrypted and only off-host copies are encrypted. | Full-disk/data encryption is outside the current build. | Recorded risk acceptance. |
| ROS-ACCOUNT | Choose a dedicated least-privilege OpenTofu account or approve the existing account. | `ROS_USERNAME`/`ROS_PASSWORD` are absent. | Provider connectivity/imports. |
| STATE-CUSTODY | Store `TF_VAR_state_passphrase` outside Git with recovery instructions. | No OpenTofu state exists. | First import/state creation. |
| ADG-CONFIG | Decide whether OpenTofu owns full `adguard_config` or rewrites only. | Trusted HTTPS and encrypted YAML backup are proven; provider singleton ID `1` owns all supported configuration. | Singleton import. |
| ROUTER-BACKUP-AUTO | Choose secure noninteractive delivery for the RouterOS binary-backup password. | Public-key SSH and manual encrypted binary backup work; the weekly Healthchecks check remains paused. | Weekly RouterOS backup schedule. |
| EXPANSION-RESTORE | Complete the HA isolated boot test before adding critical stateful apps. | Core apps and app restores are proven; the critical VM restore is not. | Paperless, Actual, Forgejo, and later services. |
