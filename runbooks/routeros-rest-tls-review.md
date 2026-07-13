# RouterOS HTTPS REST TLS Review

## Purpose

Record and validate the approved local CA and server certificate used by
OpenTofu HTTPS REST on RouterOS `www-ssl:8443`. The trusted configuration is
live; the commands below are historical reference and must not be rerun as an
apply script.

## Prerequisites

- Take and review a fresh encrypted binary backup and text export.
- Confirm SSH and local-console/WinBox recovery access.
- Capture `/certificate print detail` and `/ip service print detail where name="www-ssl"`.

Proposed RouterOS commands:

```routeros
/certificate add name=homelab-router-ca-template common-name=homelab-router-ca days-valid=3650 key-size=2048 key-usage=key-cert-sign,crl-sign
/certificate sign homelab-router-ca-template name=homelab-router-ca
/certificate add name=homelab-router-rest-template common-name=192.168.88.1 subject-alt-name=IP:192.168.88.1 days-valid=825 key-size=2048 key-usage=digital-signature,key-encipherment,tls-server
/certificate sign homelab-router-rest-template ca=homelab-router-ca name=homelab-router-rest
/ip service set [find where name="www-ssl" and dynamic=no] port=8443 certificate=homelab-router-rest disabled=no address=192.168.88.0/24,192.168.36.0/24
/certificate export-certificate homelab-router-ca file-name=homelab-router-ca type=pem
```

Export only `homelab-router-ca.crt`; never export a private key. Remove the temporary router file after copying the public certificate.

## Validation

- `www-ssl:8443` remains restricted to `192.168.88.0/24,192.168.36.0/24`.
- The server certificate is valid for IP SAN `192.168.88.1`.
- A REST request succeeds with `curl --cacert` and never `-k`.
- SSH, DHCP, client DNS through `192.168.88.1`, and AdGuard forwarding remain unchanged.
- `api-ssl:8729` is not required or modified for this REST configuration.

## Rollback

Restore the captured previous `www-ssl` port/certificate values and verify
HTTPS/SSH. Only then remove `homelab-router-rest` and `homelab-router-ca` if no
other certificate chains to that CA. Restore the fresh RouterOS backup if
service access cannot be recovered safely.
