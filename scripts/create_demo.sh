#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

create_src() {
    mkdir -p ${KUBEFLOW_SRC}
    cd ${KUBEFLOW_SRC}
    curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
}


launch_kubeflow() {
    
    KUBEFLOW_REPO=${KUBEFLOW_SRC} ${KUBEFLOW_SRC}/scripts/kfctl.sh init ${KFAPP} --platform gcp --project ${PROJECT}
    
    cd ${KFAPP}
    ${KUBEFLOW_SRC}/scripts/kfctl.sh generate platform
    ${KUBEFLOW_SRC}/scripts/kfctl.sh apply platform
    ${KUBEFLOW_SRC}/scripts/kfctl.sh generate k8s
    ${KUBEFLOW_SRC}/scripts/kfctl.sh apply k8s

}

launch_seldon() {
    cd ${KUBEFLOW_SRC}/${KFAPP}/ks_app

    ks pkg install kubeflow/seldon
    ks generate seldon seldon
    ks apply default -c seldon
}

add_helm() {
    kubectl -n kube-system create sa tiller
    kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
    helm init --service-account tiller
    kubectl rollout status deploy/tiller-deploy -n kube-system
}

add_nfs_disk() {

    set +e
    FSADDR=$(gcloud beta filestore instances describe ${FS} --project=${PROJECT} --location=${ZONE} --format="value(networks.ipAddresses[0])")
    if [ -z "$FSADDR" ]; then
	echo "Creating filestore NFS volume"
	gcloud beta filestore instances create ${FS}     --project=${PROJECT}     --location=${ZONE}     --tier=STANDARD     --file-share=name="volumes",capacity=1TB     --network=name="default",reserved-ip-range="10.0.0.0/29"
    fi
    set -e

    FSADDR=$(gcloud beta filestore instances describe ${FS} --project=${PROJECT} --location=${ZONE} --format="value(networks.ipAddresses[0])")

    helm install stable/nfs-client-provisioner --name nfs-cp --set nfs.server=${FSADDR} --set nfs.path=/volumes
    kubectl rollout status  deploy/nfs-cp-nfs-client-provisioner -n kubeflow

    kubectl apply -f ${STARTUP_DIR}/nfs-pvc.yaml -n kubeflow
}

add_argo_clusterrole() {
    kubectl create clusterrolebinding my-cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud info --format="value(config.account)")
    kubectl create clusterrolebinding default-admin2 --clusterrole=cluster-admin --serviceaccount=kubeflow:default

}

add_seldon_analytics() {
    helm install seldon-core-analytics --name seldon-core-analytics --set grafana_prom_admin_password=password --set persistence.enabled=false --repo https://storage.googleapis.com/seldon-charts --namespace kubeflow
}

if [ ! -f env.sh ]; then
    echo "Create env.sh by copying env-example.sh"
fi
source env.sh
create_src
launch_kubeflow
launch_seldon
add_helm
add_nfs_disk
add_argo_clusterrole
add_seldon_analytics
