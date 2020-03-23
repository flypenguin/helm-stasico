# v2.1.0

- [ADD] enable non-stateful deployments (use 'persistence.enabled: false')
- [FIX] fix base64 encoding for secrets

# v2.0.1

- add `container.name` setting for compatibility (set to `stasico` if you have a pre-2.0 chart version)

# v2.0.0

- [BREAKING] rename `persistence.volumeClaimTemplates.<name>.storageClass` to `... .storageClassName` to align with baseline k8s
- [BREAKING] standard container name in `StatefulSet` is now the release name, not "`stasico`"
- Helm aborts on most critical chart errors now

