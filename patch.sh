#!/bin/sh

SCRIPT_PATH=$(dirname $(realpath $0))

BACK_PATH="$(pwd)"

cd $SCRIPT_PATH

git clone --recursive https://github.com/cyweb/hammer DDoS

cp standalone.py DDoS/

cd "$BACK_PATH"
