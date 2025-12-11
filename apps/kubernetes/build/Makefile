# TODO - Need to track build files/state to only rebuild when the images are out of date.
#      - Same for only tagging and pushing changed images.
#

TGTS:=$(wildcard Dockerfile.*)
DOCKER_USER=snews
SNEWS_MODE=dev


base:
	DOCKER_DEFAULT_PLATFORM=linux/amd64 DOCKER_USER=${DOCKER_USER} SNEWS_MODE=${SNEWS_MODE} docker-compose build snews_base

build: base
	DOCKER_DEFAULT_PLATFORM=linux/amd64 DOCKER_USER=${DOCKER_USER} SNEWS_MODE=${SNEWS_MODE} docker-compose build


# refactor these! This is just the starting point.
tag: 
	docker tag build-coincidence_system_dev:latest geddes-registry.rcac.purdue.edu/snews/snews_build-coincidence_system_dev:latest
	docker tag build-coincidence_system:latest geddes-registry.rcac.purdue.edu/snews/snews_build-coincidence_system:latest
	docker tag build-db_pipeline:latest geddes-registry.rcac.purdue.edu/snews/snews_build-db_pipeline:latest
	docker tag build-monitoring_website:latest geddes-registry.rcac.purdue.edu/snews/snews_build-monitoring_website:latest


push: tag
	docker push geddes-registry.rcac.purdue.edu/snews/snews_build-db_pipeline:latest
	docker push geddes-registry.rcac.purdue.edu/snews/snews_build-coincidence_system:latest
	docker push geddes-registry.rcac.purdue.edu/snews/snews_build-coincidence_system_dev:latest
	docker push geddes-registry.rcac.purdue.edu/snews/snews_build-monitoring_website:latest


#$(TGTS): Dockerfile.$? base
#	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose build $?

# wip.
#
#_build_%:
#

#_tag_%:
#

#_push_%:
#


.PHONY: base build tag push
