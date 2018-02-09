{
  global: {
    // User-defined global parameters; accessible to all component and environments, Ex:
    // replicas: 4,
  },
  components: {
    // Component-level parameters, defined initially from 'ks prototype use ...'
    // Each object below should correspond to a component in the components/ directory
    "kubeflow-core": {
      cloud: "null",
      disks: "null",
      jupyterHubAuthenticator: "null",
      jupyterHubServiceType: "ClusterIP",
      name: "kubeflow-core",
      namespace: "default",
      tfDefaultImage: "null",
      tfJobImage: "gcr.io/tf-on-k8s-dogfood/tf_operator:v20180131-cabc1c0-dirty-e3b0c44",
      tfJobUiServiceType: "ClusterIP",
    },
    "seldon-core": {
      apifeImage: "seldonio/apife:0.1.4",
      apifeServiceType: "LoadBalancer",
      engineImage: "seldonio/engine:0.1.4",
      name: "seldon-core",
      namespace: "default",
      operatorImage: "seldonio/cluster-manager:0.1.4",
      operatorJavaOpts: "null",
      operatorSpringOpts: "null",
      withApife: "false",
      withRbac: "true",
    },
    argo: {
      name: "argo",
      namespace: "default",
    },
  },
}
