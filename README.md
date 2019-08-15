# Helm StaSiCo chart

This is the thinking here:

- A lot of very useful applications consist of only one container. Most of them are stateful.
- Most need a couple of env variables, so this should be simple.
- Most need only one volume attached, so this should be simple.
- Writing a Helm chart for _each_ of them is a lot of work, a lot of duplication, and a LOT of duplicate code.

**Enter StaSiCo.**

With this chart you can deploy a _stateful_, _single-container_ application by just setting a few values in `values.yaml`. It's 15% more complex than a hand-tailored helm chart, but a _lot_ less redundant than writing the same helm boilerplate for each custom chart, and _way_ easier to handle (only one chart to test, not many).

## Features

- Can manage multiple volume mounts
- Can manage multiple ports
- Can manage multiple mounts from _one_ volume into several directories
- Simplified mount point management, simplified volume management from existing claims
- And probably more ...

## Requirements

- None.

## Limitations

- Multi-container applications are not supported (stateful _single_ container app, eh? :)
- There is no database included, you have to take care of that yourself

## TL;DR

This is a _working_ (!) Atlassian Confluence installation on K8S.

```yaml
# values.yaml
applicationName: confluence

image:
  repository: atlassian/confluence-server
  tag: 6.6.4-alpine

container:
  ports:
    http:
      containerPort: 8090
      protocol: TCP
    synchrony:
      containerPort: 8091
      protocol: TCP
  env:
    CATALINA_CONNECTOR_PROXYNAME: confluence.mydomain.com
    CATALINA_CONNECTOR_PROXYPORT: "443"
    CATALINA_CONNECTOR_SCHEME: https
    CATALINA_CONNECTOR_SECURE: "true"
    JVM_MINIMUM_MEMORY: "1024m"
    JVM_MAXIMUM_MEMORY: "1024m"
    JVM_SUPPORT_RECOMMENDED_ARGS: -XX:MaxMetaspaceSize=512m -XX:MaxDirectMemorySize=10m -Dsynchrony.memory.max=0m

persistence:
  simpleMounts:
    data: /var/atlassian/application-data/confluence
  volumeClaimTemplates:
    data:
      size: 32Gi
      storageClass: default

service:
  enabled: true
  ports:
    http:
      port: 80
      targetPort: http
      protocol: TCP
    synchrony:
      port: 8091
      targetPort: synchrony
      protocol: TCP

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    certmanager.k8s.io/cluster-issuer: letsencrypt-prod
  path: /
  hosts:
    - confluence.my-domain.com
  tls:
    - secretName: tls-confluence-my-domain
      hosts:
        - confluence.my-domain.com
```

## Parameters

| Parameter                               | Description                                          | Default          |
| --------------------------------------- | ---------------------------------------------------- | ---------------- |
| `affinity`                              | Define a Pod [`affinity`](https://is.gd/AtiuUg)      |  `{}`            |
| `application.name`                      | Define the name of the deployed app                  |  unset, required |
| `container.ports`                       | Configure the container's ports (see also below)     | `{}`             |
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
| `persistence.simpleMount                | simplified key->value mount definitions, see below   | unset            |
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
  simpleMounts:
    # as many as you like
    MY_SIMPLE_MOUNT: /usr/local/stasico
  mounts:
    # as many as you like, will be used exactly as is
    - name: MY_MOUNT
      mountPath: /my/mount/path
      subPath: IAmASubPath

# WILL BECOME THIS IN THE StatefulSet OBJECT:

# statefulset.yaml
spec:
  template:
    spec:
      containers:
        - name: my-container
          # this will be generated
          volumeMounts:
            - name: MY_SIMPLE_MOUNT
              mountPath: /usr/local/stasico
            - name: MY_MOUNT
              mountPath: /my/mount/path
              subPath: IAmASubPath
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
spec:
  template:
    spec:
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
      size: 32Gi

# statefulset.yaml -> RESULT
spec:
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
            storage: "32Gi"
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
spec:
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
            storage: "8Gi"
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
spec:
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
            storage: "8Gi"
        selector:
          matchExpressions:
            i am very: expressive

        storageClassName: "myStorageClass"```
````

## Container ports

The ports of a container are configured through `container.ports`, which follows the same `name_key -> object` principle as the previous examples.

````yaml
# values.yaml
container:
  ports:
    http:
      containerPort: 8080
      protocol: TCP

# statefulset.yaml:
spec:
  template:
    spec:
      containers:
        - name: my-container
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP```
````
