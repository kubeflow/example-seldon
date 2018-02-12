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

**If using RBAC create a clusterrolebinding for your GCP user, replacing ```<user-email>``` by the email you are logged into GCP with**

```
kubectl create clusterrolebinding default-admin --clusterrole=cluster-admin --user=<user-email>
```

If using RBAC provide the default serviceaccount with cluster-admin to allow argo to launch manifest. TODO: could be made more restrictive.

```bash
kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=default:default
```

You need to create a ksonnet app and install all components needed by running from the root of the cloned/forked project:

```bash
./scripts/setup_k8s_tools.sh
```

Then apply this app to your cluster

```bash
cd k8s_tools
ks apply default
```

Wait for everything to come up, check with

```
kubectl get all
```

## Optional Steps

*Optional*: Port forward to Argo UI

```
kubectl port-forward $(kubectl get pods -n default -l app=argo-ui -o jsonpath='{.items[0].metadata.name}') -n default 8001:8001
```

Visit http://localhost:8001/timeline

*Optional*: Install seldon-core prometheus and Grafana dashboard

```bash
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
helm install seldon-core-analytics --name seldon-core-analytics --set grafana_prom_admin_password=password --set persistence.enabled=false --repo https://storage.googleapis.com/seldon-charts
```

Port forward dashboard to local port

```
kubectl port-forward $(kubectl get pods -n default -l app=grafana-prom-server -o jsonpath='{.items[0].metadata.name}') -n default 3000:3000
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

We need to add secrets to allow us to push to our docker repo. Create a kubernetes secret of the form shown in the template in ```k8s_setup/docker-credentials-secret.yaml```

On unix you can create base64 encoded versions of your credentials with the [base64](https://linux.die.net/man/1/base64) tool.

Enter the data into a manifest as below:

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
kubectl create -f my_docker_credentials.yaml
```

To dockerize our model training and run it we create:

  * [```models/tf_mnist/train/build_and_push.sh```](models/tf_mnist/train/build_and_push.sh) that will build an image for our Tensorflow training and push to our repo.
  * An Argo workflow [```workflows/training-tf-mnist-workflow.yaml```](workflows/training-tf-mnist-workflow.yaml) is created which:
    * Clones the project from github
    * Runs the build and push script (using DockerInDocker)
    * Starts a kubeflow TfJob to train the model and save the results to the persistent volume

You can launch this workflow with the following:

  * **Change the github-user if you forked the repo**
  * **Change the docker-user to that of for your account.**

```
GITHUB_USER=SeldonIO
DOCKER_USER=<MY_DOCKER_USER>
argo submit workflows/training-tf-mnist-workflow.yaml -p github-user=${GITHUB_USER} -p docker-user=${DOCKER_USER} -p tfjob-version-hack=$RANDOM
```

There is a hack to ensure a random TfJob due to this issue in [kubeflow](https://github.com/tensorflow/k8s/issues/322).

To check on your Argo jobs use ```argo list``` and ```argo get``` or the Argo UI discussed above.

When its finished, delete it, as the the current persistent volume is a GCS disk with ReadOnlyOnce so we need to free the persistent volume claim.

```
argo delete --all
```

 * See [here](workflows/training-tf-mnist-workflow.md) for detailed comments on workflow

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
kubectl port-forward $(kubectl get pods -n default -l service=ambassador -o jsonpath='{.items[0].metadata.name}') -n default 8002:80
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

