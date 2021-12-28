build-toolchain:
	docker buildx build --platform=linux/386,linux/amd64,linux/arm64,linux/arm \
	-t xanimo/musl-toolchain . --push