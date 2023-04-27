#!/bin/sh

export TZ="Europe/Warsaw"
export DEBIAN_FRONTEND=noninteractive

apt update > /dev/null
apt install --yes markdown > /dev/null
cd /source

echo '<!DOCTYPE html>' > index.html
echo '<html lang="en-US">' >> index.html
cat docs/head.html >> index.html

echo '<body>' >> index.html
markdown README.md >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html

apt install --yes git wine apt-utils tar wget xvfb winetricks > /dev/null
dpkg --add-architecture i386 && apt-get update > /dev/null && apt-get install --yes wine32 > /dev/null

sh patch.sh

sed -i 's/gunicorn/waitress/g' requirements.txt # Remove gunicorn due to missing fnctl for Windows

py_deps_DDoS=""
for X in $(cat requirements.txt); do
    py_deps_DDoS=$py_deps_DDoS' --collect-all '$X
done

py_deps_DDoS=$py_deps_DDoS' --collect-all tzdata'

for X in $(find DDoS/ -name '__pycache__'); do
    rm -rf "$X"
done

py_data_DDoS=""
for X in ./DDoS/*; do
    if [ -f "$X" ]; then
        BASENAME=$(basename "$X")
        py_data_DDoS=$py_data_DDoS" --add-data $BASENAME;."
    fi
done

py_dirs_DDoS=""
for X in ./DDoS/*; do
    if [ -d "$X" ]; then
        BASENAME=$(basename "$X")
        py_dirs_DDoS=$py_dirs_DDoS" --add-data $BASENAME/*;$BASENAME/"
    fi
done

export WINEPREFIX=/wine
export DISPLAY=":0"
export WINEDEBUG="-all"
export PYTHON_VERSION=3.11.3
export UPX_VERSION=3.96
export WINEDLLOVERRIDES="winemenubuilder.exe,mscoree,mshtml="

Xvfb -ac :0 -screen 0 1280x1024x24 &
sleep 5

xvfb-run sh -c "wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion' /v CurrentVersion /d 10.0 /f && \
wine reg add 'HKCU\Software\Wine\DllOverrides' /v winemenubuilder.exe /t REG_SZ /d '' /f && \
wine reg add 'HKCU\Software\Wine\DllOverrides' /v mscoree /t REG_SZ /d '' /f && \
wine reg add 'HKCU\Software\Wine\DllOverrides' /v mshtml /t REG_SZ /d '' /f; \
wineserver -w"

wget -q https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.exe -O /python-${PYTHON_VERSION}-amd64.exe
wget -q https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-win64.zip -O /upx-${UPX_VERSION}-win64.zip

cd /

xvfb-run sh -c "\
    wine /python-${PYTHON_VERSION}-amd64.exe /quiet TargetDir=C:\\Python310 \
      Include_doc=0 InstallAllUsers=1 PrependPath=1; \
    wineserver -w" && \
  unzip -o upx*.zip && \
  mv -v upx*/upx.exe ${WINEPREFIX}/drive_c/windows/

export WINEPATH='C:\Python310\Scripts'

wine python -m pip install --upgrade setuptools wheel pip
wine python -m pip install pyinstaller

cd /source

wine python -m pip install -r requirements.txt

wine python setup.py build
wine python setup.py install
rm -rf DDoS.egg-info

cd DDoS

wine pyinstaller $py_deps_DDoS $py_dirs_DDoS $py_data_DDoS \
  -F --onefile --console \
  --additional-hooks-dir=. \
  -i '../docs/icon.ico' -n DDoS -c standalone.py

mv dist/DDoS.exe ..
rm -rf dist build log

cd ..

sed -i 's/waitress/gunicorn/g' requirements.txt

chmod +x DDoS.exe

sha256sum DDoS.exe > sha256sum.txt

mkdir -pv /runner/page/
cp -rv /source/* /runner/page/
