#!/bin/sh
rm -rf target
mkdir -p target
git clone https://github.com/kubernetes-sigs/krew-index.git target/

for filename in target/plugins/*; do
  plugin=$(basename ${filename%.*})
  mkdir -p plugins/$plugin

  if ! test -f plugins/$plugin/default.json; then
    cp template/default.json plugins/$plugin
  fi
done

ruby update.rb
