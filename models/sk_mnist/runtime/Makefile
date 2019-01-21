
seldon_build_image_local:
	s2i build . seldonio/seldon-core-s2i-python2:0.4 seldonio/skmnistclassifier_runtime:0.2

seldon_push_docker_hub:
	docker push seldonio/skmnistclassifier_runtime:0.2


clean:
	rm -f source-to-image-v1.1.9a-40ad911d-linux-amd64.tar.gz*
	rm -f s2i
	rm -f sti
