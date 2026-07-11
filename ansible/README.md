# Ansible

Host bootstrap lives here after manual inventory is stable.

Do not require passwordless sudo. Use become password unless that policy changes.

Run storage bootstrap from the repo root:

```sh
make ansible-storage
```

The target prompts for the sudo/become password through Ansible's `-K` flag.
