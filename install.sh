#!/bin/bash
# creating the necessary directories

WORKPATH="${1}"
[[ -z $WORKPATH ]] && WORKPATH=$(pwd)

echo "Working directory is $WORKPATH"

echo "+ creating logs directories:"
mkdir -pv ${WORKPATH}/logs/{httpd,mysql,nginx,push-server,redis}

echo "+ creating mysql directory:"
mkdir -pv ${WORKPATH}/var/mysql

echo "+ creating project directory:"
mkdir -pv ${WORKPATH}/var/www/default
mkdir -pv ${WORKPATH}/var/www/.bx_temp/default
