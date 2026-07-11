# SOPS Age Bootstrap And Recovery

## Purpose

Bootstrap SOPS with one age identity, keep only the public recipient and encrypted SOPS files in Git, and prove recovery from a passphrase-protected off-Git bundle.

## Prerequisites

- A trusted operator computer and an off-Git backup target are available.
- The recovery passphrase has an independently accessible custody location approved by the owner.
- `curl`, `sha256sum`, and `tar` are installed.
- No terminal recording, shell tracing, or command logging captures prompts or decrypted output.

Until passphrase custody is approved, install and verify the tools only. Do not run `age-keygen`, create `.sops.yaml`, or create a recovery bundle.

## Install And Verify Tools

Install age from Ubuntu and the pinned official SOPS `v3.13.2` Linux AMD64 release. The SOPS binary must match its release checksum before installation.

```bash
set -euo pipefail
sudo apt-get update
sudo apt-get install --yes age

SOPS_VERSION=3.13.2
WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 \
  -o "$WORK/sops" \
  "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"
curl --fail --location --proto '=https' --tlsv1.2 \
  -o "$WORK/checksums.txt" \
  "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.checksums.txt"
(
  cd "$WORK"
  grep " sops-v${SOPS_VERSION}.linux.amd64$" checksums.txt | sed 's#sops-v[^ ]*linux.amd64#sops#' | sha256sum -c -
)
sudo install -m 0755 "$WORK/sops" /usr/local/bin/sops
age --version
sops --version
```

Stop here while the custody gate remains open.

## Bootstrap Procedure

Run only after custody approval. The identity file stays outside the repository under the standard SOPS configuration directory.

```bash
set -euo pipefail
umask 077
KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age"
KEY_FILE="$KEY_DIR/keys.txt"
install -d -m 0700 "$KEY_DIR"
test ! -e "$KEY_FILE"
age-keygen -o "$KEY_FILE"
chmod 0600 "$KEY_FILE"
RECIPIENT="$(age-keygen -y "$KEY_FILE")"
printf '%s\n' "$RECIPIENT"
```

Create `.sops.yaml` at the repository root with the printed public recipient only:

```yaml
creation_rules:
  - path_regex: ^secrets/.*\.sops\.ya?ml$
    age: age1replace_with_the_printed_public_recipient
```

Create and validate one non-secret encrypted fixture. The plaintext value exists only in the pipe and is never written under the repository.

```bash
set -euo pipefail
umask 077
TEST_FILE=secrets/sops/recovery-test.sops.yaml
test ! -e "$TEST_FILE"
printf 'recovery_test: sops-age-round-trip\n' \
  | sops --encrypt --input-type yaml --output-type yaml \
      --filename-override "$TEST_FILE" /dev/stdin > "$TEST_FILE"
SOPS_AGE_KEY_FILE="$KEY_FILE" sops --decrypt "$TEST_FILE" \
  | grep -qx 'recovery_test: sops-age-round-trip'
make check
git diff -- .sops.yaml "$TEST_FILE"
```

Review the diff before committing. It may contain the public age recipient, the non-secret fixture label, and SOPS ciphertext, but no private identity or real secret plaintext.

## Create The Off-Git Recovery Bundle

Run on the trusted operator computer. `age -p` must prompt for the independently stored recovery passphrase; never place the passphrase in an environment variable or command.

```bash
set -euo pipefail
umask 077
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RECOVERY_DIR="$HOME/homelab-backups/age/$STAMP"
BUNDLE="$RECOVERY_DIR/sops-age-identity-$STAMP.tar.age"
install -d -m 0700 "$RECOVERY_DIR"

tar -C "$KEY_DIR" -cf - "$(basename "$KEY_FILE")" | age -p -o "$BUNDLE"
chmod 0600 "$BUNDLE"
printf '%s\n' "$RECIPIENT" > "$RECOVERY_DIR/recipient.txt"
chmod 0600 "$RECOVERY_DIR/recipient.txt"
(cd "$RECOVERY_DIR" && sha256sum "$(basename "$BUNDLE")" > "$(basename "$BUNDLE").sha256")
(cd "$RECOVERY_DIR" && sha256sum -c "$(basename "$BUNDLE").sha256")
```

Copy the encrypted bundle, checksum, and public recipient to the approved off-host medium. The bundle is not proven until the isolated recovery below succeeds from that copy.

## Validation

On a separate trusted computer or isolated temporary environment with a clean repo clone:

```bash
set -euo pipefail
umask 077
BUNDLE='<path-to-off-host-sops-age-bundle>'
REPO='<path-to-clean-homelab-clone>'
TMP="$(mktemp -d)"
trap 'chmod -R u+w "$TMP"; rm -rf -- "$TMP"' EXIT

(cd "$(dirname "$BUNDLE")" && sha256sum -c "$(basename "$BUNDLE").sha256")
age -d "$BUNDLE" | tar -xf - -C "$TMP"
chmod 0600 "$TMP/keys.txt"
test "$(age-keygen -y "$TMP/keys.txt")" = "$(awk '/^[[:space:]]*age: / {print $2; exit}' "$REPO/.sops.yaml")"
SOPS_AGE_KEY_FILE="$TMP/keys.txt" sops --decrypt "$REPO/secrets/sops/recovery-test.sops.yaml" \
  | grep -qx 'recovery_test: sops-age-round-trip'
(
  cd "$REPO"
  make check
)
```

Validation passes only when the off-host checksum, passphrase decryption, public-recipient match, SOPS round trip, and repository secret scan all pass. Destroy the isolated temporary directory after validation; do not copy its raw identity into the repo or a shared shell profile.

## Rollback

- Before any encrypted production secret uses the new recipient, rollback is deletion of the uncommitted `.sops.yaml`, encrypted test fixture, local identity, and failed encrypted bundle.
- After encrypted files use the recipient, do not delete or rotate the identity until every file has been re-encrypted to a replacement recipient and independently recovered.
- If bundle validation fails, keep the original local identity, discard the failed encrypted copy, create a new passphrase-protected bundle, and repeat isolated validation.
- If the raw identity may have entered Git, terminal logs, chat, or another untrusted location, treat it as compromised: remove the exposed artifact, rotate recipients, re-encrypt every affected SOPS file, run `make check`, and invalidate the old recovery bundle only after the replacement is proven.
