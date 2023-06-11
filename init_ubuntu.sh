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

apt install --yes git python3-pip linux-headers-$(uname -r) build-essential python3-dev xvfb appstream tar lsb-release apt-utils file upx > /dev/null

pip install --upgrade wheel setuptools > /dev/null
pip install -r requirements.txt > /dev/null
pip install pyinstaller > /dev/null

Xvfb -ac :0 -screen 0 1280x1024x24 &
sleep 5

sh patch.sh

py_deps_DDoS=""
for X in $(cat requirements.txt); do
    py_deps_DDoS=$py_deps_DDoS' --collect-all '$X
done

py_deps_DDoS=$py_deps_DDoS' --collect-all tzdata'

for X in $(find . -name '__pycache__'); do
    rm -rf "$X"
done

py_data_DDoS=""
for X in ./DDoS/*; do
    if [ -f "$X" ]; then
        BASENAME=$(basename "$X")
        py_data_DDoS=$py_data_DDoS" --add-data $BASENAME:."
    fi
done

py_dirs_DDoS=""
for X in ./DDoS/*; do
    if [ -d "$X" ]; then
        BASENAME=$(basename "$X")
        py_dirs_DDoS=$py_dirs_DDoS" --add-data $BASENAME/*:$BASENAME/"
    fi
done

python3 setup.py build
python3 setup.py install

cd DDoS

DISPLAY=":0" pyinstaller -F --onefile --console \
 --additional-hooks-dir=. $py_dirs_DDoS $py_data_DDoS \
  $py_deps_DDoS -i ../docs/icon.png -n DDoS -c standalone.py

mv dist/DDoS ../DDoS-glibc
rm -rf dist build log

cd ..

strip DDoS-glibc

chmod +x DDoS-glibc

mkdir -p DDoS.AppDir/var/lib/dpkg
mkdir -p DDoS.AppDir/var/cache/apt/archives
apt install --yes debootstrap fakeroot fakechroot
fakechroot fakeroot debootstrap --variant=fakechroot --arch amd64 22.04 /source/DDoS.AppDir/ http://archive.ubuntu.com/ubuntu > /dev/null

cd DDoS.AppDir/
rm -rf etc var home mnt srv proc sys boot opt
cd ..

cp docs/icon.png DDoS.AppDir/icon.png

echo '[Desktop Entry]' > DDoS.AppDir/DDoS.desktop
echo 'Name=DDoS' >> DDoS.AppDir/DDoS.desktop
echo 'Categories=Settings' >> DDoS.AppDir/DDoS.desktop
echo 'Type=Application' >> DDoS.AppDir/DDoS.desktop
echo 'Icon=icon' >> DDoS.AppDir/DDoS.desktop
echo 'Terminal=true' >> DDoS.AppDir/DDoS.desktop
echo 'Exec=/usr/bin/DDoS' >> DDoS.AppDir/DDoS.desktop

chmod +x DDoS.AppDir/DDoS.desktop

echo '#!/bin/sh' > DDoS.AppDir/AppRun
echo 'DDoS_RUNPATH="$(dirname "$(readlink -f "${0}")")"' >> DDoS.AppDir/AppRun
echo 'DDoS_EXEC="${DDoS_RUNPATH}"/usr/bin/DDoS' >> DDoS.AppDir/AppRun
echo 'export LD_LIBRARY_PATH="${DDoS_RUNPATH}"/lib:"${DDoS_RUNPATH}"/lib64:$LD_LIBRARY_PATH' >> DDoS.AppDir/AppRun
echo 'export LIBRARY_PATH="${DDoS_RUNPATH}"/lib:"${DDoS_RUNPATH}"/lib64:"${DDoS_RUNPATH}"/usr/lib:"${DDoS_RUNPATH}"/usr/lib64:$LIBRARY_PATH' >> DDoS.AppDir/AppRun
echo 'export PATH="${DDoS_RUNPATH}/usr/bin/:${DDoS_RUNPATH}/usr/sbin/:${DDoS_RUNPATH}/usr/games/:${DDoS_RUNPATH}/bin/:${DDoS_RUNPATH}/sbin/${PATH:+:$PATH}"' >> DDoS.AppDir/AppRun
echo 'exec "${DDoS_EXEC}" "$@"' >> DDoS.AppDir/AppRun

chmod +x DDoS.AppDir/AppRun

mkdir -p DDoS.AppDir/usr/bin
cp DDoS-glibc DDoS.AppDir/usr/bin/DDoS
chmod +x DDoS.AppDir/usr/bin/DDoS

wget -q https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O toolkit.AppImage
chmod +x toolkit.AppImage

cd /opt/
/source/toolkit.AppImage --appimage-extract
mv /opt/squashfs-root /opt/appimagetool.AppDir
ln -s /opt/appimagetool.AppDir/AppRun /usr/local/bin/appimagetool
chmod +x /opt/appimagetool.AppDir/AppRun
cd /source

ARCH=x86_64 appimagetool DDoS.AppDir/

mv DDoS-x86_64.AppImage DDoS-glibc-x86_64.AppImage

rm -rf DDoS.AppDir
rm -f toolkit.AppImage
rm -rf DDoS.egg-info
chmod +x DDoS-glibc-x86_64.AppImage

sha256sum DDoS-glibc > sha256sum.txt
sha256sum DDoS-glibc-x86_64.AppImage >> sha256sum.txt

mkdir -pv /runner/page/
cp -rv /source/* /runner/page/
