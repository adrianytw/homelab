# RouterOS OpenTofu root

Initial scope is only the two existing DHCP reservations in `leases.tofu`. Before importing, take and review a fresh RouterOS binary backup and export. Trusted HTTPS REST is live through `www-ssl` on port `8443`; `api-ssl` on `8729` is for the separate `apis://` protocol and is not used by this root.

Required environment:

```sh
export TF_VAR_state_passphrase='at least 16 characters; keep outside Git'
export ROS_HOSTURL='https://192.168.88.1:8443'
export ROS_USERNAME='...'
export ROS_PASSWORD='...'
export ROS_CA_CERTIFICATE='/absolute/path/to/routeros-public-ca.pem'
```

`ROS_INSECURE` must remain false/unset. See `imports.md`; a successful import is not complete until `tofu plan -detailed-exitcode` returns `0`.

The committed provider already pins the trusted public CA. Review `runbooks/routeros-rest-tls-review.md`; never export the CA private key.
