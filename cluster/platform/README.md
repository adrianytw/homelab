# Platform

`test-workload.yaml` is the only prepared workload. Apply it manually after k3s, storage, and firewall validation:

```sh
kubectl apply -f cluster/platform/test-workload.yaml
kubectl -n homelab-test rollout status deployment/web
curl --fail --resolve test.k8s.nairdev.com:80:192.168.88.20 http://test.k8s.nairdev.com/
```

Delete and recreate the pod, then verify the same content to prove the PVC. DNS and TLS remain separate approval gates.
