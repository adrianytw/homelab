# DNS Failure Recovery

## Purpose

Recover client DNS if RouterOS-to-AdGuard forwarding fails.

## Gate

Do not change DHCP DNS without current RouterOS backup/export.

## Prerequisites

- Admin access to RouterOS.
- Current DNS and DHCP settings captured.
- A temporary client-side fallback DNS is known.

## Validation

- Router resolves through `192.168.88.1`.
- Client resolves `nairdev.com` rewrite.
- Upstream DNS resolves public names.

## Rollback

Temporarily point a client at known public DNS or restore previous RouterOS DNS settings.
