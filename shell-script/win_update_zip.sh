#!/bin/bash

echo "Zip Source Start"

FILE_NAME="rapse"

rm -f ~/Works/ezfarm/2018/$FILE_NAME.zip

pushd ~/Works/ezfarm/2018/$FILE_NAME

zip -r ~/Works/ezfarm/2018/$FILE_NAME.zip --exclude=*.DS_Store* --exclude=*__pycache__* --exclude=./.git --exclude=./tmp --exclude=./precompiled --exclude=./.* --exclude=./*.pyc --exclude=./db-backup/* --exclude=./app/cache/* ./

popd

mv ~/Works/ezfarm/2018/$FILE_NAME.zip ~/Downloads

echo "Zip Source Done"

