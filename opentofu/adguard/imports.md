# AdGuard imports

Export recovery data first. Add and import one observed rewrite at a time. Provider `1.7.0` uses `domain||answer` as the rewrite import ID. Require `tofu plan -detailed-exitcode` exit `0` and an encrypted state backup after each import.

| Resource | AdGuard/provider ID | Imported | Zero-diff plan |
| --- | --- | --- | --- |
| rewrites | `domain||answer` inventory pending | no | no |
| full `adguard_config` singleton | `1` | no | no |

`adguard_config` owns the provider's full supported server configuration, not only DNS fields. Do not declare or import it until every supported field is captured and human review approves that ownership boundary. Managing rewrites alone is the safe default.

cert-manager owns ephemeral `_acme-challenge` records; this root must never declare them.
