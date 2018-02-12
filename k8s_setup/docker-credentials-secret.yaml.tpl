apiVersion: v1
data:
  password: <base 64 password>
  username: <base 64 username>
kind: Secret
metadata:
  name: docker-credentials
  namespace: default
type: Opaque

