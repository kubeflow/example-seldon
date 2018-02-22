VERSION=$1
REPO=$2
PUSH=$3

IMAGE=skmnistclassifier_runtime

until docker ps; 
do sleep 3; 
done; 

docker run -v  ${PWD}:/my_model seldonio/core-python-wrapper:0.6 /my_model SkMnist ${VERSION} ${REPO} --image-name=${IMAGE}
cd ./build
./build_image.sh
docker images 
if test "$PUSH" = 'true'; then
    echo "Pushing image to ${REPO}/${IMAGE}:${VERSION}"
    echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
    ./push_image.sh
fi




