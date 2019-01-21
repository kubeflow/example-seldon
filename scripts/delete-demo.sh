#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail


if [ ! -f env.sh ]; then
    echo "Create env.sh by copying env-example.sh"
fi
source env.sh

cd ${KUBEFLOW_SRC}/${KFAPP}
${KUBEFLOW_SRC}/scripts/kfctl.sh  delete all
