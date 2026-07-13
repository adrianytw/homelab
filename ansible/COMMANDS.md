# Ansible command log

Sanitized commands run against `nmac`. Become passwords are never logged.

## 2026-07-11

```sh
ssh -o BatchMode=yes -o ConnectTimeout=5 nmac 'printf reachable'
ssh -o BatchMode=yes nmac 'sudo -n true'
```

Outcome: SSH key authentication succeeds; passwordless sudo is unavailable. No Ansible apply has run.

Prepared:

```sh
make ansible-storage
make ansible-k3s
```

Storage and k3s remain separately review-gated.

## 2026-07-13

```sh
make ansible-maintenance
```

Outcome: the root-owned `0755` maintenance wrapper and validated root-owned
`0440` sudoers rule were installed. Allowed status/backup/alert/reboot operations
worked; generic sudo, direct k3s, arbitrary apps, and caller paths were denied.

```sh
make inventory-nmac
make ansible-check
```

Outcome: the hardened read-only inventory completed using one bounded SSH control connection. Both prepared playbooks passed Ansible syntax checks; no apply ran.
