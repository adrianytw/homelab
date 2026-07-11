# Playbooks

- `storage.yml` creates only `/srv/data` and `/srv/data/k3s-storage`.
- `k3s.yml` installs the pinned single-node ARM64 k3s release after its review gates pass.
- `bootstrap.yml` currently imports storage only; k3s remains an explicit separate action.
