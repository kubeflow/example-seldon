# Example Argo Workflow to dockerize and Train Model

Comments on the [training-tf-mnist-workflow.yaml](training-tf-mnist-workflow.yaml)

## Workflow summary

To dockerize our model training and run it we create:

  * [```models/tf_mnist/train/build_and_push.sh```](../models/tf_mnist/train/build_and_push.sh) that will build an image for our Tensorflow training and push to our repo.
  * An Argo workflow [```workflows/training-tf-mnist-workflow.yaml```](training-tf-mnist-workflow.yaml) is created which:
    * Clones the project from github
    * Runs the build and push script (using DockerInDocker)
    * Starts a kubeflow TfJob to train the model and save the results to the persistent volume


## Workflow parameters

 * version
   * The version tag for the Docker image
 * github-user
   * The github user/org for which to clone this repo/fork
 * github-revision
   * The github revision to use for cloning the repo (can be a branch name)
 * docker-org
   * The Docker host and org/user/project to use when pushing an image to the registry
 * tfjob-version-hack
   * A temporary random integer for the tfjob ID
 * build-push-image
   * Whether to build and push the image to docker registry (true/false)

## Setup For Pushing Images

**To push to your own repo the Docker images you will need to setup your docker credentials as a Kubernetes secret containing a [config.json](https://www.projectatomic.io/blog/2016/03/docker-credentials-store/). To do this you can find your docker home (typically ~/.docker) and run `kubectl create secret generic docker-config --from-file=config.json=${DOCKERHOME}/config.json --type=kubernetes.io/config` to [create a secret](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#registry-secret-existing-credentials).**
