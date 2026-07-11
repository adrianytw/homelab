# RouterOS OpenTofu root

Initial scope is only the two existing DHCP reservations in `leases.tofu`. Before importing, take and review a fresh RouterOS binary backup and export, then obtain explicit approval to configure trusted HTTPS REST access.

Required environment:

```sh
export TF_VAR_state_passphrase='at least 16 characters; keep outside Git'
export ROS_HOSTURL='https://192.168.88.1'
export ROS_USERNAME='...'
export ROS_PASSWORD='...'
export ROS_CA_CERTIFICATE='/absolute/path/to/routeros-public-ca.pem'
```

`ROS_INSECURE` must remain false/unset. See `imports.md`; a successful import is not complete until `tofu plan -detailed-exitcode` returns `0`.
