# Example Argo Workflow to dockerize runtime model and deploy it for serving 

Comments on the [serving-tf-mnist-workflow.yaml](serving-tf-mnist-workflow.yaml)


 * Use global parameters to allow running on custom github forks of this repo and custom docker user.
 * use global parameter for version so this could be part of a CI/CD pipeine on releases

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: seldon-deploy-
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
```

 * Use a secret containing the user's Docker credentials

```yaml
  volumes:
  - name: my-secret-vol
    secret:
      secretName: docker-credentials     # name of an existing k8s secret
```
   
 * Workflow has two parts
   * Build and push runtime Docker image
   * Launch runtime on Kubernets

```yaml   
templates:
  - name: workflow
    steps:
    - - name: build-push 
        template: build-and-push
    - - name: serve
        template: seldon
```

 * Pull repo from github
 * Run wrap.sh to wrap the runtime model using Seldon python wrappers
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
      args: ["cd /src/kubeflow-seldon-example/models/tf_mnist/runtime ; ./wrap.sh {{workflow.parameters.version}} {{workflow.parameters.docker-user}}"]
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
      # mirrorVolumeMounts will mount the same volumes specified in the main container
      # to the sidecar (including artifacts), at the same mountPaths. This enables
      # dind daemon to (partially) see the same filesystem as the main container in
      # order to use features such as docker volume binding.
      mirrorVolumeMounts: true
```

 * Launch runtime model as SeldonDeployment
 * Uses Persisten Volume Claim to load model parameters

```yaml
  - name: seldon
    resource:                   #indicates that this is a resource template
      action: apply             #can be any kubectl action (e.g. create, delete, apply, patch)
      #successCondition: ? 
      manifest: |   #put your kubernetes spec here
       apiVersion: "machinelearning.seldon.io/v1alpha1"
       kind: "SeldonDeployment"
       metadata: 
         labels: 
           app: "seldon"
         name: "mnist-classifier"
       spec: 
         annotations: 
           deployment_version: "v1"
           project_name: "MNIST Example"
         name: "mnist-classifier"
         predictors: 
           - 
             annotations: 
               predictor_version: "v1"
             componentSpec: 
               spec: 
                 containers: 
                   - 
                     image: "seldonio/deepmnistclassifier_runtime:{{workflow.parameters.version}}"
                     imagePullPolicy: "Always"
                     name: "mnist-classifier"
                     volumeMounts: 
                       - 
                         mountPath: "/data"
                         name: "persistent-storage"
                 terminationGracePeriodSeconds: 1
                 volumes: 
                   - 
                     name: "persistent-storage"
                     volumeSource: 
                       persistentVolumeClaim: 
                         claimName: "ml-data"
             graph: 
               children: []
               endpoint: 
                 type: "REST"
               name: "mnist-classifier"
               type: "MODEL"
             name: "mnist-classifier"
             replicas: 1
```

