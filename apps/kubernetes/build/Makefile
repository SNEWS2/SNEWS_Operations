# TODO - Need to track build files/state to only rebuild when the images are out of date.
#      - Same for only tagging and pushing changed images.

# ---- User-tunable settings ----
COMPOSE ?= docker-compose
COMPOSE_PROJECT ?= build
COMPOSE_CMD := $(COMPOSE) -p $(COMPOSE_PROJECT)

PLATFORM ?= linux/amd64

DOCKER_USER ?= snews
SNEWS_MODE ?= dev

# Tag to apply in the remote registry (defaults to latest)
TAG ?= latest

# Local image tag used for images built directly via `docker build`
LOCAL_TAG ?= latest
LOCAL_IMAGE_PREFIX ?= $(COMPOSE_PROJECT)-

REGISTRY ?= geddes-registry.rcac.purdue.edu
REGISTRY_NAMESPACE ?= snews
REMOTE_IMAGE_PREFIX ?= snews_build-

# Build flags (used for "security" mode)
DOCKER_BUILD_FLAGS ?=
COMPOSE_BUILD_FLAGS ?=

# Extra args appended to `docker build` for Dockerfiles that are not part of docker-compose.yml
EXTRA_BUILD_ARGS ?=

# ---- Build context mappings (optional; used to trigger rebuilds) ----
#
# If you have local checkouts of these projects for testing, set the directory
# name here so "normal" builds rebuild when the git state (or files) change.
#
# Examples:
#   make build-all CTX_DIR_coincidence_system=SNEWS_Coincidence_System
#
CTX_DIR_coincidence_system ?= SNEWS_Coincidence_System
CTX_DIR_coincidence_system_dev ?= SNEWS_Coincidence_System
CTX_DIR_db_pipeline ?= SNEWS_DB_PIPELINE
CTX_DIR_firework_launcher ?= SNEWS_Firework_Launcher
CTX_DIR_monitoring_website ?= SNEWS_Monitoring_Website
CTX_DIR_publishing_tools ?= SNEWS_Publishing_Tools

# ---- Derived settings ----
DOCKERFILES := $(wildcard Dockerfile.*)
IMAGES := $(patsubst Dockerfile.%,%,$(DOCKERFILES))

STAMP_DIR ?= .stamps
BASE_IMAGE ?= snews_base

# NOTE: $(shell ...) collapses newlines into spaces.
COMPOSE_SERVICES := $(shell $(COMPOSE_CMD) config --services 2>/dev/null)

remote_image = $(REGISTRY)/$(REGISTRY_NAMESPACE)/$(REMOTE_IMAGE_PREFIX)$(1):$(TAG)
ctx_dir = $(strip $(value CTX_DIR_$(1)))

# Local image name for a compose service.
# - If the service sets `image:` explicitly (like snews_base), override with COMPOSE_IMAGE_<service>.
# - Otherwise default to <COMPOSE_PROJECT>-<service>.
COMPOSE_IMAGE_snews_base ?= $(BASE_IMAGE)
# Use normal expansion (not $(value ...)) so COMPOSE_IMAGE_* can reference other make vars.
compose_local_image = $(strip $(if $(COMPOSE_IMAGE_$(1)),$(COMPOSE_IMAGE_$(1)),$(COMPOSE_PROJECT)-$(1)))

BUILT_STAMPS := $(addprefix $(STAMP_DIR)/built-,$(IMAGES))
CTXHASH_STAMPS := $(addprefix $(STAMP_DIR)/ctxhash-,$(IMAGES))

# Prevent make from deleting ctxhash stamps as intermediate files.
.SECONDARY: $(CTXHASH_STAMPS)

FORCE:

$(STAMP_DIR):
	@mkdir -p $(STAMP_DIR)

# ---- Git/file-based change detection for build contexts ----
#
# This rule ALWAYS runs, but it only rewrites the stamp file when the computed
# key changes. That way downstream "built-*" stamps only rebuild when needed.
$(STAMP_DIR)/ctxhash-%: FORCE | $(STAMP_DIR)
	@ctx_dir="$(call ctx_dir,$*)"; \
	key="noctx"; \
	if [ -n "$$ctx_dir" ] && [ -d "$$ctx_dir" ]; then \
		if git -C "$$ctx_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
			rev=$$(git -C "$$ctx_dir" rev-parse HEAD 2>/dev/null || echo nogit); \
			dirty=$$(git -C "$$ctx_dir" status --porcelain --untracked-files=all -- . 2>/dev/null | shasum | awk '{print $$1}'); \
			key="gitdir:$$rev-$$dirty"; \
		elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
			tree=$$(git rev-parse HEAD:"$$ctx_dir" 2>/dev/null || echo no-tree); \
			dirty=$$(git status --porcelain --untracked-files=all -- "$$ctx_dir" 2>/dev/null | shasum | awk '{print $$1}'); \
			key="gitsubdir:$$tree-$$dirty"; \
		else \
			files=$$( (find "$$ctx_dir" -type f -print0 2>/dev/null | LC_ALL=C sort -z | xargs -0 shasum 2>/dev/null || true) | shasum | awk '{print $$1}'); \
			key="files:$$files"; \
		fi; \
	fi; \
	if [ -f "$@" ] && [ "$$(cat "$@")" = "$$key" ]; then :; else echo "$$key" > "$@"; fi

