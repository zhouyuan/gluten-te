#!/bin/bash

set -ex

BASEDIR=$(dirname $0)

source "$BASEDIR/build.sh"

GLUTEN_IT_REPO=${GLUTEN_IT_REPO:-$DEFAULT_GLUTEN_IT_REPO}
GLUTEN_IT_BRANCH=${GLUTEN_IT_BRANCH:-$DEFAULT_GLUTEN_IT_BRANCH}

# Java options
EXTRA_JAVA_OPTIONS=${EXTRA_JAVA_OPTIONS:-$DEFAULT_EXTRA_JAVA_OPTIONS}

# Docker options
EXTRA_DOCKER_OPTIONS=${EXTRA_DOCKER_OPTIONS:-$DEFAULT_EXTRA_DOCKER_OPTIONS}

# Run GDB.
RUN_GDB=${RUN_GDB:-$DEFAULT_RUN_GDB}

# Run GDB server.
RUN_GDB_SERVER=${RUN_GDB_SERVER:-$DEFAULT_RUN_GDB_SERVER}

# Run JVM jdwp server.
RUN_JDWP_SERVER=${RUN_JDWP_SERVER:-$DEFAULT_RUN_JDWP_SERVER}

if [ "$RUN_GDB" == "ON" ] && [ "$RUN_GDB_SERVER" == "ON" ]
then
  echo "RUN_GDB_SERVER and RUN_GDB_SERVER can not be turned on at the same time."
  exit 1
fi


if [ "$RUN_GDB" == "ON" ]
then
  DOCKER_SELECTED_TARGET_IMAGE_TPC=${DOCKER_TARGET_IMAGE_TPC_GDB:-$DEFAULT_DOCKER_TARGET_IMAGE_TPC_GDB}
  DOCKER_BUILD_TARGET_NAME=gluten-tpc-gdb
elif [ "$RUN_GDB_SERVER" == "ON" ]
then
  DOCKER_SELECTED_TARGET_IMAGE_TPC=${DOCKER_TARGET_IMAGE_TPC_GDB_SERVER:-$DEFAULT_DOCKER_TARGET_IMAGE_TPC_GDB_SERVER}
  DOCKER_BUILD_TARGET_NAME=gluten-tpc-gdb-server
else
  DOCKER_SELECTED_TARGET_IMAGE_TPC=${DOCKER_TARGET_IMAGE_TPC:-$DEFAULT_DOCKER_TARGET_IMAGE_TPC}
  DOCKER_BUILD_TARGET_NAME=gluten-tpc
fi

# GDB server bind port
GDB_SERVER_PORT=${GDB_SERVER_PORT:-$DEFAULT_GDB_SERVER_PORT}

# JVM jdwp bind port
JDWP_SERVER_PORT=${JDWP_SERVER_PORT:-$DEFAULT_JDWP_SERVER_PORT}

# Gluten-it commit hash
GLUTEN_IT_COMMIT="$(git ls-remote $GLUTEN_IT_REPO $GLUTEN_IT_BRANCH | awk '{print $1;}')"

if [ -z "$GLUTEN_IT_COMMIT" ]
then
  echo "Unable to parse GLUTEN_IT_COMMIT."
  exit 1
fi

echo "Building on commits:
    Gluten-it commit: $GLUTEN_IT_COMMIT"

DOCKER_BUILD_ARGS=
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --ulimit nofile=8192:8192"
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --build-arg GLUTEN_IT_REPO=$GLUTEN_IT_REPO"
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --build-arg GLUTEN_IT_COMMIT=$GLUTEN_IT_COMMIT"
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS -f dockerfile-tpc"
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS --target $DOCKER_BUILD_TARGET_NAME"
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS -t $DOCKER_SELECTED_TARGET_IMAGE_TPC"
DOCKER_BUILD_ARGS="$DOCKER_BUILD_ARGS $BASEDIR"

DOCKER_RUN_ARGS=
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS -it"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS --rm"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS --init"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS --privileged"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS --ulimit nofile=65536:65536"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS --ulimit core=-1"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS --security-opt seccomp=unconfined"
DOCKER_RUN_ARGS="$DOCKER_RUN_ARGS $EXTRA_DOCKER_OPTIONS"

TPC_CMD_ARGS="$*"

JAVA_ARGS=
if [ "$RUN_JDWP_SERVER" == "ON" ]
then
  JAVA_ARGS="$JAVA_ARGS -ea"
  JAVA_ARGS="$JAVA_ARGS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$JDWP_SERVER_PORT"
fi
JAVA_ARGS="$JAVA_ARGS $EXTRA_JAVA_OPTIONS"
JAVA_ARGS="$JAVA_ARGS -cp /opt/gluten-it/target/gluten-it-1.0-SNAPSHOT-jar-with-dependencies.jar"
JAVA_ARGS="$JAVA_ARGS io.glutenproject.integration.tpc.Tpc $TPC_CMD_ARGS"

BASH_ARGS=
if [ "$RUN_GDB" == "ON" ]
then
  BASH_ARGS="gdb --args java $JAVA_ARGS"
elif [ "$RUN_GDB_SERVER" == "ON" ]
then
  BASH_ARGS="$BASH_ARGS gdbserver :$GDB_SERVER_PORT java $JAVA_ARGS"
else
  BASH_ARGS="java $JAVA_ARGS"
fi

docker build $DOCKER_BUILD_ARGS
docker run $DOCKER_RUN_ARGS $DOCKER_SELECTED_TARGET_IMAGE_TPC bash -c "$BASH_ARGS"

# EOF