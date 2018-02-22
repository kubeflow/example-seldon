#!/bin/bash

set -o nounset
set -o errexit

ks init k8s_tools --api-spec=version:v1.8.0
cd k8s_tools
ks registry add kubeflow github.com/kubeflow/kubeflow/tree/master/kubeflow 
ks pkg install kubeflow/core 
ks pkg install kubeflow/tf-serving 
ks pkg install kubeflow/tf-job 
ks generate core kubeflow-core --name=kubeflow-core
ks registry add seldon-core github.com/SeldonIO/seldon-core/tree/master/seldon-core
ks pkg install seldon-core/seldon-core
ks generate seldon-core seldon-core --withApife=false --withRbac=true
ks pkg install kubeflow/argo
ks prototype use io.ksonnet.pkg.argo argo --namespace default --name argo
cp ../k8s_setup/pvc.json components/pvc.jsonnet
