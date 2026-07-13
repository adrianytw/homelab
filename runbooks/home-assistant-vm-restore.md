# Home Assistant VM Backup And Restore

## Purpose

Create a consistent, encrypted off-host backup of the `haos` libvirt VM and prove that it can boot as an isolated test VM before it is trusted for recovery.

## Known State

- VM: `haos`
- Disk: `/var/lib/libvirt/images/haos.qcow2`
- NVRAM: `/var/lib/libvirt/qemu/nvram/haos_VARS.qcow2`
- Current lease: `192.168.88.84`
- USB: `10c4:ea70`, serial `00C3A38C`
- Temporary staging: `/srv/data/backup-staging/home-assistant`
- Temporary off-host target: `~/homelab-backups/home-assistant`

## Prerequisites

- Approved Home Assistant downtime and working local-console access to `nmac`.
- `sudo`, `virsh`, `qemu-img`, `tar`, `age`, and `sha256sum` are available.
- The off-host computer has enough free space for the compressed VM disk.
- The age recovery-passphrase custody gate is complete. Do not create an unencrypted off-host archive.
- No storage, libvirt network, USB, or production XML change is combined with this backup window.

## Backup Procedure

### 1. Preflight and capture inactive metadata

Run on `nmac` in Bash. Stop if the VM name, disk path, free space, or USB definition differs from the known state.

```bash
set -euo pipefail
umask 077
VM=haos
DISK=/var/lib/libvirt/images/haos.qcow2
NVRAM=/var/lib/libvirt/qemu/nvram/haos_VARS.qcow2
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
STAGE="/srv/data/backup-staging/home-assistant/$STAMP"

test "$(sudo virsh domstate "$VM" | xargs)" = running
sudo test -f "$DISK"
sudo test -f "$NVRAM"
sudo virsh domblklist "$VM" --inactive --details
sudo virsh domiflist "$VM" --inactive
sudo virsh dumpxml "$VM" --inactive | grep -E '10c4|ea70|00C3A38C'
df -h /srv/data
sudo qemu-img info --backing-chain "$DISK"
sudo qemu-img info "$NVRAM"

sudo install -d -m 0700 "$STAGE"
sudo virsh dumpxml "$VM" --inactive | sudo tee "$STAGE/$VM.xml" >/dev/null
sudo virsh dominfo "$VM" | sudo tee "$STAGE/dominfo.txt" >/dev/null
sudo virsh domblklist "$VM" --inactive --details | sudo tee "$STAGE/domblklist.txt" >/dev/null
sudo virsh domiflist "$VM" --inactive | sudo tee "$STAGE/domiflist.txt" >/dev/null
sudo qemu-img info --backing-chain "$DISK" | sudo tee "$STAGE/qemu-info.txt" >/dev/null
sudo qemu-img info "$NVRAM" | sudo tee "$STAGE/nvram-info.txt" >/dev/null
sudo stat "$DISK" | sudo tee "$STAGE/disk-stat.txt" >/dev/null
```

Review `$STAGE/haos.xml` and `domblklist.txt` before continuing. The disk copied below must be the production disk shown by `domblklist`.

### 2. Gracefully stop, check, and copy

The exit trap restarts a VM that this procedure stopped. It never sends `virsh destroy`; if graceful shutdown does not finish within five minutes, abort and investigate from the console.

```bash
restart_ha() {
  if [[ "$(sudo virsh domstate "$VM" | xargs)" = "shut off" ]]; then
    sudo virsh start "$VM"
  fi
}
trap restart_ha EXIT INT TERM

sudo virsh shutdown "$VM"
for _ in {1..60}; do
  [[ "$(sudo virsh domstate "$VM" | xargs)" = "shut off" ]] && break
  sleep 5
done
test "$(sudo virsh domstate "$VM" | xargs)" = "shut off"

sudo qemu-img check "$DISK"
sudo qemu-img check "$NVRAM"
sudo qemu-img convert -p -O qcow2 -c "$DISK" "$STAGE/$VM.qcow2"
sudo qemu-img convert -p -O qcow2 -c "$NVRAM" "$STAGE/$VM-nvram.qcow2"
sudo qemu-img check "$STAGE/$VM.qcow2"
sudo qemu-img check "$STAGE/$VM-nvram.qcow2"
sudo sh -c "cd '$STAGE' && sha256sum $VM.xml dominfo.txt domblklist.txt domiflist.txt qemu-info.txt nvram-info.txt disk-stat.txt $VM.qcow2 $VM-nvram.qcow2 > SHA256SUMS"

sudo virsh start "$VM"
trap - EXIT INT TERM
test "$(sudo virsh domstate "$VM" | xargs)" = running
sudo chown -R "$(id -u):$(id -g)" "$STAGE"
chmod -R u=rwX,go= "$STAGE"
```

Confirm Home Assistant reaches the login page and the USB device is present before packaging the backup.

