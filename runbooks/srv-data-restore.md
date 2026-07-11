# /srv/data Restore

## Purpose

Restore persistent app data.

## Prerequisites

- Backup archive exists and decrypts.
- Target service is stopped.
- Destination path under `/srv/data/<service>` is known.

## Validation

- Ownership and permissions match app expectations.
- App starts from restored data.
- One low-risk app restore is tested before critical app reliance.

## Rollback

Stop app, move restored directory aside, restore previous snapshot.
