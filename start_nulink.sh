#!/bin/bash
cd "$(dirname "$0")"
_PWD=$(pwd)\
NULINK_KEYSTORE_PASSWORD=$(<.nulink_keypass)
NULINK_OPERATOR_ETH_PASSWORD=$(<.nulink_operator)
docker run --restart on-failure -d \
    --name nulink-node \
    -p 9151:9151 \
    -v $_PWD:/code \
    -v $_PWD/data:/home/circleci/.local/share/nulink \
    -e $NULINK_KEYSTORE_PASSWORD \
    -e $NULINK_OPERATOR_ETH_PASSWORD \
    nulink/nulink nulink ursula run --no-block-until-ready