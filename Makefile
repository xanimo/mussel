tag=latest
platforms=linux/amd64,linux/arm64,linux/arm,linux/386

build:
	docker buildx build --platform=$(platforms) \
	-t xanimo/musl-toolchain:$(tag) . --push

build-musl-base:
	docker buildx build --platform=$(platforms) \
	-f Dockerfile.base \
	-t xanimo/musl-toolchain:base . --load 2> log.txt

build-musl-build:
	docker buildx build --platform=$(platforms) \
	-f Dockerfile.build \
	-t xanimo/musl-toolchain:build . --load 2> log.txt