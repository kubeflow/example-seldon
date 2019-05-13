# Example Argo Workflow to dockerize runtime model and deploy it for serving

Comments on the [serving-tf-mnist-workflow.yaml](serving-tf-mnist-workflow.yaml)

## Workflow Summary

To serve our runtime model we create:

 * [```models/tf_mnist/runtime/Dockerfile```](../models/tf_mnist/runtime/Dockerfile) to wrap model using the seldon-core python wrapper.
 * An Argo workflow to:
    * Wrap the runtime model, builds a docker container for it and optionally push it to your repo
    * Optionally starts a seldon deployment that will run and expose your model


## Workflow parameters

 * version
   * The version tag for the Docker image
 * github-user
   * The github user to use to clone this repo/fork
 * github-revision
   * The github revision to use for cloning the repo (can be a branch name)
 * docker-org
   * The Docker host and org/user/project to use when pushing an image to the registry
 * build-push-image
   * Whether to build and push the image to docker registry (true/false)
 * deploy-model
   * Whether to start a seldon deployment to run and expose your model (true/false)
