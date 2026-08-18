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
	curl -o intel-oneapi-mkl-2025.0.1-3-x86_64.pkg.tar.zst -L archive.archlinux.org/packages/i/intel-oneapi-mkl/intel-oneapi-mkl-2025.0.1-3-x86_64.pkg.tar.zst
	pac --needed --noconfirm -U intel-oneapi-mkl-2025.0.1-3-x86_64.pkg.tar.zst
	curl -o hdf5-1.12.1-1-x86_64.pkg.tar.zst -L archive.archlinux.org/packages/h/hdf5/hdf5-1.12.1-1-x86_64.pkg.tar.zst
	pac --needed --noconfirm -U hdf5-1.12.1-1-x86_64.pkg.tar.zst
	
	echo '== Build new DwarFS runimage with zstd 22 lvl and 24 block size'
	rim-build -s runimage-test
}
export -f run_install
# enable OverlayFS mode, disable Nvidia driver check and run install steps
RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 ./runimage bash -c run_install
