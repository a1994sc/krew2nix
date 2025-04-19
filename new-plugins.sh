#!/bin/sh
rm -rf target
mkdir -p target

quiet_git() {
  stdout=$(mktemp)
  stderr=$(mktemp)

  if ! git "$@" </dev/null >$stdout 2>$stderr; then
    cat $stderr >&2
    rm -f $stdout $stderr
    exit 1
  fi

  rm -f $stdout $stderr
}

quiet_git clone https://github.com/kubernetes-sigs/krew-index.git target/

# delete the whole "plugins" folder to as to clean out plugins removed from upstream
rm -rf plugins

for filename in target/plugins/*; do
  plugin=$(basename ${filename%.*})
  mkdir -p plugins/$plugin

  if ! test -f plugins/$plugin/default.json; then
    cp template/default.json plugins/$plugin
    ruby update.rb $plugin
  fi
done
