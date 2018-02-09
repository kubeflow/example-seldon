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
 1. [Install kubeflow and seldon-core on your cluster](#install-kubeflow-and-seldon-core-on-your-cluster)
 1. [Do the data science](#data-science)
 1. [Train the model](#train-model)
 1. [Serve the model](#serve-model)
 1. [Get predictions](#get-predictions)

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

If using RBAC create a clusterrolebinding for your GCP user

```
kubectl create clusterrolebinding default-admin --clusterrole=cluster-admin --user=<user-email>
```

If using RBAC provide the default serviceaccount with cluster-admin to allow argo to launch manifest. TODO: could be made more restrictive.

```bash
kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=default:default
```

The ksonnet packages have already been setup so you can simply do:

```bash
cd k8s_tools && ks apply default
```

  * The steps to set up this ksonnet app are show [here](scripts/setup_k8s_tools.sh)
  * A [persistent volume claim](https://github.com/SeldonIO/seldon-core) is added to the components.


# Data Science

 * [A simple model for MNIST](model/train/create_model.py)
 * [A runtime inference module](model/runtime/DeepMnist.py) that provides a predict method that can be wrapped by seldon-core for deployment.

# Train Model

We need to add secrets to allow us to push to our docker repo. Create a kubernetes secret of the form shown in the template in ```k8s_setup/docker-credentials-secret.yaml```

```yaml
apiVersion: v1
data:
  password: <base 64 password>
  username: <base 64 username>
kind: Secret
metadata:
  name: docker-credentials
  namespace: default
type: Opaque
```

Apply the secret:

```bash
kubectl create my_docker_credentials.yaml
```

To dockerize our model training and run it we create:

  * [```model/train/build_and_push.sh```](model/train/build_and_push.sh) that will build an image for our Tensorflow training and push to our repo.
  * An Argo workflow [```training-mnist-workflow.yaml```](training-mnist-workflow.yaml) is created which:
    * Clones the project from github
    * Runs the build and push script (using DockerInDocker)
    * Starts a kubeflow TfJob to train the model and save the results to the persistent volume

You can launch this workflow with the following:

```
argo submit training-mnist-workflow.yaml -p tfjob-version-hack=$RANDOM
```

There is a hack to ensure a random TfJob due to this issue in [kubeflow](https://github.com/tensorflow/k8s/issues/322).

When its finished, delete it, as the the current persistent volume is a GCS disk with ReadOnlyOnce so we need to free the persistent volume claim.


# Serve Model

To wrap our model as a Docker container and launch we create:

 * [```model/runtime/wrap.sh```](model/runtime/wrap.sh) to wrap model using the seldon-core python wrapper.
 * An Argo workflow [```serving-mnist-workflow.yaml```] which:
    * Wraps the runtime model, builds a docker container for it and pushes it to your repo
    * Starts a seldon deployment that will run and expose your model

```
argo submit serving-mnist-workflow.yaml
```


# Get Predictions

The cluster is using [Ambassador](https://www.getambassador.io/) so your model will be exposed by REST and gRPC on the Ambassador reverse proxy.

To expose the ambassador reverse proxy to a local port do

```
kubectl port-forward $(kubectl get pods -n default -l service=ambassador -o jsonpath='{.items[0].metadata.name}') -n default 8002:80
```

You can test the service by following the example [jupyter notebook](notebooks/example.ipynb)

