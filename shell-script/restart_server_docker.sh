#!/bin/bash

echo "Restart Server Docker"

ssh -p 22022 root@rapse.ezfarm.co.kr 'docker restart rapse-current'

echo "Restart Server Docker Done"

