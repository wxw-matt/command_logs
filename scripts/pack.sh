#!/bin/bash
rm -rf releases packages
mkdir -p packages
mkdir -p releases/bin
mkdir -p releases/scripts

cp -rf bin/* releases/bin/
cp -rf scripts/* releases/scripts/

version=$1
echo $version
platforms="linux darwin"
architectures="x86_64 arm64"
for platform in $platforms; do
  for arch in $architectures; do
    tar czf packages/"release-$platform-$arch-$version.tar.gz" releases/bin/*${platform}_${arch}* releases/scripts/*
  done
done
