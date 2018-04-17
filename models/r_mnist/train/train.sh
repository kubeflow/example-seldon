#!/usr/bin/env bash

# exit when any command fails
set -e

until mountpoint -q /data; do
    echo "$(date) - waiting for /data to be mounted..."
    sleep 1
done       

ls -l /data

Rscript train.R

ls -l /data
