#!/bin/bash

git fetch origin; git reset --hard origin/18.0;
docker compose -p capili -f prod.yaml build --no-cache;
docker compose -p capili -f prod.yaml up -d --build --force-recreate --remove-orphans;
sleep 10;
docker compose -p capili -f prod.yaml exec odoo click-odoo-update -c auto/odoo.conf;
