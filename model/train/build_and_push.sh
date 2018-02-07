VERSION=$1
REPO=$2

until docker ps; 
do sleep 3; 
done; 

docker build --force-rm=true -t ${REPO}/deepmnistclassifier_trainer:${VERSION} . 
docker images 
echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
docker push ${REPO}/deepmnistclassifier_trainer:${VERSION}


