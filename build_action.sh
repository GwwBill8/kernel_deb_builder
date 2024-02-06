#!/usr/bin/env bash

VERSION=$(grep 'Kernel Configuration' < config | awk '{print $3}')

# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
sudo dpkg -i *.deb
sudo apt install -f
sudo cp deepin-app-store-home.gpg /usr/share/keyrings/
sudo cp deepin-archive-camel-keyring.gpg /usr/share/keyrings/
sudo cp deepin-archive-uranus-keyring.gpg /usr/share/keyrings/
sudo sh -c "cat > /etc/apt/sources.list.d/deepin.list" << EOL
## Generated by deepin-installer
deb [trusted=true] https://community-packages.deepin.com/beige/ beige main commercial community
deb-src [trusted=true] https://community-packages.deepin.com/beige/ beige main commercial community
EOL

sudo apt update
sudo apt install -y wget xz-utils make gcc-13 flex bison dpkg-dev bc rsync kmod cpio libssl-dev git lsb vim libelf-dev
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100
gcc -v
sudo apt build-dep -y linux

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source
wget https://gitlab.com/xanmod/linux/-/archive/6.7.3-xanmod1/linux-6.7.3-xanmod1.tar.gz
tar -xf linux-6.7.3-xanmod1.tar.gz
cd linux-6.7.3-xanmod1|| exit

# copy config file
cp ../configfd .config

# disable DEBUG_INFO to speedup build
# scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
# scripts/config --set-str SYSTEM_REVOCATION_KEYS ""
# scripts/config --undefine DEBUG_INFO
# scripts/config --undefine DEBUG_INFO_COMPRESSED
# scripts/config --undefine DEBUG_INFO_REDUCED
# scripts/config --undefine DEBUG_INFO_SPLIT
# scripts/config --undefine GDB_SCRIPTS
# scripts/config --set-val  DEBUG_INFO_DWARF5     n
# scripts/config --set-val  DEBUG_INFO_NONE       y

# apply patches
# shellcheck source=src/util.sh
# source ../patch.d/*.sh

# build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
sudo make bindeb-pkg -j"$CPU_CORES"

# move deb packages to artifact dir
cd ..
rm -rfv *dbg*.deb
mkdir "artifact"
mv ./*.deb artifact/
