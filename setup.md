# Setup kubewflow and seldon-core

## Create a Kubernetes Cluster and persistent Disk on GKE

The persistent disk needs to be called nfs-1.

Example: 

```bash
PROJECT=mnist-classification
ZONE=us-east1-d
CLUSTER=kubeflow-seldon-ml

gcloud beta container --project ${PROJECT} clusters create ${CLUSTER} \
       --zone=${ZONE} \
       --cluster-version "1.9.2-gke.1" \
       --machine-type "n1-standard-8" \
       --image-type "COS" \
       --disk-size "100" \
       --num-nodes "3" 

gcloud compute disks create  --zone=${ZONE} nfs-1 --description="PD to back NFS storage on GKE." --size=1TB

```


## Install kubeflow and seldon-core on your cluster

Install the [ksonnet binary](https://github.com/ksonnet/ksonnet/releases)

You will need to setup a github personal token to stop rate-limiting see [here](https://github.com/ksonnet/ksonnet/blob/master/docs/troubleshooting.md)

Add your token to your .profile.

```
export GITHUB_TOKEN=<token>
```

If using RBAC create a clusterrolebinding for your GCP user and for Argo which uses the default service account:

```
kubectl create clusterrolebinding my-cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud info --format="value(config.account)")
kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=kubeflow-seldon:default
```

There is a pre-packaged ksonnet app that will install kubeflow and seldon-core onto your cluster in the namespace kubeflow-seldon. First, create a namespace kubeflow-seldon

```bash
kubectl create namespace kubeflow-seldon
```

Next, go into the ksonnet app folder, and add your enviroment with the namespace you created.

```bash
cd ks_kubeflow_seldon
ks env add kubeflow-seldon --namespace kubeflow-seldon
```

You should now be able to install everything onto your cluster, run:

```bash
ks apply kubeflow-seldon
```

Wait for everything to come up, check with

```
kubectl get all --namespace kubeflow-seldon
```

If you want to see how the ksonnet app is set up, and thus how you would use it to install kubeflow and seldon-core from scratch you can see the steps in scripts/setup_ksonnet_kubeflow_seldon.sh


### Optional Steps

*Optional*: Port forward to Argo UI

```
kubectl port-forward $(kubectl get pods -n kubeflow-seldon -l app=argo-ui -o jsonpath='{.items[0].metadata.name}') -n kubeflow-seldon 8001:8001
```

Visit http://localhost:8001/timeline

*Optional*: Install seldon-core prometheus and Grafana dashboard

```bash
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
helm install seldon-core-analytics --name seldon-core-analytics --set grafana_prom_admin_password=password --set persistence.enabled=false --repo https://storage.googleapis.com/seldon-charts --namespace kubeflow-seldon
```

Port forward dashboard to local port

```
kubectl port-forward $(kubectl get pods -n kubeflow-seldon -l app=grafana-prom-server -o jsonpath='{.items[0].metadata.name}') -n kubeflow-seldon 3000:3000
```

Visit http://localhost:3000/dashboard/db/prediction-analytics?refresh=5s&orgId=1 and login using "admin" and the password you set above when launching with helm.
