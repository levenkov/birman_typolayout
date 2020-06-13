#!/bin/bash

DESTINATION_PATH=$1; shift
DESTINATION_PATH=${DESTINATION_PATH:-.}
DESTINATION_PATH=$(readlink -m $DESTINATION_PATH)

set -e

declare -a EXCLUDE_LIST

EXCLUDE_LIST+=(/deb/debignore)

for e in $(cat deb/debignore)
do
  EXCLUDE_LIST+=("$e")
done

DEB_STAGE_DIR=$(mktemp -d --suffix=-birman-layout)

set +e; ( set -e
  mkdir -p $DEB_STAGE_DIR/src
  rsync -a . $DEB_STAGE_DIR/src/ $(
    for arg in "${EXCLUDE_LIST[@]}"
    do
      echo '--exclude'
      echo $arg
    done
  )
  cd $DEB_STAGE_DIR

  echo "Tree of source files for the packing DEB package, placed in $PWD:"
  tree

  mkdir birman-layout

  mv src/deb/DEBIAN birman-layout/
  rmdir src/deb

  sed -i "s,%arch%,$(dpkg --print-foreign-architectures)," birman-layout/DEBIAN/control

  mkdir -p birman-layout/usr/share/X11/xkb/symbols

  mv src/{ru,en}_typo birman-layout/usr/share/X11/xkb/symbols/

  echo 'Tree of the packing DEB package after preparing:'
  tree

  time dpkg-deb --build birman-layout
  ls -lh birman-layout.deb

  echo
  echo 'Installing output files:'
  cp -vf birman-layout.deb $DESTINATION_PATH

  echo
  echo 'Build SUCCESSFUL'
); EXIT_CODE=$?; set -e

rm -rf $DEB_STAGE_DIR

if (( EXIT_CODE != 0 ))
then
  echo
  echo 'Build FAILED' >&2
  exit $EXIT_CODE
fi
