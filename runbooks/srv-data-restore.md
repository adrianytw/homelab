# /srv/data Backup And Restore

## Purpose

Prove that one stopped low-risk application can be backed up, decrypted, restored with Linux metadata, and started from restored data. A synthetic round trip tests tooling but does not satisfy this application gate.

## Prerequisites

- SOPS/age recovery is proven and the public `AGE_RECIPIENT` is available.
- The service data path is exactly `/srv/data/<service>` and the service is stopped cleanly.
- The application image UID/GID and expected ownership are recorded.
- The current computer has enough free space for the encrypted archive and scratch restore.

Create the archive on `nmac` only after stopping the service:

```sh
service=<service>
stamp=$(date -u +%Y%m%dT%H%M%SZ)
sudo tar --acls --xattrs --selinux --numeric-owner \
  -C /srv/data -cpf - "$service" \
  | age -r "$AGE_RECIPIENT" \
  >"$HOME/${service}-${stamp}.tar.age"
sha256sum "$HOME/${service}-${stamp}.tar.age" >"$HOME/${service}-${stamp}.tar.age.sha256"
```

Copy the encrypted archive and checksum to `~/homelab-backups/data/<service>/<stamp>/` with directory mode `0700` and file mode `0600`.

Restore to scratch first; never overwrite the live directory during validation:

```sh
scratch="/srv/data/.restore-${service}-${stamp}"
sudo install -d -m 0700 "$scratch"
age -d "$HOME/${service}-${stamp}.tar.age" \
  | sudo tar --acls --xattrs --selinux --numeric-owner -xpf - -C "$scratch"
sudo restorecon -RF "$scratch" 2>/dev/null || true
```

## Validation

- `sha256sum -c` passes before decryption.
- Scratch content, numeric ownership, modes, ACLs, xattrs, and SELinux labels match the source.
- After validation, move the untouched old directory aside, move the restored directory into place, and start the service.
- The application serves expected data after pod/process deletion and restart.
- Keep the previous directory until the application validation is complete.

## Rollback

Stop the application, move the failed restored directory aside, restore the untouched previous directory name, and restart. Preserve both encrypted archive and previous directory for investigation; do not automatically delete either.