# ---- Aliases / top-level targets ----
help: ## Show help / list available targets
	@printf "SNEWS geddes_build Makefile\n\n"; \
	printf "Usage:\n  make <target> [VAR=value ...]\n\n"; \
	printf "Common variables (with current defaults):\n"; \
	printf "  PLATFORM=%s\n" "$(PLATFORM)"; \
	printf "  DOCKER_USER=%s\n" "$(DOCKER_USER)"; \
	printf "  SNEWS_MODE=%s\n" "$(SNEWS_MODE)"; \
	printf "  TAG=%s\n" "$(TAG)"; \
	printf "    (TAG controls which remote :tag is created/pushed; pass TAG=... to both tag-* and push-* invocations)\n"; \
	printf "  REGISTRY=%s\n" "$(REGISTRY)"; \
	printf "  REGISTRY_NAMESPACE=%s\n" "$(REGISTRY_NAMESPACE)"; \
	printf "  COMPOSE_PROJECT=%s\n" "$(COMPOSE_PROJECT)"; \
	printf "\nTop-level targets:\n"; \
	awk 'BEGIN{FS=":.*##"} /^[a-zA-Z0-9_.-]+:.*##/{printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | LC_ALL=C sort; \
	printf "\nPer-image targets (IMAGE in: %s)\n" "$(IMAGES)"; \
	printf "  build-<IMAGE>        Incremental build (rebuild when Dockerfile/context changes)\n"; \
	printf "  tag-<IMAGE>          Tag IMAGE into $(REGISTRY)/$(REGISTRY_NAMESPACE)/...:$(TAG)\n"; \
	printf "  push-<IMAGE>         Push tagged image to remote registry\n"; \
	printf "\nExamples:\n"; \
	printf "  make build-all\n"; \
	printf "  make tag-all TAG=development\n"; \
	printf "  make push-all TAG=development\n"; \
	printf "  make release TAG=development\n"; \
	printf "  make security-updates TAG=development\n"

base: build-$(BASE_IMAGE) ## Build the base image first

build: build-all ## Incremental build of all images

tag: tag-all ## Tag all images for the remote registry for the current TAG (default: latest)

push: push-all ## Push all images for the current TAG (default: latest)

release: build-all tag-all push-all ## Build, tag, and push all images for the current TAG (default: latest)

# "security updates" mode: force rebuild everything.
#
# Important: do NOT use --pull when building images that are `FROM snews_base:latest`,
# otherwise Docker will try to pull `snews_base` from docker.io (and fail).
# Instead we:
#  1) rebuild the base image with --pull + --no-cache
#  2) rebuild all other images with --no-cache (no pull)
security-updates: ## Full rebuild (pull base layers for snews_base, rebuild everything else w/o pull), then tag+push
	@$(MAKE) clean-stamps
	@$(MAKE) build-$(BASE_IMAGE) DOCKER_BUILD_FLAGS="--pull --no-cache" COMPOSE_BUILD_FLAGS="--pull --no-cache"
	@$(MAKE) build-all DOCKER_BUILD_FLAGS="--no-cache" COMPOSE_BUILD_FLAGS="--no-cache"
	@$(MAKE) tag-all push-all

# Backwards-compatible aliases
security_updates: security-updates ## Alias for security-updates
security: security-updates ## Alias for security-updates

build-all: $(addprefix build-,$(IMAGES)) ## Build all images

tag-all: $(addprefix tag-,$(IMAGES)) ## Tag all images for the current TAG (default: latest)

push-all: $(addprefix push-,$(IMAGES)) ## Push all images for the current TAG (default: latest)

clean-stamps: ## Remove local build stamps so next build rebuilds
	@rm -f $(BUILT_STAMPS)

