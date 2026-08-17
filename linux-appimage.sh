#!/usr/bin/env bash
set -e

export ARCH="$(uname -m)"
export UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*-$ARCH.AppImage.zsync"

URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"

# An example of steam packaging in a RunImage container

if [ ! -x 'runimage' ]; then
	echo '== download base RunImage'
	curl -o runimage -L "https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$(uname -m)"
	chmod +x runimage
fi

run_install() {
	set -e

	INSTALL_PKGS=(
		intel-oneapi-toolkit hdf5 python-h5py
	)

	echo '== checking for updates'
	rim-update

	echo '== install packages'
	pac --needed --noconfirm -S "${INSTALL_PKGS[@]}"

	echo '== Build new DwarFS runimage with zstd 22 lvl and 24 block size'
	rim-build -s steam.RunImage
}
export -f run_install

##########################

# enable OverlayFS mode, disable Nvidia driver check and run install steps
RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 ./runimage bash -c run_install
./steam.RunImage --runtime-extract
rm -f ./steam.RunImage

mv ./RunDir ./AppDir
mv ./AppDir/Run ./AppDir/AppRun

# MAKE APPIMAGE WITH URUNTIME
echo "Generating AppImage..."
export VERSION="$(cat ~/version)"
export OUTNAME=Steam-"$VERSION"-anylinux-"$ARCH".AppImage
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage

# needs to be added here because it wont work in the config file
export ADD_PERMA_ENV_VARS='RIM_ALLOW_ROOT=1'
./uruntime2appimage

# make squashfs appbundle
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH*.AppBundle.zsync"
wget -qO ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"
chmod +x ./pelf
echo "Generating [sqfs]AppBundle...(Go runtime)"
./pelf --add-appdir ./AppDir \
	--compression "-comp zstd -Xcompression-level 22 -b 1M" \
	--appbundle-id="com.valvesoftware.Steam-$(date +%d_%m_%Y)-ivanHC" \
	--appimage-compat --disable-use-random-workdir \
	--add-updinfo "$UPINFO" \
	--output-to "Steam-${VERSION}-anylinux-${ARCH}.sqfs.AppBundle"
zsyncmake ./*.AppBundle -u ./*.AppBundle

echo "All Done!"
