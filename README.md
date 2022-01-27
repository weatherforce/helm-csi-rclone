# helm-csi-rclone

This helm chart helps setting up resources for https://github.com/diseq/csi-rclone storage plugin

**This helm chart is compatible with Kubernetes >= 1.19.x (due to storage.k8s.io/v1 CSIDriver)**

Major changes from [wunderio helm chart](https://github.com/wunderio/charts/tree/master/csi-rclone) are:

* Compatibility with Kubernetes >= 1.19.x
* fully configurable by environment variables
* check mountpoint after rclone forks (rclone forks too fast to be available for the pod)
* Extra volume mount definitions in `csi-controller-rclone`
* More recent version of rclone (1.57.0)

## Usage

1. Either:
    
    a. configure rclone defaults by creating a [secret](https://github.com/wunderio/csi-rclone/blob/master/example/kubernetes/rclone-secret-example.yaml) in current namespace

    b. Or setting credentials via `values.yaml` override.

2. Install `csi-rclone` chart.

    Here is an example of how we instantiate this helm chart: 

    ```bash
    helm upgrade --install --wait release-name csi-rclone \
                --repo "http://tech.weatherforce.org/helm-csi-rclone/charts" \
                --values values.yaml            
    ```

    Here is an axample of a `values.yaml` file:

    ```yaml
    params:
    RCLONE_CACHE_DIR: /mnt
    RCLONE_DIR_CACHE_TIME: "5m"

    nodePlugin:
    rclone:
        resources:
        limits:
            memory: 4Gi
            cpu: 2
        requests:
            memory: 250Mi
            cpu: 250m

    extraVolumes:
        - name: cache-dir
        hostPath:
            type: Directory
            path: /mnt
    extraVolumeMounts:
        - name: cache-dir
        mountPath: /mnt
    ```

3. Create persistent volumes and persistent volume claims:

    ```yaml
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv-test
      labels:
        name: pv-test
    spec:
      capacity:
        storage: 10Gi
      accessModes:
        - ReadWriteMany
      storageClassName: rclone
      persistentVolumeReclaimPolicy: Retain
      csi:
        driver: csi-rclone
        volumeAttributes:
          s3-access-key-id: ""
          s3-secret-access-key: ""
          remote: :s3
          remotePath: noaa-gefs-pds
          s3-provider: AWS
          s3-region: "us-east-1"
          s3-endpoint: ""

    ---

    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: pvc-test
    spec:
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 10Gi
      storageClassName: rclone
      selector:
        matchLabels:
          name: pv-test
    ```

4. Attach to your pod
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
    name: ubuntu
    labels:
        app: ubuntu
    spec:
    containers:
    - image: ubuntu
        command:
        - "sleep"
        - "604800"
        imagePullPolicy: IfNotPresent
        name: ubuntu
        volumeMounts:
        - mountPath: "/mnt/data"
            name: data
    volumes:
        - name: data
        persistentVolumeClaim:
            claimName: pv-test
    restartPolicy: Always
    ```

5. Check mount
    ```shell
    $ kubectl exec -it ubuntu -- bash

    root@ubuntu:/# cd /mnt/data/
    root@ubuntu:/mnt/data# ls -la
    total 686
    -rw-r--r-- 1 root root 153481 Nov 29 19:07 dpkg.log
    -rw-r--r-- 1 root root 274389 Nov 29 21:06 1.mp3
    -rw-r--r-- 1 root root 274389 Nov 29 21:06 2.mp3
    root@ubuntu:/mnt/data#
    ```


## Development

To build a new image (with the latest rclone version): 

* Update the version in the `VERSION` file
* run `make image`

To release a new helm chart:

* Update the default image vesion in `charts/values.yaml`
* run `make helm`
