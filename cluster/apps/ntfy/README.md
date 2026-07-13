# ntfy

Internal notification service at `https://notify.nairdev.com`, with default
access denied and SOPS-encrypted credentials. The human administrator retains
full access; automated alert publishers use a separate `homelab-publisher`
account restricted to write-only access on `homelab-alerts`. Declarative users
removed from `auth-users` are deleted by ntfy, so preserve both entries when
rotating either credential and increment the pod-template credentials revision.
