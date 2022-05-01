GIT_SHA_SHORT=$(shell git rev-parse --short HEAD)
DOCKER_IMAGE_TAG=$(shell echo rust-backend:$(shell git rev-parse --abbrev-ref HEAD)-$(shell git rev-parse --short HEAD)-$(shell git rev-list --count HEAD))

docker_build:
	docker build --build-arg GIT_SHA_SHORT=$(GIT_SHA_SHORT) -t $(DOCKER_IMAGE_TAG) .