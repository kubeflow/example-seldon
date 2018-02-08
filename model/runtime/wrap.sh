VERSION=$1
REPO=$2

until docker ps; 
do sleep 3; 
done; 

docker run -v  ${PWD}:/my_model seldonio/core-python-wrapper:0.6 /my_model DeepMnist ${VERSION} seldonio --image-name=deepmnistclassifier_runtime
docker images 
echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
docker push ${REPO}/deepmnistclassifier_runtime:${VERSION}

