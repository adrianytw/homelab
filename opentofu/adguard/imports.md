# AdGuard imports

Export recovery data first. Add and import one observed rewrite at a time, recording its exact provider import ID and requiring `tofu plan -detailed-exitcode` exit `0` after each.

| Resource | AdGuard/provider ID | Imported | Zero-diff plan |
| --- | --- | --- | --- |
| rewrites | inventory pending | no | no |
| singleton DNS configuration | inventory pending | no | no |

Capture every singleton field before declaring or importing it. cert-manager owns ephemeral `_acme-challenge` records; this root must never declare them.
