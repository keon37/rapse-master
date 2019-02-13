#!/bin/bash

# https://hub.docker.com/r/osrm/osrm-backend/

# mkdir -p ~/Downloads/osrm
# cd ~/Downloads/osrm


mkdir -p /srv/rapse-osrm-data
cd /srv/rapse-osrm-data

curl -O http://download.geofabrik.de/asia/south-korea-latest.osm.pbf

docker pull osrm/osrm-backend

docker run -t -v $(pwd):/data osrm/osrm-backend osrm-extract -p /opt/car.lua /data/south-korea-latest.osm.pbf
docker run -t -v $(pwd):/data osrm/osrm-backend osrm-partition /data/south-korea-latest.osrm
docker run -t -v $(pwd):/data osrm/osrm-backend osrm-customize /data/south-korea-latest.osrm

docker run -d --name rapse-osrm -v $(pwd):/data -p 5000:5000 --restart=always osrm/osrm-backend osrm-routed --algorithm mld /data/south-korea-latest.osrm

# docker run -t -i -p 5000:5000 -v $(pwd):/data osrm/osrm-backend osrm-routed --algorithm mld /data/berlin-latest.osrm

# docker run -d --name rapse-current -v /srv/rapse:/app/rapse -w /app/rapse/ -p 5060:5060 --restart=always rapse ./run_on_docker.sh