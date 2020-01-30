#!/bin/bash

PROJ_DIR="$(dirname "$0")"

if [ -f "$PROJ_DIR/.env" ]; then
  . "$PROJ_DIR/.env"
fi

ARGS="$@"
if [ "$ARGS" = "" ]; then
  gradle --quiet --console=plain run
else
  gradle --quiet --console=plain run --args="$@"
fi

