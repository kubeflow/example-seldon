#!/bin/bash

set -o nounset
set -o errexit

#kubectl create clusterrolebinding my-cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud info --format="value(config.account)")
#kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=kubeflow-seldon:default


ks init wip_ks_kubeflow_seldon --api-spec=version:v1.8.0
cd wip_ks_kubeflow_seldon
ks registry add kubeflow github.com/kubeflow/kubeflow/tree/master/kubeflow 
ks pkg install kubeflow/core 
ks pkg install kubeflow/tf-job
ks pkg install kubeflow/seldon
ks pkg install kubeflow/argo
ks generate core kubeflow-core --name=kubeflow-core --namespace kubeflow-seldon
ks param set kubeflow-core reportUsage true
ks param set kubeflow-core usageId $(uuidgen)
ks generate seldon seldon --namespace kubeflow-seldon
ks prototype use io.ksonnet.pkg.argo argo --namespace kubeflow-seldon --name argo
ks param set kubeflow-core disks nfs-1


ks env add cloud
ks param set kubeflow-core cloud gke --env=cloud

KF_ENV=cloud
NAMESPACE=kubeflow-seldon
kubectl create namespace ${NAMESPACE}
ks env set ${KF_ENV} --namespace ${NAMESPACE}

ks apply ${KF_ENV}

