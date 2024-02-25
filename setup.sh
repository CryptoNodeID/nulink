#!/bin/bash
cd "$(dirname "$0")"
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.23-d901d853.tar.gz
tar -xvzf geth-linux-amd64-1.10.23-d901d853.tar.gz --strip-components=1
rm -f geth-linux-amd64-1.10.23-d901d853.tar.gz
[ -f "COPYING" ] && rm "COPYING"
./geth account new --keystore ./keystore

if [ ! -d "data" ]; then
  mkdir "data"
fi
chmod -R 777 data
chmod -R 777 keystore
if ! command -v docker &> /dev/null; then
    echo "Docker could not be found. Please install Docker before proceeding."
    exit 1
fi

docker pull nulink/nulink:latest
read -sp "Enter your node password (minimum 8 characters): " PASSWORD
echo
if [ ${#PASSWORD} -lt 8 ]; then
    echo "Error: Password must be at least 8 characters."
    exit 1
fi
echo $PASSWORD > .nulink_operator
read -sp "Enter your keystore password: " KEYSTORE_PASSWORD
echo
# Check if the entered password can open the keystore
if echo "$KEYSTORE_PASSWORD" | ./geth account list --keystore ./keystore 2>/dev/null; then
    # If the password is correct, store it in a file
    echo $KEYSTORE_PASSWORD > .nulink_keypass
else
    echo "Error: Incorrect keystore password."
    exit 1
fi

KEYSTORE_FILE=$(ls keystore | grep UTC--)
WORKER_ACCOUNT=$(echo "$KEYSTORE_PASSWORD" | ./geth account list --keystore ./keystore | awk -F'[{}]' '{print $2}' | head -n 1)
_PWD=$(pwd)

docker run -it --rm \
    -p 9151:9151 \
    -v $_PWD:/code \
    -v $_PWD/data:/home/circleci/.local/share/nulink \
    -e $KEYSTORE_PASSWORD \
    nulink/nulink nulink ursula init \
    --signer keystore:///code/keystore/$KEYSTORE_FILE \
    --eth-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
    --network horus \
    --payment-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
    --payment-network bsc_testnet \
    --operator-address 0x$WORKER_ACCOUNT \
    --max-gas-price 10000000000