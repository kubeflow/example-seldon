STARTUP_DIR="$( cd "$( dirname "$0" )" && pwd )"
KFAPP=my-kubeflow    
PROJECT=seldon-demos
KUBEFLOW_SRC=${STARTUP_DIR}/kubeflow_src
FS=mnist-data
ZONE=europe-west1-b
# Next two lines are set from values created as discussed in https://www.kubeflow.org/docs/started/getting-started-gke/
export CLIENT_ID=<your-client-id>
export CLIENT_SECRET=<your-secret>
export KUBEFLOW_TAG=v0.5.1
