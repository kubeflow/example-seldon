VERSION=$1
REPO=$2

IMAGE=skmnistclassifier_runtime

export DOCKER_HOST="tcp://127.0.0.1:2375"
echo "DOCKER_HOST set to $DOCKER_HOST"

apk add --update openssl

wget https://github.com/openshift/source-to-image/releases/download/v1.1.9a/source-to-image-v1.1.9a-40ad911d-linux-amd64.tar.gz
tar -zxf source-to-image-v1.1.9a-40ad911d-linux-amd64.tar.gz

until docker ps; 
do sleep 3; 
done; 

./s2i build . seldonio/seldon-core-s2i-python2 ${REPO}/${IMAGE}:${VERSION}
docker images 
echo "Pushing image to ${REPO}/${IMAGE}:${VERSION}"
echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
docker push ${REPO}/${IMAGE}:${VERSION}

