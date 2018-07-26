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

gcloud compute disks create --project=${PROJECT} --zone=${ZONE} nfs-1 --description="PD to back NFS storage on GKE." --size=1TB

```


## Install kubeflow and seldon-core onto your cluster

Install the [ksonnet binary](https://github.com/ksonnet/ksonnet/releases).

Note:

  * The demo has been tested with ksonnet 0.9.1 and 0.9.2
  * The demo does **NOT** work with the latest alpha release of ksonnet 0.10.0.alpha.1


You will need to setup a github personal token to stop rate-limiting see [here](https://github.com/ksonnet/ksonnet/blob/master/docs/troubleshooting.md)

Add your token to your .profile.

```
export GITHUB_TOKEN=<token>
```

Create a namespace kubeflow-seldon

```bash
kubectl create namespace kubeflow-seldon
```

If using RBAC create a clusterrolebinding for your GCP user and for Argo which uses the default service account:

```
kubectl create clusterrolebinding my-cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud info --format="value(config.account)")
kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=kubeflow-seldon:default
```

Install kubeflow - for details see [here](https://www.kubeflow.org/docs/about/user_guide)

```
export KUBEFLOW_VERSION=0.2.2
export KUBEFLOW_KS_DIR=</path/to/store/your/ksonnet/application>
export KUBEFLOW_DEPLOY=false
curl https://raw.githubusercontent.com/kubeflow/kubeflow/v${KUBEFLOW_VERSION}/scripts/deploy.sh | bash
```

Install seldon and argo.

```
ks generate seldon seldon --namespace kubeflow-seldon
ks prototype use io.ksonnet.pkg.argo argo --namespace kubeflow-seldon --name argo
```

Setup the particular config settings. We set usage metrics to true : skip this step if you do not wish to contribute usage metrics. We also specify the name of the NFS volume we created.

```bash
ks param set kubeflow-core reportUsage true
ks param set kubeflow-core usageId $(uuidgen)
ks param set kubeflow-core disks nfs-1
```

To create all the components run the following command

```bash
ks apply default
```

### Optional Steps

*Optional*: Update your kubectl to use the namespace by default

```bash
kubectl config set-context $(kubectl config current-context) --namespace=kubeflow-seldon
```


*Optional*: Port forward to Argo UI

```
kubectl port-forward $(kubectl get pods -n kubeflow-seldon -l app=argo-ui -o jsonpath='{.items[0].metadata.name}') -n kubeflow-seldon 8001:8001
```

Visit http://localhost:8001/timeline

### Grafana Dashboard

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
