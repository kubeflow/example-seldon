VERSION=$1
REPO=$2

IMAGE=rmnistclassifier_runtime

export DOCKER_HOST="tcp://127.0.0.1:2375"
echo "DOCKER_HOST set to $DOCKER_HOST"

until docker ps; 
do sleep 3; 
done; 

docker build . -t ${REPO}/${IMAGE}:${VERSION}
docker images 
echo "Pushing image to ${REPO}/${IMAGE}:${VERSION}"
echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin
docker push ${REPO}/${IMAGE}:${VERSION}

