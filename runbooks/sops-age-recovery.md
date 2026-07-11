# SOPS Age Key Recovery

## Purpose

Recover encrypted secrets after host loss.

## Prerequisites

- Encrypted recovery bundle or offline age key exists.
- Passphrase/key material is available outside Discord/plaintext Git.
- Repo clone is available.

## Validation

- Age key decrypts a test SOPS file.
- Recovery bundle is encrypted.

## Rollback

Use offline recovery copy. Never commit raw private key.
