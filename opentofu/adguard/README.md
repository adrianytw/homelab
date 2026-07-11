# AdGuard OpenTofu root

This root intentionally declares no resources yet. Export AdGuard recovery data and inventory every rewrite before adding declarations. The `adguard_config` singleton owns the provider's full supported server configuration and stays deferred unless every field is captured and that broad ownership is approved. The router-internal `10.0.0.2` address is not a client endpoint, and `adguard.nairdev.com` must not be assumed to route to the UI.

Required environment:

```sh
export TF_VAR_state_passphrase='at least 16 characters; keep outside Git'
export TF_VAR_adguard_host='verified-host:port'
export TF_VAR_adguard_username='...'
export TF_VAR_adguard_password='...'
```

HTTPS is the default. A temporary HTTP provider connection is not accepted for credentialed management.
