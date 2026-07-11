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

## 2026-07-11

```sh
git add AGENTS.md .gitignore COMMANDS.md Makefile README.md ansible apps cluster diagnostics docs opentofu runbooks scripts secrets
git diff --cached --check
git commit --only -m "chore: establish homelab baseline" -- AGENTS.md .gitignore COMMANDS.md Makefile README.md ansible apps cluster diagnostics docs opentofu runbooks scripts secrets
mkdir -p ~/homelab-backups/git
git clone --mirror /home/nairda/homelab ~/homelab-backups/git/homelab.git
git push -u origin main
```

Outcome: baseline commit `3afc09a` was pushed to `origin/main`; the bare off-repository mirror was created. The `.codex` tooling remained staged but excluded from the commit.

## Unattended preparation — 2026-07-11

```sh
graphify query "Which files should change for unattended task tracking, OpenTofu recovery, host inventory, and runbook hardening?"
make inventory-router
make inventory-nmac
make check
make ansible-check
TF_VAR_state_passphrase='<state-passphrase>' tofu -chdir=opentofu/routeros validate
TF_VAR_state_passphrase='<state-passphrase>' tofu -chdir=opentofu/adguard validate
```

Outcome: read-only inventories completed; shell, backup self-test, Ansible, OpenTofu, YAML, and secret checks passed. No infrastructure mutation, apply, key generation, or GitHub push occurred.

The approved local-only staging step was rejected by the execution environment because workspace escalation credits were exhausted. The Git index, bare mirror, and GitHub remote were not changed.

A later retry succeeded; the verified homelab paths were staged separately from `.codex` for local-only commits.

```sh
git commit --only -m "docs: add unattended operations runbooks" -- <documentation-paths>
git commit --only -m "feat: prepare guarded homelab automation" -- <automation-paths>
git -C ~/homelab-backups/git/homelab.git remote update
```

Outcome: local commits `4ca1517` and `9800d52` were created and mirrored. `origin/main` was not pushed.
