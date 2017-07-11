#!/bin/sh
# appLariat generic java openjdk build script
# Requirements - A jar file is provided as a code artifact in appLariat 
# Dockerfile adds the jar file to /code/
# Build.sh copies the jar file from the code_dir and copies it into APP_DIR

#set environment
export APP_DIR=/usr/local/jmeter
export JMETER_DIR=/usr/local/jmeter/jmeter-3.1

#Log everything in /tmp/build.log
logfile=/tmp/build.log
exec > $logfile 2>&1
set -x

apt-get update && apt-get install -y curl

#Move code into APP_DIR
mkdir -p $APP_DIR
mv /code/* $APP_DIR

echo "Moved resources to $APP_DIR"
echo "Build completed"