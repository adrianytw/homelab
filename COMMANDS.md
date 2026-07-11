# Command log

Meaningful repository-wide commands run during implementation. Secrets and transient values are replaced with placeholders; subsystem-specific commands live with that subsystem.

## 2026-07-10

```sh
graphify query "What is already implemented for the actionable homelab delivery plan, especially README, OpenTofu, Ansible, backups, k3s, DNS, and TLS?"
rg --files -g '!graphify-out/**' | sort
git status --short
git diff --cached --stat
git remote -v
git branch --show-current
rg -n -i --hidden -g '!graphify-out/**' -g '!.git/**' '(plaintext-secret-signatures)' .
make check
git diff --check
```

Outcome: repository checks and the plaintext-secret signature scan passed after the OpenTofu files were added. The existing staged `.codex` files remain separate from the homelab work.

See `opentofu/COMMANDS.md` for OpenTofu installation, initialization, and validation.
