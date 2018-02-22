#!/bin/bash

set -o nounset
set -o errexit

ks init ks_kubeflow_seldon --api-spec=version:v1.8.0
cd ks_kubeflow_seldon
ks registry add kubeflow github.com/kubeflow/kubeflow/tree/master/kubeflow 
ks pkg install kubeflow/core 
ks pkg install kubeflow/tf-serving 
ks pkg install kubeflow/tf-job
ks pkg install kubeflow/seldon
ks pkg install kubeflow/argo
ks generate core kubeflow-core --name=kubeflow-core --namespace kubeflow-seldon
ks generate seldon seldon --namespace kubeflow-seldon
ks prototype use io.ksonnet.pkg.argo argo --namespace kubeflow-seldon --name argo
cp ../k8s_setup/pvc.json components/pvc.jsonnet


#kubectl create namespace kubeflow-seldon

ks env rm default
ks env add kubeflow-seldon --namespace kubeflow-seldon
