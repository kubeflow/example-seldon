# Example Argo Workflow to dockerize and Train Model

Comments on the [training-tf-mnist-workflow.yaml](training-tf-mnist-workflow.yaml)

 * use global parameter for version so this could be part of a CI/CD pipeine on releases
 * Use global parameters to allow running on custom github forks of this repo and custom docker user.
 * Has a parameter to allow a unique name to be given to the TfJob to work around kube-flow [bug](https://github.com/tensorflow/k8s/issues/322).

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: kubeflow-train-
spec:
  entrypoint: workflow
  arguments:
    parameters:
    - name: version
      value: 0.1
    - name: github-user
      value: SeldonIO
    - name: docker-user
      value: seldonio
    - name: tfjob-version-hack
      value: 1
```

 * Use a secret containing the user's Docker credentials

```yaml
  volumes:
  - name: my-secret-vol
    secret:
      secretName: docker-credentials     # name of an existing k8s secret
```

 * Workflow in 2 parts
   * Build and push Docker image for training
   * Run TfJob to do actual training

```yaml
  templates:
  - name: workflow
    steps:
    - - name: build-push 
        template: build-and-push
    - - name: train
        template: tfjob
```

 * Pull the repo from github
 * Run the build_and_push.sh script with Docker credentials from secret
 * use the Docker-in-Docker sidecar provied by Argo

```yaml
  - name: build-and-push
    inputs:
      artifacts:
      - name: argo-source
        path: /src/kubeflow-seldon-example
        git:
          repo: https://github.com/{{workflow.parameters.github-user}}/kubeflow-seldon-example.git
          revision: "master"
    container:
      image: docker:17.10
      command: [sh,-c]
      args: ["cd /src/kubeflow-seldon-example/models/tf_mnist/train ; ./build_and_push.sh {{workflow.parameters.version}} {{workflow.parameters.docker-user}}"]
      env:
      - name: DOCKER_HOST               #the docker daemon can be access on the standard port on localhost
        value: 127.0.0.1
      - name: DOCKER_USERNAME  # name of env var
        valueFrom:
          secretKeyRef:
            name: docker-credentials     # name of an existing k8s secret
            key: username     # 'key' subcomponent of the secret
      - name: DOCKER_PASSWORD  # name of env var
        valueFrom:
          secretKeyRef:
            name: docker-credentials     # name of an existing k8s secret
            key: password     # 'key' subcomponent of the secret
      volumeMounts:
      - name: my-secret-vol     # mount file containing secret at /secret/mountpath
        mountPath: "/secret/mountpath"
    sidecars:
    - name: dind
      image: docker:17.10-dind          #Docker already provides an image for running a Docker daemon
      securityContext:
        privileged: true                #the Docker daemon can only run in a privileged container
      mirrorVolumeMounts: true
```

 * Launch a TFJob to do training
 * Uses Persisten Volume Claim to save trained model parameters

```yaml
    - name: tfjob
    resource:                   #indicates that this is a resource template
      action: create             #can be any kubectl action (e.g. create, delete, apply, patch)
      successCondition: status.state == Succeeded
      manifest: |   #put your kubernetes spec here
       apiVersion: "kubeflow.org/v1alpha1"
       kind: "TFJob"
       metadata: 
         name: mnist-train-{{workflow.parameters.tfjob-version-hack}}
         namespace: "default"
         ownerReferences:
         - apiVersion: argoproj.io/v1alpha1
           kind: Workflow
           controller: true
           name: kubeflow-train
           uid: {{workflow.uid}}
       spec: 
         replicaSpecs: 
           - 
             replicas: 1
             template: 
               spec: 
                 containers: 
                   - 
                     image: "seldonio/deepmnistclassifier_trainer:{{workflow.parameters.version}}"
                     name: "tensorflow"
                     volumeMounts: 
                       - 
                         mountPath: "/data"
                         name: "persistent-storage"
                 restartPolicy: "OnFailure"
                 volumes: 
                   - 
                     name: "persistent-storage"
                     persistentVolumeClaim: 
                       claimName: "ml-data"
             tfReplicaType: "MASTER"
```

