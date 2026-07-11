# Home Assistant VM Restore

## Purpose

Restore libvirt Home Assistant VM.

## Known State

- VM: `haos`
- Disk: `/var/lib/libvirt/images/haos.qcow2`
- Current lease: `192.168.88.84`
- USB: `10c4:ea70`, serial `00C3A38C`

## Prerequisites

- VM disk backup and libvirt XML export exist.
- USB adapter is physically attached.
- DNS rewrite for `ha.nairdev.com` is known.

## Validation

- VM boots.
- USB passthrough works.
- `ha.nairdev.com` resolves to VM IP.

## Rollback

Restore previous qcow2 and libvirt XML from backup.