# ---- Docker maintenance ----
# NOTE: This is intentionally guarded because it can delete a lot of data.
# It is useful when Docker has consumed all disk space.
#
# Usage:
#   make docker-purge CONFIRM=YES
#
# This runs:
#   docker system prune -af
docker-purge: ## DANGEROUS: reclaim disk by pruning ALL unused docker data (requires CONFIRM=YES)
	@if [ "$(CONFIRM)" != "YES" ]; then \
		echo "Refusing to run docker system prune -af without confirmation."; \
		echo "Re-run with: make docker-purge CONFIRM=YES"; \
		exit 1; \
	fi
	docker system prune -af

# ---- Incremental build stamps ----
# All non-base images depend on the base image being built first.
$(filter-out $(STAMP_DIR)/built-$(BASE_IMAGE),$(BUILT_STAMPS)): $(STAMP_DIR)/built-$(BASE_IMAGE)

# Build stamps: rebuild only when Dockerfile or context hash changes.
$(STAMP_DIR)/built-%: Dockerfile.% docker-compose.yml $(STAMP_DIR)/ctxhash-% | $(STAMP_DIR)
	@if echo "$(COMPOSE_SERVICES)" | tr ' ' '\n' | grep -qx "$*"; then \
		DOCKER_DEFAULT_PLATFORM=$(PLATFORM) DOCKER_USER=$(DOCKER_USER) SNEWS_MODE=$(SNEWS_MODE) $(COMPOSE_CMD) build $(COMPOSE_BUILD_FLAGS) $*; \
	else \
		DOCKER_DEFAULT_PLATFORM=$(PLATFORM) docker build $(DOCKER_BUILD_FLAGS) -f Dockerfile.$* -t $(LOCAL_IMAGE_PREFIX)$*:$(LOCAL_TAG) \
			--build-arg DOCKER_USER=$(DOCKER_USER) \
			--build-arg SNEWS_MODE=$(SNEWS_MODE) \
			$(EXTRA_BUILD_ARGS) \
			.; \
	fi
	@touch $@

# ---- User-facing build targets (depend on stamps) ----
# GNU make does not treat a recipe-less pattern rule as an implicit rule for
# command-line targets, so we define these explicitly via a static pattern rule.
$(addprefix build-,$(IMAGES)): build-%: $(STAMP_DIR)/built-%

# ---- Tag ----
# NOTE: docker-compose v2's `images` subcommand may not report built images
# unless containers exist, so we tag by resolved local image name.
tag-$(BASE_IMAGE): build-$(BASE_IMAGE)
	@img="$(call compose_local_image,$(BASE_IMAGE))"; \
	if docker image inspect "$$img:$(LOCAL_TAG)" >/dev/null 2>&1; then \
		docker tag "$$img:$(LOCAL_TAG)" $(call remote_image,$(BASE_IMAGE)); \
	else \
		echo "ERROR: could not find local image '$$img:$(LOCAL_TAG)' (run: make build-$(BASE_IMAGE))"; \
		exit 1; \
	fi

tag-%: build-%
	@if echo "$(COMPOSE_SERVICES)" | tr ' ' '\n' | grep -qx "$*"; then \
		img="$(call compose_local_image,$*)"; \
		img2="$(COMPOSE_PROJECT)_$*"; \
		if docker image inspect "$$img:$(LOCAL_TAG)" >/dev/null 2>&1; then \
			docker tag "$$img:$(LOCAL_TAG)" $(call remote_image,$*); \
		elif docker image inspect "$$img2:$(LOCAL_TAG)" >/dev/null 2>&1; then \
			docker tag "$$img2:$(LOCAL_TAG)" $(call remote_image,$*); \
		else \
			echo "ERROR: could not find local compose image for '$*' (tried '$$img:$(LOCAL_TAG)' and '$$img2:$(LOCAL_TAG)')"; \
			echo "       (run: make build-$*)"; \
			exit 1; \
		fi; \
	else \
		if docker image inspect "$(LOCAL_IMAGE_PREFIX)$*:$(LOCAL_TAG)" >/dev/null 2>&1; then \
			docker tag $(LOCAL_IMAGE_PREFIX)$*:$(LOCAL_TAG) $(call remote_image,$*); \
		else \
			echo "ERROR: could not find local image '$(LOCAL_IMAGE_PREFIX)$*:$(LOCAL_TAG)' (run: make build-$*)"; \
			exit 1; \
		fi; \
	fi

# ---- Push ----
push-%: tag-%
	docker push $(call remote_image,$*)

.PHONY: \
	FORCE \
	help \
	base build tag push release security security-updates security_updates clean-stamps docker-purge \
	build-all tag-all push-all
