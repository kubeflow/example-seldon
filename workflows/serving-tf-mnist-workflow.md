# Example Argo Workflow to dockerize runtime model and deploy it for serving 

Comments on the [serving-tf-mnist-workflow.yaml](serving-tf-mnist-workflow.yaml)

## Workflow Summary

To serve our runtime model we create:

 * [```models/tf_mnist/runtime/wrap.sh```](models/tf_mnist/runtime/wrap.sh) to wrap model using the seldon-core python wrapper.
 * An Argo workflow to:
    * Wrap the runtime model, builds a docker container for it and optionally push it to your repo
    * Starts a seldon deployment that will run and expose your model


## Workflow parameters

 * version
   * The version tag for the Docker image
 * github-user
   * The github user to use to clone this repo
 * github-revision
   * The github revision to use for cloning the repo (can be a branch name)
 * docker-user
   * The Docker user to use when pushing an image to DockerHub
 * build-push-image
   * Whether to build and push the image to an external repo on DockerHub (true/false)





