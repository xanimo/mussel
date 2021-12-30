build-toolchain:
	docker buildx build --platform=linux/amd64 \
	-t xanimo/musl-toolchain . --load