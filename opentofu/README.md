# OpenTofu

`routeros/` and `adguard/` are independent roots with independent encrypted local state. Run commands from one root at a time with `TF_VAR_state_passphrase` set to a long passphrase kept outside Git.

Initialize and validate without contacting infrastructure:

```sh
TF_VAR_state_passphrase='...' tofu -chdir=opentofu/routeros init -backend=false
TF_VAR_state_passphrase='...' tofu -chdir=opentofu/routeros validate
TF_VAR_state_passphrase='...' tofu -chdir=opentofu/adguard init -backend=false
TF_VAR_state_passphrase='...' tofu -chdir=opentofu/adguard validate
```

Commit each `.terraform.lock.hcl`. Do not use RouterOS plaintext API `8728`, and do not let OpenTofu manage firewall, WireGuard, DNS, or container networking without a separate reviewed project and explicit approval.
