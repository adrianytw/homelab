# Cluster

k3s platform manifests were proven manually before Flux took ownership. Flux
reconciles `cluster/` from public `origin/main`; suspend the affected Flux
Kustomization before using the manual manifests as a recovery fallback.
