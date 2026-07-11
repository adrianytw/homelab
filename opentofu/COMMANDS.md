# OpenTofu command log

Commands run for the independent RouterOS and AdGuard roots. Secret values are never recorded; `<state-passphrase>` below represents the temporary validation value or the operator's real value.

## Install OpenTofu 1.12.1 — 2026-07-10

```sh
mkdir -p ~/.local/bin
curl -fsSLo /tmp/tofu_1.12.1_linux_amd64.zip https://github.com/opentofu/opentofu/releases/download/v1.12.1/tofu_1.12.1_linux_amd64.zip
curl -fsSLo /tmp/tofu_1.12.1_SHA256SUMS https://github.com/opentofu/opentofu/releases/download/v1.12.1/tofu_1.12.1_SHA256SUMS
grep 'tofu_1.12.1_linux_amd64.zip' /tmp/tofu_1.12.1_SHA256SUMS | sha256sum -c -
unzip -o /tmp/tofu_1.12.1_linux_amd64.zip tofu -d ~/.local/bin
tofu version
```

Outcome: checksum passed; OpenTofu `1.12.1` installed at `~/.local/bin/tofu`.

## Format, initialize, and validate — 2026-07-10

```sh
tofu fmt -recursive opentofu

TF_VAR_state_passphrase='<state-passphrase>' tofu -chdir=opentofu/routeros init -backend=false
TF_VAR_state_passphrase='<state-passphrase>' tofu -chdir=opentofu/adguard init -backend=false

TF_VAR_state_passphrase='<state-passphrase>' tofu -chdir=opentofu/routeros validate
TF_VAR_state_passphrase='<state-passphrase>' tofu -chdir=opentofu/adguard validate
```

Outcome: initialization generated both `.terraform.lock.hcl` files with RouterOS provider `1.99.1` and AdGuard provider `1.7.0`; both configurations validated successfully. The first sandboxed initialization attempt could not reach `registry.opentofu.org`, so it was repeated with approved network access.

No `plan`, `import`, or `apply` command has been run. No RouterOS or AdGuard endpoint was contacted.

## Recovery preparation — 2026-07-11

```sh
ssh -o BatchMode=yes -o ConnectTimeout=5 router '/system identity print'
strings ~/.local/bin/tofu | rg 'encryption_version|encrypted_data'
```

Outcome: read-only SSH reached RouterOS; the state-backup helper checks OpenTofu's encrypted envelope fields. No provider connection, state creation, import, plan, or apply occurred.

```sh
make inventory-router
```

Outcome: exact lease IDs and public TLS/service state were captured in ignored diagnostics. No RouterOS configuration changed.
