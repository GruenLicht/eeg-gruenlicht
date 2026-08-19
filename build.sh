#!/bin/bash

CONTAINER="eeg-gruenlicht"
REPOSITORY="oydeu"

# Standard-Tag ist das heutige Datum im Format YYMMDD (z.B. 260814).
# Mit --tag=<wert> ueberschreibbar, mit --latest auf "latest" zurueckschaltbar.
TAG="$(date +%y%m%d)"
EXPLICIT_TAG=""

# read commandline options
BUILD_TEST=true
BUILD_CLEAN=false
DOCKER_UPDATE=false
BUILD_ARM=false
PLATFORM="linux/amd64"
BUILD_X86=true
DOCKERFILE="./docker/Dockerfile"

while [ $# -gt 0 ]; do
    case "$1" in
        --clean*)
            BUILD_CLEAN=true
            ;;
        --dockerhub*)
            DOCKER_UPDATE=true
            ;;
        --arm*)
            BUILD_X86=false
            BUILD_ARM=true
            PLATFORM="linux/arm64"
            DOCKERFILE="${DOCKERFILE}.arm64v8"
            TAG="arm64v8"
            ;;
        --x86*)
            BUILD_X86=true
            PLATFORM="linux/amd64"
            ;;
        --tag=*)
            EXPLICIT_TAG="${1#*=}"
            ;;
        --tag)
            shift
            EXPLICIT_TAG="$1"
            ;;
        --latest*)
            EXPLICIT_TAG="latest"
            ;;
        *)
            printf "unknown option(s)\n"
            printf "usage: ./build.sh [--clean] [--dockerhub] [--arm|--x86] [--tag=YYMMDD|--latest]\n"
            if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
                return 1
            else
                exit 1
            fi
    esac
    shift
done

# Ein explizit gesetzter Tag gewinnt immer -- auch gegenueber --arm.
if [ -n "$EXPLICIT_TAG" ]; then
    TAG="$EXPLICIT_TAG"
fi

printf "building %s/%s:%s for %s\n" "$REPOSITORY" "$CONTAINER" "$TAG" "$PLATFORM"

if $BUILD_CLEAN; then
    docker build --platform $PLATFORM --no-cache -f $DOCKERFILE -t $REPOSITORY/$CONTAINER:$TAG .
else
    docker build --platform $PLATFORM -f $DOCKERFILE -t $REPOSITORY/$CONTAINER:$TAG .
fi

if $DOCKER_UPDATE; then
    docker push $REPOSITORY/$CONTAINER:$TAG
    printf "\npushed %s/%s:%s\n" "$REPOSITORY" "$CONTAINER" "$TAG"
    printf "naechster Schritt: image-Tag in kubernetes/eeg-website-deploy.yaml auf %s setzen und anwenden\n" "$TAG"
fi
