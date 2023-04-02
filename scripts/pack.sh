#!/bin/bash
rm -rf releases packages
mkdir -p packages
mkdir -p releases/bin
mkdir -p releases/scripts

cp -rf bin/* releases/bin/
cp -rf scripts/* releases/scripts/

version=$1
platforms="linux darwin"
architectures="x86_64 arm64"
for platform in $platforms; do
  for arch in $architectures; do
    zip packages/"release-$platform-$arch-$version.zip" releases/bin/*${platform}_${arch}* releases/scripts/*
  done
done
