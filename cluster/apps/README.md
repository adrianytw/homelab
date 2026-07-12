# Applications

Authenticated applications use the shared username and password encrypted in
`secrets/sops/app-admin.enc.yaml`. Their application-specific SOPS Secrets must
be regenerated from that file when the shared credential changes.
