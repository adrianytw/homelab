# Flux

Flux `v2.9.1` reconciles public `origin/main` over HTTPS. Bootstrap starts with
Glance only; remaining proven resources are added after suspension, fallback,
restart, and drift-repair checks pass. The age identity is installed directly
as the uncommitted `sops-age` Secret in `flux-system`.