### 3. Create the encrypted off-host copy

Run on the off-host computer. `age -p` must prompt for the independently stored recovery passphrase; never put it in an environment variable, command, or log.

```bash
set -euo pipefail
umask 077
STAMP='<timestamp-created-on-nmac>'
OFFHOST="$HOME/homelab-backups/home-assistant/$STAMP"
BUNDLE="$OFFHOST/haos-$STAMP.tar.age"
install -d -m 0700 "$OFFHOST"

ssh nmac "tar --numeric-owner -C /srv/data/backup-staging/home-assistant -cf - '$STAMP'" \
  | age -p -o "$BUNDLE"
chmod 0600 "$BUNDLE"
(cd "$OFFHOST" && sha256sum "$(basename "$BUNDLE")" > "$(basename "$BUNDLE").sha256")
(cd "$OFFHOST" && sha256sum -c "$(basename "$BUNDLE").sha256")
age -d "$BUNDLE" | tar -tf - >/dev/null
```

Keep the on-host staging copy until isolated restore validation passes. It is temporary and is not an off-host backup.

## Validation

`scripts/check-ha-backup-freshness.sh` verifies the newest off-host archive's
outer checksum daily and reports failure to Healthchecks after eight days. This
is a freshness alarm, not restore proof: the cold VM backup and isolated boot
test remain attended maintenance procedures.

### Production validation

- `virsh domstate haos` reports `running` and autostart has not changed.
- Home Assistant responds on port `8123` at `192.168.88.84`.
- The USB adapter `10c4:ea70`, serial `00C3A38C`, is visible in Home Assistant.
- `sha256sum -c SHA256SUMS` passes after decrypting the archive in an isolated temporary directory.
- The outer bundle checksum passes and the encrypted tar listing succeeds.

### Isolated restore test

Perform this from a local-console maintenance window. Do not attach the restored guest to any libvirt network or pass through any host device.

1. Decrypt the bundle into a mode-`0700` temporary directory and verify `SHA256SUMS`.
2. Copy `haos.qcow2` and `haos-nvram.qcow2` to unique paths such as `/var/lib/libvirt/images/haos-restore-test.qcow2` and `/var/lib/libvirt/qemu/nvram/haos-restore-test_VARS.qcow2`; run `qemu-img check` on both.
3. Copy the backed-up XML to `haos-restore-test.xml` and review these mandatory edits before defining it:
   - set `<name>` to `haos-restore-test`;
   - remove `<uuid>` so libvirt creates a new one;
   - point the disk source only at `haos-restore-test.qcow2`;
   - replace the production `<nvram>` element with `<nvram format='qcow2'>/var/lib/libvirt/qemu/nvram/haos-restore-test_VARS.qcow2</nvram>` and remove its `template`/`templateFormat` attributes;
   - remove every `<interface>...</interface>` block;
   - remove every `<hostdev>...</hostdev>` block.
4. Define but do not autostart it, then enforce the isolation gates:

```bash
sudo virsh define haos-restore-test.xml
sudo virsh autostart haos-restore-test --disable
! sudo virsh dumpxml haos-restore-test --inactive | grep -q '/var/lib/libvirt/qemu/nvram/haos_VARS.qcow2'
test -z "$(sudo virsh domiflist haos-restore-test --inactive | awk 'NR>2 && NF')"
! sudo virsh dumpxml haos-restore-test --inactive | grep -q '<hostdev'
test "$(sudo virsh domstate haos-restore-test | xargs)" = "shut off"
sudo virsh start haos-restore-test --paused
sudo virsh resume haos-restore-test
```

5. Validate boot from the libvirt console. Network-based validation is intentionally unavailable.
6. Request graceful shutdown and wait up to five minutes. Never force-stop it automatically. Remove the test definition and disk only after it is confirmed shut off and the restore evidence is recorded.

The restore gate passes only when the isolated guest boots, the checksums pass, and production `haos` remains running and unchanged.

## Rollback

- If shutdown, `qemu-img check`, conversion, or checksum creation fails, stop the backup; the exit trap restarts production `haos` if this procedure stopped it.
- If production does not restart, use the local console to start the unchanged VM and inspect `journalctl -u libvirtd` or `journalctl -u virtqemud`. Do not replace its disk or XML during diagnosis.
- If the restore-test XML exposes a network or host device, leave the test VM shut off, undefine only `haos-restore-test`, correct the copied XML, and repeat the isolation checks.
- A production restore requires a separate approved downtime: preserve the current disk and inactive XML, gracefully stop `haos`, verify the selected archive and qcow2 checksums, restore to a new temporary disk, run `qemu-img check`, preserve ownership and mode from the current disk, atomically replace the disk, define the reviewed XML only if required, and start `haos`. Keep the pre-restore disk until IP, port `8123`, USB, autostart, and application data are validated.
