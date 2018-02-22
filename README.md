# End-To-End Train and Deploy Machine Learning Model on Kubernetes (on GKE)

Using:

 * [kubeflow](https://github.com/kubeflow/kubeflow)
 * [seldon-core](https://github.com/SeldonIO/seldon-core)
 
The example will be the MNIST handwriiten digit classification task.

Requirements:

  * Ability to create a GKE kubernetes cluster
  * A github account
  * A docker account


![MNIST](notebooks/mnist.png "MNIST Digits")


In the follow we will:

 1. [Create a GKE Cluster](#create-a-kubernetes-cluster-on-gke) 
 1. [Setup Kubernetes with kubeflow and seldon-core](#install-tools)
 1. [Fork this project](#clone-this-project-from-github)
 1. [Install kubeflow and seldon-core on your cluster](#install-kubeflow-and-seldon-core-on-your-cluster)
 1. [Do the data science](#data-science)
 1. [Train the model](#train-model)
 1. [Serve the model](#serve-model)
 1. [Get predictions](#get-predictions)

# Create a Kubernetes Cluster on GKE

**For the current demo you will need to create a 1 node cluster** 

This is because the default persistent volume claim on GCP uses a Google Persistent disk which is ReadWriteOnce. For a production setting you should use a file system which is ReadWriteMany.

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
       --num-nodes "1" 
```


# Fork or Clone this Project from github

Fork https://github.com/SeldonIO/kubeflow-seldon-example if you wish to use your github account in the examples below otherwise you can use SeldonIO and just clone:

```bash
git clone https://github.com/SeldonIO/kubeflow-seldon-example
cd kubeflow-seldon-example
```


# Install kubeflow and seldon-core on your cluster

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

There is a pre-packaged ksonnet app that will install kubeflow and seldon-core onto your cluster. First, create a namespace kubeflow-seldon

```bash
kubectl create namespace kubeflow-seldon
```

Next, go into the ksonnet app folder, and remove the default environment and add one for your running cluster.

```bash
cd ks_kubeflow_seldon
ks env rm default
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


## Optional Steps

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

# Data Science

In this demo we provide some example models for MNIST classification. Firstly, a Tensorflow model

 * [A simple TensorFlow model for MNIST classification](models/tf_mnist/train/create_model.py)
 * [A runtime TensorFlow inference module](models/tf_mnist/runtime/DeepMnist.py) that provides a predict method that can be wrapped by seldon-core for deployment.

We also provide a simple scikit-learn random forest model which is used in the notebooks to illustrate A-B tests and multi-armed bandits.

 * [A simple scikit-learn model for MNIST classification](models/sk_mnist/train/create_model.py)
 * [A runtime scikit-learn inference module](models/sk_mnist/runtime/SkMnist.py) that provides a predict method that can be wrapped by seldon-core for deployment.


# Train Model

The training and serving steps are written as Argo jobs. You will need to install the Argo CLI.

On Mac:
```
$ brew install argoproj/tap/argo
```
On Linux:
```
$ curl -sSL -o /usr/local/bin/argo https://github.com/argoproj/argo/releases/download/v2.0.0/argo-linux-amd64
$ chmod +x /usr/local/bin/argo
```

Tp train the model run the Argo workflow

```bash
argo submit workflows/training-tf-mnist-workflow.yaml -p tfjob-version-hack=$RANDOM
```

To understand the workflow in detail and run it with optional parameters to build and push to your own repo see [here](workflows/training-tf-mnist-workflow.md).


To check on your Argo jobs use ```argo list``` and ```argo get``` or the Argo UI discussed above.



# Serve Model

To wrap our model as a Docker container and launch we create:

 * [```models/tf_mnist/runtime/wrap.sh```](models/tf_mnist/runtime/wrap.sh) to wrap model using the seldon-core python wrapper.
 * An Argo workflow [```workflows/serving-tf-mnist-workflow.yaml```](workflows/serving-tf-mnist-workflow.yaml) which:
    * Wraps the runtime model, builds a docker container for it and pushes it to your repo
    * Starts a seldon deployment that will run and expose your model


  * **Change the github-user if you forked the repo**
  * **Change the docker-user to that of for your account.**

```
GITHUB_USER=SeldonIO
DOCKER_USER=<MY_DOCKER_USER>
argo submit workflows/serving-tf-mnist-workflow.yaml -p github-user=${GITHUB_USER} -p docker-user=${DOCKER_USER}
```

 * See [here](workflows/serving-tf-mnist-workflow.md) for detailed comments on workflow

# Get Predictions

The cluster is using [Ambassador](https://www.getambassador.io/) so your model will be exposed by REST and gRPC on the Ambassador reverse proxy.

To expose the ambassador reverse proxy to a local port do

```
kubectl port-forward $(kubectl get pods -n kubeflow-seldon -l service=ambassador -o jsonpath='{.items[0].metadata.name}') -n kubeflow-seldon 8002:80
```

You can test the service by following the example [jupyter notebook](notebooks/example.ipynb)

```
cd notebooks
jupyter notebook
```

# Next Steps

There is a [second model for mnist using an sklearn random forest](models/sk_mnist/train/create_model.py) which can be found in [```models/sk_mnist```](models/sk_mnist/).

 * You start an A-B test using the two models by using the deployment in [```k8s_serving/ab_test_sklearn_tensorflow.json```](k8s_serving/ab_test_sklearn_tensorflow.json)

 
See Next Steps in [jupyter notebook](notebooks/example.ipynb)

