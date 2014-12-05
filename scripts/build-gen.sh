#!/bin/sh

# generate build-toolchain.sh from chapter5 

set -o nounset
set -o errexit
#set -x

toolchain_dir=chapter05
LFS=/mnt/lfs

function prebuild_sanity_check() {
    if [[ $(whoami) != "lfs" ]] ; then
        echo "Not running as user lfs, you should be!"
        exit 1
    fi

    if ! [[ -v LFS ]] ; then
        echo "You forgot to set your LFS environment variable!"
        exit 1
    fi

    if ! [[ -v LFS_TGT ]] ; then
        echo "Your LFS_TGT variable should be set "
        exit 1
    fi

    if ! [[ -d $LFS ]] ; then
        echo "Your LFS directory doesn't exist!"
        exit 1
    fi

    if ! [[ -d $LFS/sources ]] ; then
        echo "Can't find your sources directory!"
        exit 1
    fi

    if [[ $(stat -c %U $LFS/sources) != "lfs" ]] ; then
        echo "The sources directory should be owned by user lfs!"
        exit 1
    fi

    if ! [[ -d $LFS/tools ]] ; then
        echo "Can't find your tools directory!"
        exit 1
    fi

    if [[ $(stat -c %U $LFS/tools) != "lfs" ]] ; then
        echo "The tools directory should be owned by user lfs!"
        exit 1
    fi
}

echo "#!/bin/sh" 
echo "source scripts/utils.sh" 

cd $toolchain_dir 
for i in $(find . -name "0*-*" |sort -n);
do
  echo "# $i" 
  pkgname=$(echo $i| awk -F- '{ print $2; }') 
  echo "extract_package $pkgname" 
  cat "$i" 
done

echo 'echo "* Toolchain finiched !"'

