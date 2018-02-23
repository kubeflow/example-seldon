# Example Argo Workflow to dockerize and Train Model

Comments on the [training-tf-mnist-workflow.yaml](training-tf-mnist-workflow.yaml)

## Workflow summary

To dockerize our model training and run it we create:

  * [```models/tf_mnist/train/build_and_push.sh```](models/tf_mnist/train/build_and_push.sh) that will build an image for our Tensorflow training and push to our repo.
  * An Argo workflow [```workflows/training-tf-mnist-workflow.yaml```](workflows/training-tf-mnist-workflow.yaml) is created which:
    * Clones the project from github
    * Runs the build and push script (using DockerInDocker)
    * Starts a kubeflow TfJob to train the model and save the results to the persistent volume


## Workflow parameters

 * version
   * The version tag for the Docker image
 * github-user
   * The github user to use to clone this repo
 * github-revision
   * The github revision to use for cloning the repo (can be a branch name)
 * docker-user
   * The Docker user to use when pushing an image to DockerHub
 * tfjob-version-hack
   * A temporary random integer for the tfjob ID
 * build-push-image
   * Whether to build and push the image to an external repo on DockerHub (true/false)

## Setup For Pushing Images

We need to add secrets to allow us to push to our docker repo. Create a kubernetes secret of the form shown in the template in ```k8s_setup/docker-credentials-secret.yaml.tpl```

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

