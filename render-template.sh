#!/bin/bash

IMAGE_NAME=registry.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/service-shaper/s2-api/dev-tools
EXTRA_ARGS=${EXTRA_ARGS:-}

# if extra args are empty then try to source them from render-template-args.sh file
if [ -z "$EXTRA_ARGS" ] && [ -f $(pwd)/render-template-args.sh ]; then
    source $(pwd)/render-template-args.sh
fi

docker pull $IMAGE_NAME

if [ -d $(pwd)/.rendered ]; then rm -Rf $(pwd)/.rendered; fi

docker run \
    --rm -it \
    --tmpfs /tmp:size=1g \
    -v $(pwd):/template \
    $IMAGE_NAME dev render-template --input-path=/template --output-path=/template/.rendered $EXTRA_ARGS