#!/bin/bash

function backup() {
    if [ ! -d "./backups" ]; then
        mkdir ./backups
    fi
    if [ -z "$(ls -A ./backups)" ]; then
        xtrabackup --backup --compress=zstd --target-dir=./backups/base
    else
        xtrabackup --backup --compress=zstd --target-dir=./backups/inc-$(date '+%Y-%m-%d_%H:%M:%S') --incremental-basedir=$(ls -d ./backups/* | tail -n 1)
    fi
    rclone sync ./backups ${RCLONE_BACKUP_PATH}
}

function restore() {
    for d in backups/*/; do
        xtrabackup --decompress --target-dir=$d
    done
    for d in backups/*/; do
        if [ $d == "backups/base/" ]; then
            xtrabackup --prepare --apply-log-only --target-dir=$d
        else
            if [ $d == $(ls -d backups/*/ | tail -n 1) ]; then
                xtrabackup --prepare --target-dir=./backups/base --incremental-dir=$d
            else
                xtrabackup --prepare --apply-log-only --target-dir=./backups/base --incremental-dir=$d
            fi
        fi
    done
    xtrabackup --copy-back --target-dir=./backups/base
}

case "$1" in
backup)
    backup
    ;;
restore)
    restore
    ;;
*)
    echo "Usage: $0 {backup|restore}"
    exit 1
    ;;
esac
