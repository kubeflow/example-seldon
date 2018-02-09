# End-To-End Train and Deploy Machine Learning Model on Kubernetes (on GKE)

Using:

 * [kubeflow](https://github.com/kubeflow/kubeflow)
 * [seldon-core](https://github.com/SeldonIO/seldon-core)
 
The example will be the MNIST handwriiten digit classification task.

![MNIST](notebooks/mnist.png "MNIST Digits")


In the follow we will:

 1. [Create a GKE Cluster](#create-a-kubernetes-cluster-on-gke) 
 1. [Setup Kubernetes with kubeflow and seldon-core](#install-tools)
 1. [Clone this project](#clone-this-project-from-github)


# Create a Kubernetes Cluster on GKE

Example: 

```bash
PROJECT=mnist-classification
ZONE=us-east1-d
CLUSTER=kubeflow-seldon-ml

gcloud --project=${PROJECT} container clusters create \
       --zone=${ZONE} \
       --machine-type=n1-standard-8 \
       --cluster-version=1.8.4-gke.1 \
       ${CLUSTER}
```



# Install Tools

  * Install [ksonnet binary](https://github.com/ksonnet/ksonnet/releases)
    * Needed to install kubeflow and seldon-core on your cluster
  * Install [Argo binary](https://github.com/argoproj/argo/blob/master/demo.md)
    * Needed to run the CI/CD workflows



# Clone this Project from github

```bash
git clone https://github.com/SeldonIO/kubeflow-seldon-example
```




# Install kubeflow and seldon-core on your cluster

## RBAC Setup
If using RBAC create a clusterrolebinding for your GCP user

```
kubectl create clusterrolebinding default-admin --clusterrole=cluster-admin --user=<user-email>
```

If using RBAC provide the default serviceaccount with cluster-admin to allow argo to launch manifest. TODO: could be made more restrictive.

```bash
kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=default:default
```

## Launch tools


The ksonnet packages have already been setup so you can simply do:

```bash
cd k8s_tools && ks apply default
```

### Details

  * The steps to set up this ksonnet app are show in ```scripts/setup_k8s_tools.sh```
  * A persistent volume claim is created - see ```k8s_tools/components/pvc.jsonnet```


### Data Science

 * [A simple model for MNIST](model/train/create_model.py)
 * [A runtime inference module](model/runtime/DeepMnist.py) that provides a predict method that can be wrapped by seldon-core for deployment can be found 

