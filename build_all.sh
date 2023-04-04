#!/bin/bash
PROJECT_DIR="`pwd`"
BUILD_SCRIPT="$PROJECT_DIR/build.sh"

platforms=("linux" "macos")
architectures=("amd64" "arm64")
for dir in $(find . -name main.go -exec dirname {} \; | sort | uniq); do
  if [[ "$dir" == *"test"* ]] || [[ -f "$dir/.buildignore" ]]; then
    continue
  fi
  echo "Building $dir"
  cd $dir

  for platform in "${platforms[@]}"; do
    for arch in "${architectures[@]}"; do
      PROJECT_DIR=$PROJECT_DIR $BUILD_SCRIPT $platform $arch
    done
  done

  cd $PROJECT_DIR
done
