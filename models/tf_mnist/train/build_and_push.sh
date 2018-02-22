VERSION=$1
REPO=$2
PUSH=$3

IMAGE=deepmnistclassifier_trainer

until docker ps; 
do sleep 3; 
done; 

docker build --force-rm=true -t ${REPO}/${IMAGE}:${VERSION} . 
docker images 
if test "$PUSH" = 'true'; then
   echo "Pushing image to ${REPO}/${IMAGE}:${VERSION}"
   echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
   docker push ${REPO}/${IMAGE}:${VERSION}
fi

