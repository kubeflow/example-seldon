VERSION=$1
REPO=$2

until docker ps; 
do sleep 3; 
done; 

docker run -v  ${PWD}:/my_model seldonio/core-python-wrapper:0.6 /my_model SkMnist ${VERSION} seldonio --image-name=skmnistclassifier_runtime
cd ./build
./build_image.sh
docker images 
echo $DOCKER_PASSWORD | docker login --username=$DOCKER_USERNAME --password-stdin 
./push_image.sh




