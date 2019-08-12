# Helm StaSiCo chart

This is the thinking here:

- A lot of very useful applications consist of only one container.
- Most of them are stateful.
- Most need the same parameters (DB_USER, DB_HOST, etc).
- Most need only one volume attached.
- Writing a Helm chart for _each_ of them is a lot of work, a lot of duplication, and just plainly annoying.

Enter StaSiCo.

With this chart you can deploy a _stateful_, _single-container_ application by just setting a few values in `values.yaml`.

## Features

- Can manage multiple volume mounts
- Can manage multiple ports
- Can manage multiple mounts from _one_ volume into several directories
- And probably more ...

## Requirements

- None.

## Limitations

- Multi-container applications are not supported (stateful _single_ container app, eh? :)
- There is no database included, you have to take care of that yourself

## TL;DR

(this is just an example, the values are not correct for the actual XWiki container ... yet)

```yaml
# values.yaml

applicationName: "example-app"
env:
  DB_USER: xwiki
  DB_HOST: postgres-0

secretEnv:
  DB_PASS: s00pasecr3t

persistence:
  mounts:
    data:
      mountPath: /usr/local/xwiki
  volumes:
    data:
      persistentVolumeClaim:
        claimName: xwiki-main-data

image:
  repository: xwiki

service:
  enabled: true
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  path: /
  hosts:
    - xwiki.my-domain.com
  tls:
    - secretName: tls-com-my-domain-xwiki
      hosts:
        - xwiki.my-domain.com
```

## Parameters

| Parameter                               | Description                                          | Default          |
| --------------------------------------- | ---------------------------------------------------- | ---------------- |
| `affinity`                              | Define a Pod [`affinity`](https://is.gd/AtiuUg)      |  `{}`            |
| `application.name`                      | Define the name of the deployed app                  |  unset, required |
| `image.pullPolicy`                      | container image [`pullPolicy`](https://is.gd/5tfCPv) | `Always`         |
| `image.repository`                      | container image repository                           | unset, required  |
| `image.tag`                             | container image tag                                  | `latest`         |
| `ingress.enabled`                       | Enable ingress                                       | `false`          |
| `ingress.annotations`                   | Define ingress annotations                           | `{}`             |
| `ingress.hosts`                         | Define ingress hosts                                 | unset            |
| `ingress.path`                          | Set ingress path                                     | `/`              |
| `ingress.tls`                           | Define ingress [TLS fields](https://is.gd/SkhKxV)    | `[]`             |
| `livenessProbe`                         | Define a [liveness probe](https://is.gd/z0lJO3)      | unset            |
| `nodeSelector`                          | Define a Pod [`nodeSelector`](https://is.gd/AtiuUg)  | `{}`             |
| `persistence.mounts`                    | see below                                            | unset            |
| `persistence.volumes`                   | see below                                            | unset            |
| `persistence.volumesFromExistingClaims` | see below                                            | unset            |
| `persistence.volumeClaimTemplates`      | see below                                            | unset            |
| `readinessProbe`                        | Define a [readiness probe](https://is.gd/z0lJO3)     | unset            |
| `resources`                             | Define Pod [`resources`](https://is.gd/pZtMlt)       | `{}`             |
| `service.enabled`                       | Whether to create a service                          | `false`          |
| `service.ports`                         | Define the Service's [type](https://is.gd/XvsUf0)    | unset            |
| `service.type`                          | The Service type                                     | `ClusterIP`      |
| `tolerations`                           | Define Pod [`tolerations`](https://is.gd/XaLbxF)     | `[]`             |

## Persistence mounts

The `persistence.mounts` map is directly translated into the `volumeMounts` section of the stateful container.

```yaml
# values.yaml
persistence:
  mounts:
    DATA_IS_THE_NAME:
      mountPath: /usr/local/stasico
      # ... and so on

# WILL BECOME THIS IN THE StatefulSet DEFINITION:

# statefulset.yaml
# [...]
            volumeMounts:
                - name: DATA_IS_THE_NAME
                mountPath: /usr/local/stasico
                # ... and so on
```

## Persistence volumes

The `persistence.volumes` follow the same principle as `persistence.mounts`, just like that:

```yaml
# values.yaml
persistence:
  volumes:
    DATA_IS_THE_NAME:
      persistentVolumeClaim:
        claimName: schmoo-claim

# statefulset.yaml
_
      volumes:
        - name: DATA_IS_THE_NAME
          persistentVolumeClaim:
            claimName: schmoo-claim
```

## Persistence volumesFromExistingClaims

This is a convenience wrapper for existing claims. The example below will produce the exact same result in the StatefulSet as the the previous one.

```yaml
# values.yaml
persistence:
  volumesFromExistingClaims:
    DATA_IS_THE_NAME: schmoo-claim

# statefulset.yaml
_
# SAME RESULT AS LAST EXAMPLE
```

## Persistence volumeClaimTemplates

In case you want to have dynamic provisioning you can use the volumeClaimTemplates map to create several of those. Some examples to show you the general idea of it. You can mix and match the examples, and you can define more than one volumeClaimTemplate in your `values.yaml`.

### Simple volume, just use a size

```yaml
# values.yaml
persistence:
  volumeClaimTemplates:
    data:
      size: 32GiB

# statefulset.yaml -> RESULT
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          app.kubernetes.io/name: example-app
          app.kubernetes.io/instance: test-me
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: "32GiB"
        storageClassName: ""
```

### Use `accessModes` and some `matchLabels`

```yaml
# values.yaml
persistence:
  volumeClaimTemplates:
    data2:
      accessModes:
        - ReadWriteMany
      matchLabels:
        match: me

# statefulset.yaml -> RESULT
  volumeClaimTemplates:
    - metadata:
        name: data2
        labels:
          app.kubernetes.io/name: example-app
          app.kubernetes.io/instance: test-me
      spec:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: "8 GiB"
        selector:
          matchLabels:
            match: me

        storageClassName: ""
```

### Using labels, storageClass and some matchExpressions

````yaml
persistence:
  volumeClaimTemplates:
    data3:
      labels:
        purpose: data
        type: cache
      matchExpressions:
        "i am very": expressive
      storageClass: myStorageClass

# statefulset.yaml -> RESULT
  volumeClaimTemplates:
    - metadata:
        name: data3
        labels:
          app.kubernetes.io/name: example-app
          app.kubernetes.io/instance: test-me
          "app.kubernetes.io/example-app/purpose": "data"
          "app.kubernetes.io/example-app/type": "cache"
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: "8 GiB"
        selector:
          matchExpressions:
            i am very: expressive

        storageClassName: "myStorageClass"```
````
