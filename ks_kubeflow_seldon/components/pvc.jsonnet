{
    "kind": "PersistentVolumeClaim",
    "apiVersion": "v1",
    "metadata": {
        "name": "ml-data",
    },
    "spec": {
        "accessModes": [
            "ReadWriteOnce"
        ],
        "resources": {
            "requests": {
                "storage": "50Gi"
            }
        },
        "storageClassName": "standard"
    }
}
