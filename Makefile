tag=latest
platforms=linux/amd64,linux/arm64,linux/arm,linux/386

build:
	docker buildx build --platform=$(platforms) \
	-t xanimo/musl-toolchain:$(tag) . --push