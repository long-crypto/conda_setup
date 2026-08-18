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
		curl python-h5py gcc
	)

	echo '== checking for updates'
	rim-update

	echo '== install packages'
	pac --needed --noconfirm -S "${INSTALL_PKGS[@]}"
	curl -o intel-oneapi-base-toolkit-2025.3.1.36_offline.sh -L https://registrationcenter-download.intel.com/akdlm/IRC_NAS/6caa93ca-e10a-4cc5-b210-68f385feea9e/intel-oneapi-base-toolkit-2025.3.1.36_offline.sh
	chmod +x intel-oneapi-base-toolkit-2025.3.1.36_offline.sh && sudo sh ./intel-oneapi-base-toolkit-2025.3.1.36_offline.sh -a --silent --cli --eula accept
	curl -o hdf5-1.12.1-1-x86_64.pkg.tar.zst -L archive.archlinux.org/packages/h/hdf5/hdf5-1.12.1-1-x86_64.pkg.tar.zst
	pac --needed --noconfirm -U hdf5-1.12.1-1-x86_64.pkg.tar.zst
	
	echo '== Build new DwarFS runimage with zstd 22 lvl and 24 block size'
	rim-build -s runimage-test
}
export -f run_install
# enable OverlayFS mode, disable Nvidia driver check and run install steps
RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 ./runimage bash -c run_install
