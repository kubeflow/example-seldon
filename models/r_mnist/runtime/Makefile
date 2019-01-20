
seldon_build_image_local:
	s2i build . seldonio/seldon-core-s2i-r:0.2 seldonio/rmnistclassifier_runtime:0.2

seldon_push_docker_hub:
	docker push seldonio/rmnistclassifier_runtime:0.2

clean:
	rm -f source-to-image-v1.1.9a-40ad911d-linux-amd64.tar.gz*
	rm -f s2i
	rm -f sti
