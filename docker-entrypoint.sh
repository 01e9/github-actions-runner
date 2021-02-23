#!/usr/bin/env bash

# fix `docker` group id (to match id on host)
if [[ -S /var/run/docker.sock ]]; then
  LOCAL_ID=$(getent group docker | cut -d: -f3)
  HOST_ID=$(stat -c "%g" /var/run/docker.sock)
  groupmod -g "${HOST_ID}" docker
  echo "Fixed docker group id ${LOCAL_ID} -> ${HOST_ID}"
fi

COMMAND='./config.sh ${RUNNER_CONFIG_ARGS}; ./run.sh; sleep infinity'
COMMAND="cd $(pwd); ${COMMAND}"

echo "Executing as github '${COMMAND}'"

sudo -n -E -H -u github bash -c "${COMMAND}"
