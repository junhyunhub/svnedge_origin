#!/usr/bin/env bash
set -e

attempt_counter=0
max_attempts=30

until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:3343/csvn); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi

    echo "Waiting for SVN Edge console"
    attempt_counter=$(($attempt_counter+1))
    sleep 2
done
