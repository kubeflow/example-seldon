
#Argo
kubectl port-forward $(kubectl get pods -n kubeflow -l app=argo-ui -o jsonpath='{.items[0].metadata.name}') -n kubeflow 8001:8001 &

#Seldon Grafana
kubectl port-forward $(kubectl get pods -n kubeflow -l app=grafana-prom-server -o jsonpath='{.items[0].metadata.name}') -n kubeflow 3000:3000 &

#Ambassador reverse proxy
kubectl port-forward $(kubectl get pods -n kubeflow -l service=ambassador -o jsonpath='{.items[0].metadata.name}') -n kubeflow 8002:80 &

#Ambassador admin
kubectl port-forward $(kubectl get pods -n kubeflow -l service=ambassador -o jsonpath='{.items[0].metadata.name}') -n kubeflow 8877:8877 &


