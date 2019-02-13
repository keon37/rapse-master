#!/bin/bash

docker stop rapse-current
docker rm rapse-current
docker rmi -f rapse
