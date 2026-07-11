# cert-manager Cloudflare DNS-01

## Purpose

Issue Let's Encrypt certificates using Cloudflare DNS-01.

## Gate

Use staging issuer before production.

## Prerequisites

- Cloudflare token is scoped to `nairdev.com`.
- Token is injected manually or stored with SOPS, not plaintext Git.
- k3s, Traefik, and cert-manager are installed.

## Validation

- Cloudflare token is least-privilege.
- No public private-app A/AAAA records are created.
- Exact-name staging and production certificates are issued.
- Any wildcard covers only a verified homelab-exclusive subzone; `*.nairdev.com` is forbidden because the root zone is shared.
- No public A/AAAA record or WAN forward was created.

## Rollback

Delete failed Certificate/Order/Challenge resources and revoke bad token if exposed.
