# End-To-End Train and Deploy Machine Learning Model on Kubernetes (on GKE)

Using:

 * [kubeflow](https://github.com/kubeflow/kubeflow)
 * [seldon-core](https://github.com/SeldonIO/seldon-core)
 
The example will be the MNIST handwriiten digit classification task.

![MNIST](notebooks/mnist.png "MNIST Digits")

In the follow we will:

 1. [Do the data science](#data-science)
 1. [Train the model](#train-model)
 1. [Serve the model](#serve-model)
 1. [Get predictions](#get-predictions)

**We assume you have a running kubernetes cluster with [kubeflow](https://github.com/kubeflow/kubeflow) installed along with seldon-core.** If you wish to run a preconfigured kubeflow and seldon that is packaged as part of this project see details [here](setup.md)


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

 
See Next Steps in [jupyter notebook](notebooks/example-seldon.ipynb)

