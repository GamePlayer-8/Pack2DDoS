#!/bin/sh

SCRIPT_PATH=$(dirname $(realpath $0))

BACK_PATH="$(pwd)"

cd $SCRIPT_PATH

git clone --recursive https://github.com/MatrixTM/MHDDoS DDoS

cp DDoS/requirements.txt .

cd "$BACK_PATH"
