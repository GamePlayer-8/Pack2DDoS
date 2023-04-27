#!/bin/sh

SCRIPT_PATH=$(dirname $(realpath $0))

BACK_PATH="$(pwd)"

cd $SCRIPT_PATH

git clone --recursive https://github.com/MatrixTM/MHDDoS DDoS

sed -i 's/git+https://github.com/MHProDev/PyRoxy.git/PyRoxy/g' DDoS/requirements.txt

cp DDoS/requirements.txt .
cp standalone.py DDoS/

cd "$BACK_PATH"
