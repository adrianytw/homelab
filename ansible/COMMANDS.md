# Ansible command log

Sanitized commands run against `nmac`. Become passwords are never logged.

## 2026-07-11

```sh
ssh -o BatchMode=yes -o ConnectTimeout=5 nmac 'printf reachable'
ssh -o BatchMode=yes nmac 'sudo -n true'
```

Outcome: SSH key authentication succeeds; passwordless sudo is unavailable. No Ansible apply has run.

Prepared, not run:

```sh
make ansible-storage
make ansible-k3s
```

Both remain blocked on human-review gates; preparation is not approval to apply them.

```sh
make inventory-nmac
make ansible-check
```

Outcome: the hardened read-only inventory completed using one bounded SSH control connection. Both prepared playbooks passed Ansible syntax checks; no apply ran.
