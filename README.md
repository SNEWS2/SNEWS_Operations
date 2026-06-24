# SNEWS_Operations
These are the useful bits for running the SNEWS 2.0 infrastructure.

## Docker/Kubernetes
The entire SNEWS 2.0 infrastructure runs as containers. There are Dockerfiles for each of the major components.
This infrastructure is running in a Kubernetes cluster hosted at Purdue University.

The containers images are created using a local Docker instance, then published to a Harbor repository. 
Our Kubernetes instance deploys the images from the Harbor repository.

A Makefile wraps the process of building and publishing the container images. This may need to be modified for use
elsewhere. 


### Build/run

SNEWS geddes\_build Makefile

Usage:
  make <target> [VAR=value ...]

Common variables (with current defaults):
  PLATFORM=linux/amd64
  DOCKER\_USER=snews
  SNEWS\_MODE=dev
  TAG=latest
    (TAG controls which remote :tag is created/pushed; pass TAG=... to both tag-* and push-* invocations)
  REGISTRY=geddes-registry.rcac.purdue.edu
  REGISTRY\_NAMESPACE=snews
  COMPOSE\_PROJECT=build

Top-level targets:
  base                Build the base image first
  build               Incremental build of all images
  build-all           Build all images
  clean-stamps        Remove local build stamps so next build rebuilds
  docker-purge        DANGEROUS: reclaim disk by pruning ALL unused docker data (requires CONFIRM=YES)
  help                Show help / list available targets
  push                Push all images for the current TAG (default: latest)
  push-all            Push all images for the current TAG (default: latest)
  release             Build, tag, and push all images for the current TAG (default: latest)
  security            Alias for security-updates
  security-updates    Full rebuild (pull base layers for snews\_base, rebuild everything else w/o pull), then tag+push
  security\_updates    Alias for security-updates
  tag                 Tag all images for the remote registry for the current TAG (default: latest)
  tag-all             Tag all images for the current TAG (default: latest)

Per-image targets (IMAGE in: coincidence\_system coincidence\_system\_dev db\_pipeline firework\_followup monitoring\_website publishing\_tools snews\_base)
  build-<IMAGE>        Incremental build (rebuild when Dockerfile/context changes)
  tag-<IMAGE>          Tag IMAGE into geddes-registry.rcac.purdue.edu/snews/...:latest
  push-<IMAGE>         Push tagged image to remote registry

Examples:
  make build-all
  make tag-all TAG=development
  make push-all TAG=development
  make release TAG=development
  make security-updates TAG=development



### Credentials

### Monitor

### Back-up





# Legacy documentation

## Apptainer usage:
Apptainer is a handy container environment that doesn't require administrative
access to install or execute.

### Data storage locations:
	~/apps
	~/data
	~/etc
	~/run

### Building the Apptainer container
	$ cd SNEWS_Operations/apps/snews_cs
	$ apptainer build snews_cs.img snews_cs.def

### Executing the Apptainer container
	$ apptainer run --app coinc snews_cs.img
	$ apptainer run --app feedback snews_cs.img

Note: 
It *is* possible to configure the container to 
not use localhost as the smtp relay, as well as use smtp-auth.
These items can be passed in through the environment
so that things like passwords are not laying in plain text.
They are also VERY environment specific and will differ
depending on where this container is launched from.

	apptainer run \
		--env smtp_server_addr=relay.physics.purdue.edu \
		--env snews_sender_email=snews@purdue.edu \
		--env snews_sender_pass=$(pass snews@purdue.edu) \
		--app coinc snews_cs.img firedrill

## Log rotations

It will eventually become necessary to rotate your log files.
An example configuration exists in [SNEWS_Operations/etc/logrotate/logrotate.conf](https://github.com/SNEWS2/SNEWS_Operations/blob/main/etc/logrotate/logrotate.conf).

An okay crontab might be configured like:

	7 1 * * * /usr/sbin/logrotate -l ~/data/logrotate/logrotate.log -s ~/run/logrotate/state ~/etc/logrotate/logrotate.conf

# Grafana graph configurations

These settings are used to generate the dashboard.  I believe this *should* be templated at some point, although it doesn't appear Grafana supports variables in the field name transformation, which could make things interesting.

	1. Click dashboard
	2. Add/Row
	3. Name: XENONnT at a glance
	4. Ok

## On/Off status panel
	1. Add/Visualization
	2. Transform data
	3. Add transformation
	4. Filter by name (unfortunately, this doesn't support the usage of variables yet)
	5. Field: Detector, Match: Is equal, Value: XENONnT

	6. Visualizaions: Stat
	7. itle: XENONnT
	8. Value mappings: Value: on -> green, off -> red
	9. Unit: Boolean - On/Off
	10. Calculation: Last, Fields: Status
	11. Apply/Save

## Heartbeats data
	1. Add/Visualization
	    1. Transform data
	    2. Add transformation
	    3. Filter by name (unfortunately, this doesn't support the usage of variables yet)
	    4. Field: Detector, Match: Is equal, Value: XENONnT

	2. Query:
	    1. Field: Recieved Times: Type Time
	    2. Field: Stamped Times: Type Time
	    3. Field: Status: Type String
	    4. Field: Time After Last: Type Number

	3. Visualizations: Table
	    1. Title: XENONnT Heartbeats
	    2. Decimals: 5

