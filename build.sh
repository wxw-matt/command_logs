#!/bin/bash

# Set the name of the program and the output directory
program_name=$(basename `pwd`)
output_dir="$PROJECT_DIR/bin"
if [ -z "$PROJECT_DIR" ]; then
    output_dir="./bin"
fi

platform=$1
arch=$2

# Determine the platform and architecture
if [ -z "$platform" ]; then
  platform=$(uname | tr '[:upper:]' '[:lower:]')
fi

if [ -z "$arch" ]; then
  arch=$(uname -m)
fi

program_name="${program_name}_${platform}_${arch}"

echo "Building $program_name ..."

# Build the program for the current platform and architecture
if [ "$platform" == "linux" ]; then
    GOOS=linux GOARCH=$arch go build -o "$output_dir/$program_name"
elif [ "$platform" == "macos" ]; then
    GOOS=darwin GOARCH=$arch go build -o "$output_dir/$program_name"
else
    echo "Unsupported platform: $platform"
    exit 1
fi
