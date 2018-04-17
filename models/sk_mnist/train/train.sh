#!/usr/bin/env bash

# exit when any command fails
set -e

until mountpoint -q /data; do
    echo "$(date) - wainting for /data to be mounted..."
    sleep 1
done       

ls -l /data

python -u create_model.py

ls -l /data
