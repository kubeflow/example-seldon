# Example NFS Setup

The steps below are a consolidated set of steps following the guide [here](https://cloud.google.com/community/tutorials/gke-filestore-dynamic-provisioning).

Set the following variables

  * `FS` : the name of your filestore
  * `PROJECT` : Your Google Project
  * `ZONE` : Your GCP Zone

Create a Google Filestore and install the helm chart for nfs-client-provisioner to use it.
```
  PROJECT=seldon-demos
  FS=mnist-data
  ZONE=europe-west1-b    

  gcloud beta filestore instances create ${FS}     --project=${PROJECT}     --location=${ZONE}     --tier=STANDARD     --file-share=name="volumes",capacity=1TB     --network=name="default",reserved-ip-range="10.0.0.0/29"

  FSADDR=$(gcloud beta filestore instances describe ${FS} --project=${PROJECT} --location=${ZONE} --format="value(networks.ipAddresses[0])")

  helm install stable/nfs-client-provisioner --name nfs-cp --set nfs.server=${FSADDR} --set nfs.path=/volumes
  kubectl rollout status  deploy/nfs-cp-nfs-client-provisioner -n kubeflow
```

To create the NFS claim save the following and apply to your kubernetes cluster

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-1
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 30Gi
```
