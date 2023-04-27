#!/bin/sh

SCRIPT_PATH=$(dirname $(realpath $0))

BACK_PATH="$(pwd)"

cd $SCRIPT_PATH

git clone --recursive https://github.com/cyweb/hammer DDoS

sed -i 's/time.sleep(.1)/###/g' DDoS/hammer.py
sed -i 's/except:/except: pass/g' DDoS/hammer.py

cp standalone.py DDoS/

cd "$BACK_PATH"
