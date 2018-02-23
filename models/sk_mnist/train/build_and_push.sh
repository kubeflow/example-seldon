VERSION=$1
REPO=$2

IMAGE=skmnistclassifier_trainer

until docker ps; 
do sleep 3; 
done; 

docker build --force-rm=true -t ${REPO}/${IMAGE}:${VERSION} . 
docker images 
echo "Pushing image to ${REPO}/${IMAGE}:${VERSION}"
echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
docker push ${REPO}/${IMAGE}:${VERSION}
