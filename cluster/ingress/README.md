# Ingress

Traefik first. Internal only. No WAN exposure by default.

cert-manager is pinned to `v1.21.0`. Install the official release manifest only
after verifying SHA-256
`6e499c3f1ab356abe79a7853911f80cb09c213885bfdf81092fdff142ba63c4a`.
The Cloudflare token Secret is SOPS-encrypted; decrypt it directly into
`kubectl` and never write a plaintext copy.
