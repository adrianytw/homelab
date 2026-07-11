# Ansible

Host bootstrap lives here after manual inventory is stable.

Do not require passwordless sudo. Use become password unless that policy changes.

Run storage bootstrap from the repo root:

```sh
make ansible-storage
```

The target prompts for the sudo/become password through Ansible's `-K` flag.

`make ansible-k3s` is prepared but review-gated. Do not run it until storage is idempotent and `HOST-SUDO`, `HOST-FIREWALL`, and the maintenance window are resolved in `docs/human-review.md`.
