#!/bin/bash

echo "Update Server Source"

rsync ~/Works/ezfarm/2018/rapse/ root@rapse.ezfarm.co.kr:/srv/rapse -arqz --rsh='ssh -p22722' --delete --exclude='.*' --exclude='db-backup' --exclude='app/cache' --exclude='log/*'
ssh root@rapse.ezfarm.co.kr -p 22722 "touch /srv/rapse/uwsgi.reload"
ssh -p 22722 root@rapse.ezfarm.co.kr 'rm -rf /srv/rapse/app/cache/*'

echo "Update Server Source Done"

